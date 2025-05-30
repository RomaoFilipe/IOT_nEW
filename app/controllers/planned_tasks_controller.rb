class PlannedTasksController < ApplicationController
  def destroy
    @task = PlannedTask.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path, notice: "Tarefa cancelada com sucesso." }
    end
  end
end
