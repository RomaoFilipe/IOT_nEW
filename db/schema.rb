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

ActiveRecord::Schema[7.2].define(version: 2025_05_20_053044) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.string "field_type"
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
    t.index ["sensor_id"], name: "index_irrigation_logs_on_sensor_id"
  end

  create_table "irrigation_schedules", force: :cascade do |t|
    t.bigint "field_id", null: false
    t.integer "day_of_week", null: false
    t.integer "hour", null: false
    t.integer "minute", null: false
    t.integer "duration", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sensor_id", null: false
    t.index ["field_id"], name: "index_irrigation_schedules_on_field_id"
    t.index ["sensor_id"], name: "index_irrigation_schedules_on_sensor_id"
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
    t.float "temperature"
    t.float "moisture"
    t.string "device_id"
    t.boolean "manually_disabled"
    t.string "type"
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
    t.index ["field_id"], name: "index_soil_readings_on_field_id"
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "crop_yields", "fields"
  add_foreign_key "financials", "fields"
  add_foreign_key "irrigation_logs", "sensors"
  add_foreign_key "irrigation_schedules", "fields"
  add_foreign_key "irrigation_schedules", "sensors"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensors", "fields"
  add_foreign_key "soil_readings", "fields"
end
