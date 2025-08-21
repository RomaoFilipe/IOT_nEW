# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_08_21_023225) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_graphql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "supabase_vault"
  enable_extension "uuid-ossp"

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "nif", null: false
    t.integer "farm_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "production_kind"
    t.integer "fields_count", default: 0, null: false
    t.index ["nif"], name: "index_accounts_on_nif", unique: true
    t.index ["production_kind"], name: "index_accounts_on_production_kind"
  end

  create_table "agriculture_fields", force: :cascade do |t|
    t.string "name"
    t.string "field_type"
    t.float "area"
    t.float "latitude"
    t.float "longitude"
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "polygon_coordinates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_agriculture_fields_on_account_id"
    t.index ["user_id"], name: "index_agriculture_fields_on_user_id"
  end

  create_table "aquaculture_readings", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.float "temperature"
    t.float "ph"
    t.float "salinity"
    t.float "oxygen_level"
    t.datetime "measured_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_aquaculture_readings_on_field_id"
  end

  create_table "aquaculture_seas", force: :cascade do |t|
    t.string "name"
    t.float "salinity"
    t.float "wave_height"
    t.float "area"
    t.float "latitude"
    t.float "longitude"
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "polygon_coordinates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_aquaculture_seas_on_account_id"
    t.index ["user_id"], name: "index_aquaculture_seas_on_user_id"
  end

  create_table "aquaculture_tanks", force: :cascade do |t|
    t.string "name"
    t.float "tank_volume"
    t.float "ph_level"
    t.float "temperature"
    t.float "area"
    t.float "latitude"
    t.float "longitude"
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "polygon_coordinates"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_aquaculture_tanks_on_account_id"
    t.index ["user_id"], name: "index_aquaculture_tanks_on_user_id"
  end

  create_table "crop_yields", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.string "crop_type"
    t.float "amount"
    t.string "month"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "index_crop_yields_on_field_id"
  end

  create_table "crops", force: :cascade do |t|
    t.string "name"
    t.date "planted_on"
    t.date "expected_harvest"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fields", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "model_path"
    t.integer "humidity"
    t.integer "temperature"
    t.integer "sensors_count"
    t.string "status"
    t.float "area"
    t.decimal "latitude"
    t.decimal "longitude"
    t.text "notes"
    t.date "planting_date"
    t.date "harvest_date"
    t.string "soil_type"
    t.string "irrigation_type"
    t.jsonb "field_boundary"
    t.jsonb "polygon_coordinates"
    t.string "soil_quality"
    t.bigint "account_id", null: false
    t.integer "field_type", default: 0, null: false
    t.string "species"
    t.float "tank_volume"
    t.float "stocking_density"
    t.string "feeding_regime"
    t.date "fish_placement_date"
    t.date "estimated_harvest_date"
    t.string "plantation_type"
    t.string "production_kind"
    t.index ["account_id"], name: "index_fields_on_account_id"
  end

  create_table "financials", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.decimal "revenue"
    t.decimal "expenses"
    t.decimal "profit"
    t.datetime "recorded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "expense_category"
    t.index ["field_id"], name: "index_financials_on_field_id"
  end

  create_table "irrigation_logs", force: :cascade do |t|
    t.bigint "sensor_id", null: false
    t.datetime "executed_at"
    t.integer "duration"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "device_id"
    t.index ["sensor_id"], name: "index_irrigation_logs_on_sensor_id"
  end

  create_table "irrigation_schedules", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.bigint "sensor_id", null: false
    t.integer "day_of_week", null: false
    t.integer "hour", null: false
    t.integer "minute", null: false
    t.integer "duration", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "executed_at"
    t.integer "scheduled_day"
    t.bigint "irrigation_sensor_id"
    t.index ["field_id"], name: "index_irrigation_schedules_on_field_id"
    t.index ["sensor_id"], name: "index_irrigation_schedules_on_sensor_id"
  end

  create_table "planned_tasks", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "scheduled_for"
    t.boolean "completed"
    t.bigint "field_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "priority"
    t.index ["field_id"], name: "index_planned_tasks_on_field_id"
  end

  create_table "sensor_readings", force: :cascade do |t|
    t.bigint "sensor_id", null: false
    t.float "temperature"
    t.float "moisture"
    t.integer "battery"
    t.integer "signal"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.integer "remaining_time"
    t.integer "last_duration"
    t.integer "light_intensity"
    t.float "wind_speed"
    t.integer "wind_direction"
    t.float "air_temperature"
    t.integer "air_humidity"
    t.float "soil_ph"
    t.float "soil_ec"
    t.integer "soil_nitrogen"
    t.integer "soil_potassium"
    t.integer "soil_phosphorus"
    t.integer "uptime"
    t.integer "error_count"
    t.integer "soil_raw"
    t.decimal "soil_pct", precision: 6, scale: 2
    t.decimal "temp_c", precision: 5, scale: 2
    t.decimal "hum_air", precision: 5, scale: 2
    t.decimal "lux", precision: 10, scale: 2
    t.datetime "measured_at"
    t.jsonb "raw", default: {}
    t.index ["sensor_id", "measured_at"], name: "index_sensor_readings_on_sensor_id_and_measured_at"
    t.index ["sensor_id"], name: "index_sensor_readings_on_sensor_id"
  end

  create_table "sensors", force: :cascade do |t|
    t.string "name"
    t.string "sensor_type"
    t.string "status"
    t.integer "battery"
    t.integer "signal"
    t.string "last_value"
    t.datetime "last_reading"
    t.boolean "active"
    t.string "icon"
    t.bigint "field_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "water_temperature"
    t.float "moisture"
    t.string "device_id"
    t.boolean "manually_disabled"
    t.string "type"
    t.datetime "irrigation_started_at"
    t.integer "irrigation_duration"
    t.integer "remaining_time"
    t.integer "last_duration"
    t.float "oxygen"
    t.float "ph"
    t.float "salinity"
    t.float "ammonia"
    t.float "temperature"
    t.float "current_speed"
    t.string "model"
    t.string "label"
    t.index ["device_id"], name: "index_sensors_on_device_id", unique: true
    t.index ["field_id"], name: "index_sensors_on_field_id"
    t.index ["type"], name: "index_sensors_on_type"
  end

  create_table "soil_readings", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.float "moisture"
    t.float "ph"
    t.integer "nitrogen"
    t.datetime "measured_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "uptime"
    t.integer "light_intensity"
    t.float "wind_speed"
    t.float "air_temperature"
    t.integer "air_humidity"
    t.float "soil_ph"
    t.float "soil_ec"
    t.integer "soil_nitrogen"
    t.integer "soil_potassium"
    t.integer "soil_phosphorus"
    t.integer "error_count"
    t.float "temperature"
    t.integer "wind_direction"
    t.index ["field_id"], name: "index_soil_readings_on_field_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.text "description"
    t.boolean "completed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "photo"
    t.boolean "admin", default: false
    t.string "role"
    t.string "status", default: "active"
    t.boolean "notif_email"
    t.boolean "notif_sms"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "company_nif"
    t.bigint "account_id"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "agriculture_fields", "accounts"
  add_foreign_key "agriculture_fields", "users"
  add_foreign_key "aquaculture_readings", "fields"
  add_foreign_key "aquaculture_seas", "accounts"
  add_foreign_key "aquaculture_seas", "users"
  add_foreign_key "aquaculture_tanks", "accounts"
  add_foreign_key "aquaculture_tanks", "users"
  add_foreign_key "crop_yields", "fields"
  add_foreign_key "fields", "accounts"
  add_foreign_key "financials", "fields"
  add_foreign_key "irrigation_logs", "sensors"
  add_foreign_key "irrigation_schedules", "fields"
  add_foreign_key "irrigation_schedules", "sensors"
  add_foreign_key "planned_tasks", "fields"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensors", "fields"
  add_foreign_key "soil_readings", "fields"
  add_foreign_key "tasks", "users"
  add_foreign_key "users", "accounts"
end
