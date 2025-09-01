# app/services/sensor_reading/ingest.rb
# ATENÇÃO: o caminho exige a constante SensorReading::Ingest.
# Como SensorReading já é UMA CLASSE (o model), abrimos a classe:
class SensorReading
  class Ingest
    def self.call(sensor_or_id, attrs = {})
      sensor = sensor_or_id.is_a?(::Sensor) ? sensor_or_id : ::Sensor.find(sensor_or_id)
      h = attrs.to_h.symbolize_keys

      # timestamp unificado
      ts = h[:measured_at].presence || h[:read_at].presence || Time.zone.now

      reading_attrs = {
        sensor_id:        sensor.id,
        measured_at:      ts,
        read_at:          (h[:read_at].presence || ts),

        temperature:      f(h[:temperature]),
        moisture:         f(h[:moisture]),
        battery:          i(h[:battery]),
        signal:           i(h[:signal]),
        light_intensity:  i(h[:light_intensity]),
        wind_speed:       f(h[:wind_speed]),
        wind_direction:   i(h[:wind_direction]),
        air_temperature:  f(h[:air_temperature]),
        air_humidity:     i(h[:air_humidity]),
        soil_ph:          f(h[:soil_ph]),
        soil_ec:          f(h[:soil_ec]),
        soil_nitrogen:    i(h[:soil_nitrogen]),
        soil_potassium:   i(h[:soil_potassium]),
        soil_phosphorus:  i(h[:soil_phosphorus]),
        uptime:           i(h[:uptime]),
        error_count:      i(h[:error_count]),

        soil_pct:         d(h[:soil_pct]),
        temp_c:           d(h[:temp_c]),
        hum_air:          d(h[:hum_air]),
        lux:              d(h[:lux]),

        raw:              (h[:raw].is_a?(Hash) ? h[:raw] : {})
      }

      ::SensorReading.create!(reading_attrs)
    end

    # helpers de casting
    def self.f(v); v.nil? ? nil : v.to_f; end
    def self.i(v); v.nil? ? nil : v.to_i; end
    def self.d(v); v.nil? ? nil : BigDecimal(v.to_s); end
    private_class_method :f, :i, :d
  end
end
