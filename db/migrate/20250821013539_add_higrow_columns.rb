class AddHigrowColumns < ActiveRecord::Migration[7.2]
  def change
    # --- SENSOR READINGS ---
    add_column :sensor_readings, :soil_raw, :integer unless column_exists?(:sensor_readings, :soil_raw)
    unless column_exists?(:sensor_readings, :soil_pct)
      add_column :sensor_readings, :soil_pct, :decimal, precision: 6, scale: 2
    end
    unless column_exists?(:sensor_readings, :temp_c)
      add_column :sensor_readings, :temp_c,  :decimal, precision: 5, scale: 2
    end
    unless column_exists?(:sensor_readings, :hum_air)
      add_column :sensor_readings, :hum_air, :decimal, precision: 5, scale: 2
    end
    unless column_exists?(:sensor_readings, :lux)
      add_column :sensor_readings, :lux,     :decimal, precision: 10, scale: 2
    end
    add_column :sensor_readings, :measured_at, :datetime unless column_exists?(:sensor_readings, :measured_at)
    add_column :sensor_readings, :raw, :jsonb, default: {} unless column_exists?(:sensor_readings, :raw)

    unless index_exists?(:sensor_readings, [:sensor_id, :measured_at])
      add_index :sensor_readings, [:sensor_id, :measured_at]
    end

    # --- SENSORS ---
    # device_id já existe no schema; garantir unicidade
    unless index_exists?(:sensors, :device_id, unique: true)
      # Se já houver duplicados em produção, este índice vai falhar.
      # Primeiro limpa duplicados ou usa um índice parcial.
      add_index :sensors, :device_id, unique: true
    end
  end
end
