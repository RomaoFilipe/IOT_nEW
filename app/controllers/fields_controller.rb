class FieldsController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = Field.all
    @field = Field.new # ESSENCIAL para form_with model: @field
    @fields = current_user.fields.select(
      :id, :name, :latitude, :longitude, :area, :field_type, :updated_at, :polygon_coordinates
    )
  end

  def show
    @field = Field.find(params[:id])
    render partial: 'fields/view_details_content', locals: { field: @field }
  end
  

  def new
    @field = Field.new
  end

  def create
    @field = current_user.fields.build(field_params)
    
    if @field.save
      redirect_to fields_path, notice: "Field created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @field = Field.find(params[:id])
  
    if @field.destroy
      respond_to do |format|
        format.html { redirect_to fields_path, notice: "Campo eliminado com sucesso." }
        format.json { render json: { status: 'ok', message: "Campo eliminado com sucesso." } }
      end
    else
      respond_to do |format|
        format.html { redirect_to fields_path, alert: @field.errors.full_messages.to_sentence }
        format.json { render json: { status: 'error', message: @field.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
    end
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
