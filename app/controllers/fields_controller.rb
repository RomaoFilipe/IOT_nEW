class FieldsController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = Field.all
    @field = Field.new # ESSENCIAL para form_with model: @field
    @fields = current_user.fields.select(
      :id, :name, :latitude, :longitude, :area, :field_type, :updated_at, :polygon_coordinates
    )
  end

  def new
    @field = Field.new
  end

def create
  @field = current_user.fields.new(field_params)
  if @field.save
    redirect_to fields_path, notice: "Campo criado com sucesso."
  else
    # Se estiveres a usar um modal, renderiza um partial com Turbo Stream
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("field_form", partial: "fields/form", locals: { field: @field })
      end
      format.html { redirect_to fields_path, alert: "Erro ao criar campo." }
    end
  end
end

  def destroy
    @field = Field.find(params[:id])
    @field.destroy
    redirect_to fields_path, notice: "Campo eliminado com sucesso."
  end

  def show_details
    @field = Field.find(params[:id])
    render partial: "fields/view_details", locals: { field: @field }
  end

  private

  def field_params
    permitted = params.require(:field).permit(:name, :field_type, :area, :latitude, :longitude, :notes, :polygon_coordinates)
    if permitted[:polygon_coordinates].present? && permitted[:polygon_coordinates].is_a?(String)
      permitted[:polygon_coordinates] = JSON.parse(permitted[:polygon_coordinates])
    end
    permitted
  end
  
end
