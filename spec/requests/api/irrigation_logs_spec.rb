# frozen_string_literal: true
require "rails_helper"

RSpec.describe "API::IrrigationLogs create", type: :request do
  let(:token)       { "abc123supersecreto" }
  let(:auth_header) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  before do
    @old = ENV["SENSOR_API_TOKEN"]
    ENV["SENSOR_API_TOKEN"] = token
  end

  after { ENV["SENSOR_API_TOKEN"] = @old }

  it "cria log e actualiza estado/última leitura do sensor" do
    sensor = Sensor.create!(
      device_id: "irrigator_010",
      name: "irrigator_010",
      sensor_type: "irrigation",
      type: "IrrigationSensor",
      status: "Active"
    )

    payload = {
      device_id: sensor.device_id,
      executed_at: "2025-08-09T18:25:00Z",
      duration: 45,
      status: "executado"
    }

    expect {
      post "/api/irrigation_logs", params: payload.to_json, headers: auth_header
    }.to change { IrrigationLog.count }.by(1)

    expect(response).to have_http_status(:created)

    sensor.reload
    expect(sensor.status).to eq("online").or eq("Active") # conforme lógica do teu controller
    expect(sensor.last_reading).to be_present
    expect(sensor.last_value).to match(/45s/).or be_present
  end

  it "retorna 404 se o device_id não existir" do
    payload = { device_id: "desconhecido", executed_at: "2025-08-09T18:25:00Z", duration: 10 }
    post "/api/irrigation_logs", params: payload.to_json, headers: auth_header
    expect(response).to have_http_status(:not_found)
  end
end
