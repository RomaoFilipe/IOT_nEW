class GenerateRecommendationsJob < ApplicationJob
  queue_as :default

  def perform
    Field.includes(:sensors, :crop_yields).find_each do |field|
      RecommendationEngine.generate_for(field)
    end
  end
end
