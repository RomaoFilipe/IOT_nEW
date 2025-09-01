# app/controllers/sensor_readings_controller.rb
class SensorReadingsController < ApplicationController
  before_action :authenticate_user!

  # Se este controller também serve API (dispositivos sem CSRF), descomenta:
  # protect_from_forgery with: :null_session

  def new
    @reading  = SensorReading.new
    @sensors  = Sensor.select(:id, :name)
  end

def create
  attrs = sr_params.to_h
  attrs["measured_at"] ||= attrs["read_at"] # fallback
  @reading = SensorReading.new(attrs)

  if @reading.save
    redirect_to analytics_path(production_kind: params[:production_kind] || "agriculture"),
                notice: "Leitura registada."
  else
    @sensors = Sensor.select(:id,:name)
    flash.now[:alert] = "Verifica os campos."
    render :new, status: :unprocessable_entity
  end
end


  private

  # Strong params (aceita também JSONB em :data)
def sr_params
  params.require(:sensor_reading).permit(
    :sensor_id,
    :read_at, :measured_at,
    :moisture, :soil_pct,
    :temperature, :air_temperature, :air_humidity,
    :battery, :signal, :light_intensity,
    :wind_speed, :wind_direction,
    :soil_ph, :soil_ec, :soil_nitrogen, :soil_potassium, :soil_phosphorus,
    :uptime, :error_count
  )
end
  # ————————————————————————————————————————————
  # Normalização:
  # - usa measured_at (ou converte de read_at)
  # - faz cast numérico
  # - move chaves desconhecidas para JSONB :data (se existir)
  # ————————————————————————————————————————————
  def normalize_params(p)
    p = p.transform_keys(&:to_s)

    # 1) timestamp → preferir measured_at; senão, converter read_at
    parsed_ts =
      begin
        if p["measured_at"].present?
          Time.zone.parse(p["measured_at"].to_s)
        elsif p["read_at"].present?
          Time.zone.parse(p["read_at"].to_s)
        end
      rescue
        nil
      end
    parsed_ts ||= Time.zone.now

    if SensorReading.column_names.include?("measured_at")
      p["measured_at"] = parsed_ts
    elsif SensorReading.column_names.include?("read_at")
      p["read_at"] = parsed_ts
    else
      # se nenhuma existir, criamos measured_at virtual (não vai gravar, mas evita crash)
      p["measured_at"] = parsed_ts
    end

    # 2) separar colunas conhecidas vs resto (para JSONB :data)
    known_cols = SensorReading.column_names
    data_hash  = (p["data"].is_a?(Hash) ? p.delete("data") : {})

    # lista de possíveis métricas que podes ter como colunas
    candidate_cols = %w[
      moisture temperature battery signal light_intensity
      wind_speed wind_direction air_temperature air_humidity
      soil_ph soil_ec soil_nitrogen soil_potassium soil_phosphorus
    ]

    candidate_cols.each do |k|
      next unless p.key?(k)
      if known_cols.include?(k)
        p[k] = cast_number(p[k])
      else
        data_hash[k] = p.delete(k)
      end
    end

    # garante sensor_id
    p["sensor_id"] = p["sensor_id"]

    # 3) se existir coluna JSONB :data, guardamos o resto lá
    if known_cols.include?("data") && data_hash.present?
      # também convertemos números em strings numéricas
      data_hash = data_hash.to_h { |kk, vv| [kk.to_s, cast_number(vv)] }
      p["data"] = (p["data"].is_a?(Hash) ? p["data"] : {}).merge(data_hash)
    else
      p.delete("data")
    end

    p.symbolize_keys
  end

  def cast_number(v)
    return nil if v.nil? || v == ""
    return v   if v.is_a?(Numeric)
    Float(v) rescue v
  end
end
