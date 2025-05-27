class PlannedTasksController < ApplicationController
  def destroy
    @task = PlannedTask.find(params[:id])
    @task.destroy
    redirect_to dashboard_path, notice: "Tarefa cancelada com sucesso."
  end
end
