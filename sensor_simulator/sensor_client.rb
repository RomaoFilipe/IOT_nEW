require 'net/http'
require 'uri'
require 'json'
require 'time'  # necessário para usar .iso8601


SENSOR_IDS = [1, 2, 3, 4]
API_URL = "http://host.docker.internal:3000/api/sensors"
API_TOKEN = ENV.fetch("API_TOKEN", "abc123supersecreto")

loop do
  SENSOR_IDS.each do |id|
    uri = URI("#{API_URL}/#{id}/simulate")

    data = {
      battery: rand(60..100),
      signal: rand(50..100),
      temperature: rand(15..35),
      moisture: rand(30..90),
      value: "#{rand(10..90)}%",
      read_at: Time.now.iso8601
    }

    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{API_TOKEN}"
    }

    begin
      res = Net::HTTP.post(uri, data.to_json, headers)
      puts "[#{Time.now}] Sensor ##{id} => #{res.code}: #{res.body}"
    rescue => e
      puts "Erro ao enviar para o sensor #{id}: #{e.message}"
    end
  end

  sleep 10
end
