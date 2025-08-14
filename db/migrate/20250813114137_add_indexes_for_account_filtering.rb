class AddIndexesForAccountFiltering < ActiveRecord::Migration[7.2]
  def change
    # Para filtros por conta via Field
    add_index :fields, :account_id unless index_exists?(:fields, :account_id)

    # Relacionamentos mais comuns
    add_index :sensors, :field_id unless index_exists?(:sensors, :field_id)
    add_index :irrigation_schedules, :sensor_id unless index_exists?(:irrigation_schedules, :sensor_id)
  end
end
