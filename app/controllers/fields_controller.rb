class FieldsController < ApplicationController
  before_action :authenticate_user!

  

  def index
    @fields = current_user.fields
    respond_to do |format|
      format.html # renderizar uma view HTML
      format.json { render json: @fields, only: [:id, :name, :position_x, :position_y, :position_z, :model_path] }
    end
  end

    # Exibir detalhes de um terreno específico
    def show
      @field = current_user.fields.find_by(id: params[:id])
    
      if @field
        # Dados simulados de sensores (substituir futuramente por dados reais de IoT)
        @sensor_data = {
          temperature: rand(20..35), # Temperatura entre 20°C e 35°C
          humidity: rand(40..80),    # Umidade entre 40% e 80%
          light: rand(400..800),     # Luz solar entre 400 e 800 lux
          status: "Em Crescimento"
        }
      else
        # Caso o terreno não seja encontrado
        redirect_to fields_path, alert: "Terreno não encontrado ou não pertence a você."
      end
    end

    def create
      @field = current_user.fields.new(field_params)
      
      if @field.save
        render json: { status: 'success', field: @field }
      else
        render json: { status: 'error', errors: @field.errors.full_messages }, status: :unprocessable_entity
      end
    end

  def destroy
    @field = current_user.fields.find(params[:id])
    if @field.destroy
      render json: { status: 'success', message: 'Terreno removido com sucesso.' }
    else
      render json: { status: 'error', message: 'Erro ao remover o terreno.' }
    end
  end

  private

  def field_params
    params.require(:field).permit(:name, :field_type, :position_x, :position_y, :position_z, :model_path)
  end
end
