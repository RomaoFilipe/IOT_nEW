class AddFieldToCropYields < ActiveRecord::Migration[7.2]
  def change
    add_reference :crop_yields, :field, foreign_key: true
  end
end
