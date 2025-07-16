class FieldsController < ApplicationController
  before_action :authenticate_user!

def index
  @fields = current_user.fields.select(
    :id, :name, :latitude, :longitude, :area, :field_type, :updated_at, :polygon_coordinates, :notes,
    :species, :tank_volume, :stocking_density, :feeding_regime, :fish_placement_date, :estimated_harvest_date
  )
  @field = Field.new
end



  def new
    @field = Field.new
  end

  def create
    @field = current_user.fields.build(field_params)
    @field.account = current_user.account
    @field.field_type = current_user.account.farm_type

    if @field.save
      respond_to do |format|
        format.html { redirect_to fields_path, notice: "Campo criado com sucesso." }
        format.turbo_stream do
          flash.now[:notice] = "Campo criado com sucesso."
          render turbo_stream: turbo_stream.prepend("fields_list", partial: "fields/card", locals: { field: @field })
        end
      end
    else
      # 🔁 Recarregar os campos se falhar para evitar erro de nil.each
      @fields = current_user.fields.select(
        :id, :name, :latitude, :longitude, :area, :field_type, :updated_at, :polygon_coordinates
      )

      respond_to do |format|
        format.html do
          flash.now[:alert] = "Erro ao criar campo."
          render :index, status: :unprocessable_entity
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "field_form_errors",
            partial: "fields/form_errors",
            locals: { field: @field }
          )
        end
      end
    end
  end

def edit
  @field = current_user.fields.find(params[:id])
end

def update
  @field = current_user.fields.find(params[:id])
  if @field.update(field_params)
    redirect_to fields_path, notice: "Campo atualizado com sucesso."
  else
    render :edit, status: :unprocessable_entity
  end
end


  def destroy
    @field = current_user.fields.find(params[:id])
    @field.destroy
    redirect_to fields_path, notice: "Campo eliminado com sucesso."
  end

  def show_details
    @field = current_user.fields.find(params[:id])
    render partial: "fields/view_details", locals: { field: @field }
  end

  private

def field_params
  permitted = params.require(:field).permit(
    :name, :area, :latitude, :longitude, :notes, :polygon_coordinates,
    :species, :tank_volume, :stocking_density, :feeding_regime, :fish_placement_date, :estimated_harvest_date
  )

  if permitted[:polygon_coordinates].present? && permitted[:polygon_coordinates].is_a?(String)
    permitted[:polygon_coordinates] = JSON.parse(permitted[:polygon_coordinates]) rescue nil
  end

  permitted
end

end
