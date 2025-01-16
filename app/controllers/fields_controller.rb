class FieldsController < ApplicationController
  before_action :authenticate_user!

  def new
    @field = Field.new
  end

  def index
    @fields = current_user.fields
    @weather_forecast = [
      { day: "segunda", temperature: "23.2", rain: "5.6", wind_speed: "19.4" },
      { day: "terça", temperature: "29.9", rain: "0.4", wind_speed: "9.5" },
      { day: "quarta", temperature: "25.8", rain: "6.2", wind_speed: "7.4" },
      { day: "quinta", temperature: "21.1", rain: "6.3", wind_speed: "9.3" },
      { day: "sexta", temperature: "28.4", rain: "0.0", wind_speed: "7.1" }
    ]
  
    @soil_analysis = {
      ph_level: 6.5,
      nitrogen: "Moderado",
      phosphorus: "Moderado",
      potassium: "Moderado"
    }
  
    @irrigation_schedule = ["00:00", "06:00", "12:00", "18:00"] unless @irrigation_schedule
  
    @resource_consumption = {
      water: "120L/day",
      fertilizer: "2.5kg/week",
      energy: "5kWh/day"
    }
  
    @activity_history = [
      "Ciclo de irrigação automático completado",
      "Umidade do solo baixa detectada",
      "Fertilizante aplicado"
    ]
  
    respond_to do |format|
      format.html
      format.json { render json: @fields.as_json(only: [:id, :name, :field_type, :model_path, :position_x, :position_y, :position_z]) }
    end
  end
  

  def show
    # Tenta encontrar o terreno pelo ID
    @field = current_user.fields.find_by(id: params[:id])

    # Dados de exemplo para demonstração
    if @field.nil?
      @field = Field.new(
        id: 999,
        name: "Terreno de Exemplo",
        field_type: "Trigo",
        model_path: "trigo2/scene.gltf",
        position_x: 0,
        position_y: 0,
        position_z: 0
      )
    end

    # Dados simulados
    @weather_forecast = {
      "quinta" => 25,
      "sexta" => 27,
      "sábado" => 26,
      "domingo" => 28,
      "segunda" => 24
    }

    @soil_analysis = {
      ph_level: 6.5,
      nitrogen: "Moderado",
      phosphorus: "Moderado",
      potassium: "Moderado"
    }

    @irrigation_schedule = ["00:00", "06:00", "12:00", "18:00"]

    @resource_consumption = {
      water: "120L/day",
      fertilizer: "2.5kg/week",
      energy: "5kWh/day"
    }

    @activity_history = [
      "Ciclo de irrigação automático completado",
      "Umidade do solo baixa detectada",
      "Fertilizante aplicado"
    ]

    respond_to do |format|
      format.html
      format.json do
        render json: {
          field: @field,
          weather_forecast: @weather_forecast,
          soil_analysis: @soil_analysis,
          irrigation_schedule: @irrigation_schedule,
          resource_consumption: @resource_consumption,
          activity_history: @activity_history
        }
      end
    end
  end

  def create
    @field = current_user.fields.new(field_params)

    if @field.save
      respond_to do |format|
        format.html { redirect_to fields_path, notice: 'Terreno criado com sucesso!' }
        format.json { render json: @field, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to fields_path, alert: @field.errors.full_messages.to_sentence }
        format.json { render json: { errors: @field.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @field = current_user.fields.find(params[:id])
    if @field.destroy
      head :no_content
    else
      render json: { error: 'Não foi possível excluir o terreno.' }, status: :unprocessable_entity
    end
  end

  private

  def field_params
    params.require(:field).permit(:name, :field_type, :model_path, :position_x, :position_y, :position_z)
  end
end
