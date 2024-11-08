class TasksController < ApplicationController
  before_action :authenticate_user! # Certifique-se de que o usuário está autenticado
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  # GET /tasks
  def index
    @tasks = current_user.tasks # Busca apenas tarefas do usuário atual
    render json: @tasks
  end

  # GET /tasks/1
  def show; end

  # GET /tasks/new
  def new
    @task = Task.new
  end

  # GET /tasks/1/edit
  def edit; end

  # POST /tasks
  def create
    @task = current_user.tasks.build(task_params) # Associa a tarefa ao usuário atual

    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      render json: @task, status: :ok
    else
      render json: @task.errors, status: :unprocessable_entity
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy
    render json: { notice: 'Tarefa excluída com sucesso.' }, status: :ok
  end

  private

  # Define a tarefa atual para as ações show, edit, update e destroy
  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :start, :end, :task_type, :status)
  end
end
