class TasksController < ApplicationController
  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to calendar_path, notice: "Task created successfully"
    else
      render :new
    end
  end

  def index
    @tasks = Task.all.map do |task|
      {
        title: task.name,
        start: task.date,
        allDay: task.all_day,
        description: task.description
      }
    end
  end

  private

  def task_params
    params.require(:task).permit(:name, :description, :date, :time, :location, :all_day)
  end
end
