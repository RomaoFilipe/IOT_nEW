# app/controllers/fields_controller.rb
class FieldsController < ApplicationController
  before_action :authenticate_user!

  def index
    @fields = current_account.fields
                             .includes(:sensors) # evita N+1 na listagem
                             .order(updated_at: :desc)

    # usado pelo modal "Adicionar Novo Campo"
    @field  = current_account.fields.build(user: current_user)
    assign_company_safely(@field)
    apply_field_type_from_account(@field)
  end

  def new
    @field = current_account.fields.build(user: current_user)
    assign_company_safely(@field)
    apply_field_type_from_account(@field)
  end

  def update_polygon
  @field = current_account.fields.find(params[:id])
  coords = params[:polygon_coordinates]

  unless coords.is_a?(Array) && coords.all? { |p| p.is_a?(Array) && p.size == 2 }
    return render json: { error: "Formato inválido." }, status: :unprocessable_entity
  end

  # guarda como array de [lng,lat] (JSON column recomendada)
  @field.update!(polygon_coordinates: coords)
  render json: { ok: true }
end

  def create
    # constrói SEMPRE pela conta do utilizador (garante account_id)
    @field = current_account.fields.build(field_params)
    @field.user ||= current_user

    # company é opcional — só atribuímos se o modelo tiver a associação
    assign_company_safely(@field)

    # normaliza o tipo do campo a partir do farm_type da conta (se existir)
    apply_field_type_from_account(@field)

    if @field.save
      respond_to do |format|
        format.html { redirect_to fields_path, notice: "Campo criado com sucesso." }
        format.turbo_stream do
          flash.now[:notice] = "Campo criado com sucesso."
          render turbo_stream: turbo_stream.prepend(
            "fields_list",
            partial: "fields/card",
            locals: { field: @field }
          )
        end
      end
    else
      # recarrega lista para o index não rebentar quando há erros
      @fields = current_account.fields
                              .select(:id, :name, :latitude, :longitude, :area, :field_type, :updated_at, :polygon_coordinates)
                              .order(updated_at: :desc)

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
    @field = current_account.fields.find(params[:id])
  end

  def update
    @field = current_account.fields.find(params[:id])

    if @field.update(field_params)
      redirect_to fields_path, notice: "Campo atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @field = current_account.fields.find(params[:id])
    @field.destroy
    redirect_to fields_path, notice: "Campo eliminado com sucesso."
  end

  def show_details
    @field = current_account.fields.find(params[:id])
    render partial: "fields/view_details", locals: { field: @field }
  end

  private

  # ——— helpers ———

  def current_account
    current_user.account
  end

  # Atribui company só se a associação existir e for compatível
  def assign_company_safely(field)
    return unless field.respond_to?(:company=)

    candidate =
      if current_user.respond_to?(:company) && current_user.company.present?
        current_user.company
      elsif current_account.respond_to?(:company) && current_account.company.present?
        current_account.company
      else
        # Em muitos projetos "company" é na prática a própria Account.
        # Só atribuímos se a classe coincidir para não dar AssociationTypeMismatch.
        current_account
      end

    # evita AssociationTypeMismatch (Company esperado vs Account)
    begin
      field.company ||= candidate
    rescue ActiveRecord::AssociationTypeMismatch
      # ignora se a classe não for a esperada
    end
  end

  # Sincroniza field_type com o farm_type da conta (se existir)
  def apply_field_type_from_account(field)
    return unless field.respond_to?(:field_type) && current_account.respond_to?(:farm_type)

    ft = current_account.farm_type.presence
    field.field_type = ft if ft.present?
  end

  def field_params
    permitted = params.require(:field).permit(
      :name, :area, :latitude, :longitude, :notes, :polygon_coordinates,
      :species, :tank_volume, :stocking_density, :feeding_regime,
      :fish_placement_date, :estimated_harvest_date, :plantation_type,
      :production_kind, :field_type # se vier do form, deixamos passar
    )

    # aceitar JSON de polígono vindo como string
    if permitted[:polygon_coordinates].present? && permitted[:polygon_coordinates].is_a?(String)
      begin
        permitted[:polygon_coordinates] = JSON.parse(permitted[:polygon_coordinates])
      rescue JSON::ParserError
        permitted[:polygon_coordinates] = nil
      end
    end

    permitted
  end
end
