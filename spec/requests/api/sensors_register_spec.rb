# frozen_string_literal: true
require "rails_helper"

RSpec.describe "API::Sensors register", type: :request do
  let(:token)       { "abc123supersecreto" }
  let(:auth_header) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  before do
    # isola o ENV usado no controller
    @old = ENV["SENSOR_API_TOKEN"]
    ENV["SENSOR_API_TOKEN"] = token
  end

  after { ENV["SENSOR_API_TOKEN"] = @old }

  it "cria um sensor como irrigation e define STI (IrrigationSensor)" do
    payload = {
      device_id: "irrigator_001",
      name: "irrigator_001",
      sensor_type: "irrigation",
      field_id: 1
    }

    expect {
      post "/api/sensors/register", params: payload.to_json, headers: auth_header
    }.to change { Sensor.count }.by(1)

    expect(response).to have_http_status(:created)
    s = Sensor.find_by(device_id: "irrigator_001")
    expect(s).to be_present
    expect(s.sensor_type).to eq("irrigation")
    expect(s.type).to eq("IrrigationSensor") # STI
    expect(s.field_id).to eq(1)
  end

  it "não faz downgrade do tipo ao chamar identify sem sensor_type" do
    # 1) regista como irrigation
    post "/api/sensors/register",
         params: { device_id: "irrigator_002", sensor_type: "irrigation" }.to_json,
         headers: auth_header
    expect(response).to have_http_status(:created)

    # 2) chama identify SEM sensor_type
    get "/api/sensors/identify", params: { device_id: "irrigator_002" }
    expect(response).to have_http_status(:ok)

    s = Sensor.find_by(device_id: "irrigator_002")
    expect(s.sensor_type).to eq("irrigation")
    expect(s.type).to eq("IrrigationSensor")
  end

  it "é idempotente: segundo POST actualiza sem duplicar" do
    post "/api/sensors/register",
         params: { device_id: "irrigator_003", sensor_type: "irrigation", field_id: 5 }.to_json,
         headers: auth_header
    expect(response).to have_http_status(:created)

    # actualizar apenas o name e status
    post "/api/sensors/register",
         params: { device_id: "irrigator_003", name: "valvula_norte", status: "Active" }.to_json,
         headers: auth_header
    expect(response).to have_http_status(:created)

    s = Sensor.find_by(device_id: "irrigator_003")
    expect(s.name).to eq("valvula_norte")
    expect(s.field_id).to eq(5)                 # manteve
    expect(s.sensor_type).to eq("irrigation")   # manteve
    expect(s.type).to eq("IrrigationSensor")    # manteve STI
  end
end
