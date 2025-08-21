class FieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_field, only: [:edit, :update, :destroy, :show_details]

  # GET /fields/:id/edit
  def edit
  end

  # PATCH/PUT /fields/:id
  def update
    scrubbed = scrub_field_params(field_params.dup)

    if @field.update(scrubbed)
      redirect_to fields_path, notice: "Campo atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /fields/:id
  def destroy
    @field.destroy
    redirect_to fields_path, notice: "Campo eliminado com sucesso."
  end

  # GET /fields/:id/show_details
  def show_details
    render partial: "fields/view_details", locals: { field: @field }
  end

  private

  def set_field
    @field = current_user.fields.find(params[:id])
  end

  # Strong params alinhados com o teu schema.rb
  # - inclui agricultura e aquacultura
  # - jsonb: polygon_coordinates, field_boundary
  def field_params
    params.require(:field).permit(
      :name,
      :area,
      :latitude, :longitude,
      :notes,
      :status,
      :model_path,
      :humidity, :temperature, :sensors_count,
      :soil_type, :soil_quality,
      :irrigation_type,
      :planting_date, :harvest_date,
      :plantation_type,
      :production_kind,
      :species,
      :tank_volume, :stocking_density, :feeding_regime,
      :fish_placement_date, :estimated_harvest_date,
      :field_type,
      :account_id, # normalmente definido na criação
      :polygon_coordinates,
      :field_boundary
    )
  end

  # --- helpers de sanitização/conversão ---
  def scrub_field_params(permitted)
    # Coerção de números (strings -> float)
    %i[area latitude longitude tank_volume stocking_density].each do |k|
      permitted[k] = to_float_or_nil(permitted[k]) if permitted.key?(k)
    end

    # Datas (aceita "YYYY-MM-DD" ou local)
    %i[planting_date harvest_date fish_placement_date estimated_harvest_date].each do |k|
      permitted[k] = to_date_or_nil(permitted[k]) if permitted[k].present?
    end

    # JSONB seguros
    %i[polygon_coordinates field_boundary].each do |k|
      next unless permitted.key?(k)
      permitted[k] = parse_json_or_nil(permitted[k])
    end

    # Inteiros ocasionais
    %i[humidity temperature sensors_count field_type].each do |k|
      permitted[k] = to_int_or_nil(permitted[k]) if permitted.key?(k)
    end

    permitted
  end

  def parse_json_or_nil(value)
    case value
    when String
      return nil if value.strip.blank?
      JSON.parse(value)
    when ActionController::Parameters, Hash, Array
      value
    else
      nil
    end
  rescue JSON::ParserError
    nil
  end

  def to_float_or_nil(v)
    return nil if v.blank?
    Float(v)
  rescue ArgumentError, TypeError
    nil
  end

  def to_int_or_nil(v)
    return nil if v.blank?
    Integer(v)
  rescue ArgumentError, TypeError
    nil
  end

  def to_date_or_nil(v)
    return nil if v.blank?
    v.is_a?(Date) ? v : Date.parse(v.to_s)
  rescue ArgumentError
    nil
  end
end
