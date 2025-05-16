class RecommendationEngine
  def self.generate_for(field)
    if field.humidity && field.humidity < 30
      Recommendation.create!(
        field: field,
        message: "Agendar irrigação",
        reason: "Humidade do solo abaixo de 30%",
        suggested_for: Time.current + 1.hour
      )
    end

    if field.crop_yields.any? && field.crop_yields.last.month == "Ago"
      Recommendation.create!(
        field: field,
        message: "Avaliar colheita",
        reason: "Última produção registada há mais de 30 dias",
        suggested_for: Time.current
      )
    end
  end
end
