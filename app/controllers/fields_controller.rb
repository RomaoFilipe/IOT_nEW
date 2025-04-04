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
    @field = current_user.fields.build(field_params)
    
    if @field.save
      redirect_to fields_path, notice: "Field created successfully."
    else
      render :new, status: :unprocessable_entity
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
