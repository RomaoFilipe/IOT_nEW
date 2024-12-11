class AddFieldsToTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :title, :string unless column_exists?(:tasks, :title)
    add_column :tasks, :start, :datetime unless column_exists?(:tasks, :start)
    add_column :tasks, :end, :datetime unless column_exists?(:tasks, :end)
    add_column :tasks, :task_type, :string unless column_exists?(:tasks, :task_type)
    add_column :tasks, :status, :string unless column_exists?(:tasks, :status)
    add_column :tasks, :notes, :text unless column_exists?(:tasks, :notes)
  end
end
