class CropYieldsController < ApplicationController
  MESES_PT = {
    "Jan" => "Jan", "Feb" => "Fev", "Mar" => "Mar", "Apr" => "Abr",
    "May" => "Mai", "Jun" => "Jun", "Jul" => "Jul", "Aug" => "Ago",
    "Sep" => "Set", "Oct" => "Out", "Nov" => "Nov", "Dec" => "Dez",
    "Fev" => "Fev", "Abr" => "Abr", "Ago" => "Ago", "Set" => "Set", "Out" => "Out", "Dez" => "Dez"
  }

  def create
    crop_types = params[:crop_yield][:crop_type]
    amounts    = params[:crop_yield][:amount]
    months     = params[:crop_yield][:month]
    field_id   = params[:crop_yield][:field_id]

    @new_yields = []

    crop_types.each_with_index do |type, i|
      mes_normalizado = MESES_PT[months[i]] || months[i]

      yield_record = CropYield.create!(
        field_id: field_id,
        crop_type: type.presence,
        amount: amounts[i].to_f,
        month: mes_normalizado
      )

      @new_yields << yield_record
    end

    respond_to do |format|
      format.html { redirect_to analytics_path(field_id: field_id), notice: "Produção registada com sucesso." }
      format.turbo_stream
    end
  end
end
