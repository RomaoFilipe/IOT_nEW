# app.rb
require 'sinatra'
require 'json'
require 'net/http'
require 'uri'

# Middleware simples para autenticação
before do
  halt 401, 'Unauthorized' unless request.env["HTTP_AUTHORIZATION"] == "Bearer #{ENV['API_TOKEN']}"
end

# Endpoint para receber leitura de sensores
def forward_to_main_api(sensor_id, payload)
  uri = URI("#{ENV['RAILS_API_URL']}/#{sensor_id}/simulate")
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{ENV['API_TOKEN']}"
  })
  request.body = payload.to_json
  http.request(request)
end

post '/readings/:id' do
  sensor_id = params[:id]
  begin
    payload = JSON.parse(request.body.read)
    response = forward_to_main_api(sensor_id, payload)
    status response.code.to_i
    body response.body
  rescue => e
    status 500
    { error: e.message }.to_json
  end
end

# Healthcheck
get '/' do
  'Sensor Gateway is running'
end
