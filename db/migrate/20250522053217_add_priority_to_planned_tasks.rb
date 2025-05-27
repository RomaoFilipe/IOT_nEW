class AddPriorityToPlannedTasks < ActiveRecord::Migration[7.2]
  def change
    add_column :planned_tasks, :priority, :string
  end
end
