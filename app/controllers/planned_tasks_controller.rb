class PlannedTasksController < ApplicationController
  def create
    @task = current_user.planned_tasks.new(task_params)
    if @task.save
      PlannedEventsChannel.broadcast_to(current_user, {
        action: 'create',
        task: render_to_string(partial: "dashboard/event", locals: { event: @task.to_event_hash })
      })
      redirect_to dashboard_path, notice: "Tarefa criada com sucesso."
    else
      # tratamento de erro
    end
  end

  def destroy
    @task = PlannedTask.find(params[:id])
    if @task.destroy
      PlannedEventsChannel.broadcast_to(current_user, {
        action: 'destroy',
        id: @task.id
      })
      redirect_to dashboard_path, notice: "Tarefa cancelada com sucesso."
    else
      redirect_to dashboard_path, alert: "Erro ao cancelar a tarefa."
    end
  end

  private

  def task_params
    params.require(:planned_task).permit(:title, :description, :scheduled_for, :priority, :field_id)
  end
end
