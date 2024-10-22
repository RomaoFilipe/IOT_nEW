class CreateCropEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :crop_events do |t|
      t.string :name
      t.text :description
      t.string :event_type
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
