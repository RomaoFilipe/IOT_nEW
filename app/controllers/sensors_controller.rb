class SensorsController < ApplicationController
  before_action :set_field, only: [:create]
  before_action :set_sensor, only: [:simulate, :destroy]

  def create
    @sensor = @field.sensors.build(sensor_params)

    if @sensor.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to fields_path, notice: "Sensor criado com sucesso." }
      end
    else
      respond_to do |format|
        format.html { redirect_to fields_path, alert: "Erro ao criar sensor." }
      end
    end
  end

  def simulate
    @sensor.update(
      last_value: "#{rand(10..90)}%",
      battery: rand(30..100),
      signal: rand(20..100),
      last_reading: Time.current
    )

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to fields_path, notice: "Sensor atualizado." }
    end
  end

  def destroy
    @sensor.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to fields_path, notice: "Sensor apagado." }
    end
  end

  private

  def set_field
    @field = Field.find(params[:field_id])
  end

  def set_sensor
    @sensor = Sensor.find(params[:id])
  end

  def sensor_params
    params.require(:sensor).permit(:name, :sensor_type)
  end
end
