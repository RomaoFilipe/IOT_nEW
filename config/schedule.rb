# Define onde guardar os logs das execuções agendadas
default_log_path = File.expand_path("../../log/cron.log", __FILE__)
set :output, default_log_path

# Ambiente (usa "production" em deploys reais)
set :environment, "development"

# Tarefa: gerar sugestões inteligentes todos os dias às 6h00
# Garante que o job corre em segundo plano com ActiveJob

every 1.day, at: '6:00 am' do
  runner "GenerateRecommendationsJob.perform_later"
end