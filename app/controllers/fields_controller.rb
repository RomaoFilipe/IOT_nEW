class FieldsController < ApplicationController
  before_action :authenticate_user!

  def new
    @field = Field.new
  end

  def index
    # Recupera os terrenos do usuário atual
    @fields = current_user.fields

    # Dados de exemplo para demonstração (caso o usuário não tenha terrenos)
    if @fields.empty?
      @fields = [
        Field.new(id: 1, name: "Terreno Exemplo 1", field_type: "Milho", model_path: "trigo2/scene.gltf", position_x: 10, position_y: 0, position_z: -20),
        Field.new(id: 2, name: "Terreno Exemplo 2", field_type: "Trigo", model_path: "PlaneQuadrado/scene.gltf", position_x: 30, position_y: 0, position_z: 40)
      ]
    end

    # Dados simulados para exibição nos modais
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
