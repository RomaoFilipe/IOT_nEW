# app/services/analytics/sensor_agg.rb
module Analytics
  class SensorAgg
    ALIASES = {
      soil_moisture:  %w[soil_moisture moisture],
      temperature:    %w[temperature air_temperature water_temperature],
      humidity:       %w[air_humidity humidity],
      ph:             %w[ph soil_ph],
      salinity:       %w[salinity soil_ec],
      do_mg_l:        %w[do_mg_l dissolved_oxygen],
      turbidity:      %w[turbidity],
      light:          %w[light light_intensity]
    }.freeze

    def initialize(company:, range:)
      @company = company
      @range   = range
    end

    def avg_by_day(metric_key)
      keys = ALIASES[metric_key.to_sym] || [metric_key.to_s]
      ids  = company_sensor_ids
      return {} if ids.empty? || !model_exists?

      scope = SensorReading.where(sensor_id: ids, measured_at: @range)

      keys.each do |k|
        if column_exists?(k)
          return group_avg_column(scope, k)
        elsif json_exists?
          if scope.where("sensor_readings.data ? :key", key: k).limit(1).exists?
            return group_avg_json(scope, k)
          end
        end
      end
      {}
    end

    def avg_last_24h(metric_key)
      keys = ALIASES[metric_key.to_sym] || [metric_key.to_s]
      ids  = company_sensor_ids
      return nil if ids.empty? || !model_exists?

      scope = SensorReading.where(sensor_id: ids, measured_at: 24.hours.ago..Time.current)

      keys.each do |k|
        if column_exists?(k)
          v = scope.average(k)
          return v.to_f if v
        elsif json_exists?
          v = scope.where("sensor_readings.data ? :key", key: k)
                   .pluck(Arel.sql("AVG((sensor_readings.data->>'#{k}')::numeric)")).first
          return v.to_f if v
        end
      end
      nil
    end

    private

    def model_exists?
      defined?(SensorReading) && SensorReading.table_exists?
    end

    def company_sensor_ids
      if @company.respond_to?(:sensors)
        @company.sensors.pluck(:id)
      elsif @company.respond_to?(:fields)
        Sensor.where(field_id: @company.fields.select(:id)).pluck(:id)
      else
        []
      end
    rescue
      []
    end

    def column_exists?(name) = SensorReading.column_names.include?(name.to_s)
    def json_exists?         = SensorReading.column_names.include?("data")

    def group_avg_column(scope, col)
      if defined?(Groupdate)
        scope.group_by_day(:measured_at, time_zone: Time.zone.name).average(col)
      else
        scope.select("DATE(measured_at) AS d, AVG(#{col}) AS v")
             .group("d").order("d").map { |r| [r.d, r.v.to_f] }.to_h
      end
    end

    def group_avg_json(scope, key)
      expr = "AVG((sensor_readings.data->>'#{key}')::numeric)"
      scope.select("DATE(measured_at) AS d, #{expr} AS v")
           .group("d").order("d").map { |r| [r.d, r.v.to_f] }.to_h
    end
  end
end
