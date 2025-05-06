class ChangeFieldIdNullableOnSensors < ActiveRecord::Migration[7.2]
  def change
    change_column_null :sensors, :field_id, true
  end
end
