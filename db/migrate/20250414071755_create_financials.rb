class CreateFinancials < ActiveRecord::Migration[7.2]
  def change
    create_table :financials do |t|
      t.references :field, null: false, foreign_key: true
      t.decimal :revenue
      t.decimal :expenses
      t.decimal :profit
      t.datetime :recorded_at

      t.timestamps
    end
  end
end
