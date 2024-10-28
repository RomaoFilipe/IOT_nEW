class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]
  before_action :set_crops, only: %i[new edit create update]

  # GET /tasks
  # GET /tasks.json
  def index
    @tasks = Task.all

    respond_to do |format|
      format.html
      format.json do
        render json: @tasks.map do |task|
          {
            id: task.id,
            title: task.name,
            start: task.start_time,
            end: task.end_time,
            color: task.crop.name == 'Irrigação' ? '#28a745' : '#007bff'
          }
        end
      end
    end
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
    @task = Task.new(task_params)

    if @task.save
      redirect_to @task, notice: 'Tarefa criada com sucesso.'
    else
      render :new, status: :unprocessable_entity
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

  # Parâmetros permitidos para criação/atualização de tarefa
  def task_params
    params.require(:task).permit(:crop_id, :name, :start_time, :end_time, :description)
  end
end
