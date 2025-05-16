class CreateRecommendations < ActiveRecord::Migration[7.2]
  def change
    create_table :recommendations do |t|
      t.references :field, null: false, foreign_key: true
      t.string :message
      t.string :reason
      t.datetime :suggested_for
      t.boolean :dismissed

      t.timestamps
    end
  end
end
