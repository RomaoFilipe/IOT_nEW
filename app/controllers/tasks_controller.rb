class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  # GET /tasks
  # GET /tasks.json
  def index
    tasks = Task.all
    render json: tasks.map { |task| { id: task.id, title: task.title, start: task.start, end: task.end, task_type: task.task_type, status: task.status } }
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
    task = Task.new(task_params)
    if task.save
      render json: task, status: :created
    else
      render json: task.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      redirect_to @task, notice: 'Tarefa atualizada com sucesso.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy
    redirect_to tasks_url, notice: 'Tarefa excluída com sucesso.'
  end

  private

  # Define a tarefa atual para as ações show, edit, update e destroy
  def set_task
    @task = Task.find(params[:id])
  end

  # Carrega as culturas disponíveis para o formulário de tarefa
  def set_crops
    @crops = Crop.all
  end

  private
  # Parâmetros permitidos para criação/atualização de tarefa
  def task_params
    params.require(:task).permit(:title, :start, :end, :task_type, :status, :notes)
  end
end
