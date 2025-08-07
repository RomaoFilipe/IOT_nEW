class IrrigationSchedulesController < ApplicationController
  before_action :set_field, except: [:destroy, :by_sensor]

  def create
    days = params[:days] || []
duration = params[:irrigation_schedule][:duration].to_i * 60

    created = 0
    last_created = nil

    days.each do |day|
      schedule = @field.irrigation_schedules.new(
        schedule_params.merge(day_of_week: day.to_i, duration: duration)
      )
      if schedule.save
        created += 1
        last_created = schedule
      end
    end

    respond_to do |format|
      if created > 0
        format.html {
          redirect_back fallback_location: fields_path, notice: "Criado(s) #{created} agendamento(s)."
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "schedules_container_#{last_created.sensor.id}",
            partial: "irrigation_schedules/list",
            locals: {
              sensor: last_created.sensor,
              schedules: last_created.sensor.irrigation_schedules.order(:day_of_week, :hour, :minute)
            }
          )
        }
      else
        format.html {
          redirect_back fallback_location: fields_path, alert: "Erro ao criar agendamento."
        }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def today
    @field = Field.find(params[:field_id])
    now = Time.zone.now

    @schedules = @field.irrigation_schedules
      .where(day_of_week: now.wday)
      .where("hour > ? OR (hour = ? AND minute > ?)", now.hour, now.hour, now.min)
      .order(:hour, :minute)
  end

  def destroy
    @schedule = IrrigationSchedule.find(params[:id])
    if @schedule.destroy
      ActionCable.server.broadcast(
        "planned_events_#{current_user.id}",
        {
          action: 'destroy_irrigation',
          irrigation_id: @schedule.id
        }
      )
      redirect_to dashboard_path, notice: "Irrigação cancelada com sucesso."
    else
      redirect_to dashboard_path, alert: "Erro ao cancelar irrigação."
    end
  end

  def by_sensor
    sensor = Sensor.find(params[:sensor_id])
    schedules = sensor.irrigation_schedules.order(:day_of_week, :hour, :minute)

    render partial: "irrigation_schedules/list", locals: { sensor: sensor, schedules: schedules }
  end

  private

  def set_field
    @field = Field.find(params[:field_id])
  end

  def schedule_params
    params.require(:irrigation_schedule).permit(:hour, :minute, :sensor_id)
  end
end
