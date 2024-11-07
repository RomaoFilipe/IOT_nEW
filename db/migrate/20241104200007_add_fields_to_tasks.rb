class AddFieldsToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :title, :string
    add_column :tasks, :start, :datetime
    add_column :tasks, :end, :datetime
    add_column :tasks, :task_type, :string
    add_column :tasks, :status, :string
    add_column :tasks, :notes, :text
  end
end
