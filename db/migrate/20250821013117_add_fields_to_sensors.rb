class AddFieldsToSensors < ActiveRecord::Migration[7.2]
  def change
    # Só adiciona a referência se não existir
    unless column_exists?(:sensors, :field_id)
      add_reference :sensors, :field, null: true, foreign_key: true
    else
      # Se já existir a coluna mas faltar a FK, tenta criá-la
      unless foreign_key_exists?(:sensors, :fields)
        add_foreign_key :sensors, :fields
      end
    end

    add_column :sensors, :model, :string unless column_exists?(:sensors, :model)
    add_column :sensors, :label, :string unless column_exists?(:sensors, :label)

    # Garante índice único para device_id
    add_index :sensors, :device_id, unique: true unless index_exists?(:sensors, :device_id, unique: true)
  end
end
