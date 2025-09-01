# app/helpers/production_kinds_helper.rb
module ProductionKindsHelper
  # Chaves que usamos em todo o lado: "agriculture" | "aquaculture_tank" | "aquaculture_sea"
  def company_kind_key(company)
    return "agriculture" if company.blank?

    # Se a tua Account tem enum farm_type: { agriculture: 0, aquaculture_tank: 1, aquaculture_sea: 2 }
    if company.respond_to?(:farm_type) && company.farm_type.present?
      company.farm_type.to_s
    else
      company.respond_to?(:production_kind) && company.production_kind.present? ? company.production_kind : "agriculture"
    end
  end

  def kind_label(kind)
    case kind.to_s
    when "agriculture"       then "🌾 Agricultura"
    when "aquaculture_tank"  then "🐟 Aquacultura (Tanque)"
    when "aquaculture_sea"   then "🌊 Aquacultura (Sea)"
    else "🌾 Agricultura"
    end
  end
end
