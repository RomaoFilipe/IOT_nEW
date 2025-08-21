# app/controllers/fields_controller.rb
class FieldsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_field, only: [:show, :edit, :update, :destroy, :show_details]

  # GET /fields
  def index
    # Lista apenas os campos do utilizador atual
    @fields = current_user.fields
                          .includes(:sensors) # evita N+1 ao ler sensores
                          .order(created_at: :desc)

    # Instância para o modal "novo campo"
    @field = current_user.fields.build(
      account_id: current_user.account_id # assegura FK obrigatória
    )

    # Métricas rápidas (sem N+1)
    field_ids = @fields.pluck(:id)

    # Se manténs o counter_cache (:sensors_count) atualizado, usa-o:
    if Field.column_names.include?("sensors_count")
      @total_sensors = @fields.sum(:sensors_count)
    else
      @total_sensors = Sensor.where(field_id: field_ids).count
    end

    @total_fields   = @fields.size
    @active_sensors = Sensor.where(field_id: field_ids)
                            .where("LOWER(COALESCE(status, '')) = 'active'")
                            .count
  rescue => e
    Rails.logger.warn("[Fields#index] Falha a preparar listagem: #{e.class}: #{e.message}")
    @fields = Field.none
    @field  = current_user.fields.build(account_id: current_user.account_id)
    @total_fields = @total_sensors = @active_sensors = 0
  end

  # GET /fields/:id
  def show
  end

  # GET /fields/:id/edit
  def edit
  end

  # POST /fields
  def create
    @field = current_user.fields.build(field_params)
    @field.account_id ||= current_user.account_id

    if @field.save
      redirect_to fields_path, notice: "Campo criado com sucesso."
    else
      # Recarrega listagem e métricas para re-render do index com erros no modal
      recalc_index_state_for_failed_form
      render :index, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /fields/:id
  def update
    if @field.update(field_params)
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

  # GET /fields/:id/show_details (parcial)
  def show_details
    render partial: "fields/view_details", locals: { field: @field }
  end

  private

  # Garante que só acedes a campos do utilizador atual
  def set_field
    @field = current_user.fields.find(params[:id])
  end

  # Strong params + sanitização de JSON
  def field_params
    permitted = params.require(:field).permit(
      :name,
      :area,
      :latitude,
      :longitude,
      :notes,
      :species,
      :tank_volume,
      :stocking_density,
      :feeding_regime,
      :fish_placement_date,
      :estimated_harvest_date,
      :plantation_type,
      :production_kind,
      :soil_type,
      :soil_quality,
      :irrigation_type,
      :planting_date,
      :harvest_date,
      :field_type,           # enum inteiro (se usado)
      :account_id,           # assegura FK, por norma igual a current_user.account_id
      :model_path,
      :status,
      :sensors_count,        # só se permitires atualizar via form (normalmente não)
      :field_boundary,       # pode vir como JSON string
      :polygon_coordinates   # pode vir como JSON string
    )

    # Sanitiza campos JSON quando vêm como string (ex.: do form/JS)
    %i[field_boundary polygon_coordinates].each do |json_attr|
      next unless permitted[json_attr].present?

      if permitted[json_attr].is_a?(String)
        permitted[json_attr] = safe_parse_json(permitted[json_attr])
      end
    end

    permitted
  end

  def safe_parse_json(str)
    JSON.parse(str)
  rescue JSON::ParserError
    Rails.logger.warn("[FieldsController] JSON inválido em param: #{str.truncate(120)}")
    nil
  end

  # Recalcular estado do index quando create falha (para o modal mostrar erros)
  def recalc_index_state_for_failed_form
    @fields = current_user.fields.includes(:sensors).order(created_at: :desc)
    field_ids = @fields.pluck(:id)

    if Field.column_names.include?("sensors_count")
      @total_sensors = @fields.sum(:sensors_count)
    else
      @total_sensors = Sensor.where(field_id: field_ids).count
    end
    @total_fields   = @fields.size
    @active_sensors = Sensor.where(field_id: field_ids)
                            .where("LOWER(COALESCE(status, '')) = 'active'")
                            .count
  end
end
