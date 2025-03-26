class FieldsController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = current_user.fields
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
    params.require(:field).permit(:name, :field_type, :latitude, :longitude, :area)
  end
end
