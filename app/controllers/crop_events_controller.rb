class CropEventsController < ApplicationController
  before_action :set_crop_event, only: %i[ show edit update destroy ]

  # GET /crop_events or /crop_events.json
  def index
    @crop_events = CropEvent.all

    respond_to do |format|
      format.html
      format.json { render json: @crop_events.map { |event|
        {
          id: event.id,
          title: event.name,
          start: event.start_time,
          end: event.end_time,
          description: event.description,
          url: crop_event_path(event)
        }
      }}
    end

  # GET /crop_events/1 or /crop_events/1.json
  def show
  end

  # GET /crop_events/new
  def new
    @crop_event = CropEvent.new
    @crop_event.start_time = params[:start_time] if params[:start_time]
  end

  # GET /crop_events/1/edit
  def edit
  end

  # POST /crop_events or /crop_events.json
  def create
    @crop_event = CropEvent.new(crop_event_params)

    respond_to do |format|
      if @crop_event.save
        format.html { redirect_to @crop_event, notice: "Crop event was successfully created." }
        format.json { render :show, status: :created, location: @crop_event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @crop_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crop_events/1 or /crop_events/1.json
  def update
    respond_to do |format|
      if @crop_event.update(crop_event_params)
        format.html { redirect_to @crop_event, notice: "Crop event was successfully updated." }
        format.json { render :show, status: :ok, location: @crop_event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @crop_event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crop_events/1 or /crop_events/1.json
  def destroy
    @crop_event.destroy!

    respond_to do |format|
      format.html { redirect_to crop_events_path, status: :see_other, notice: "Crop event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crop_event
      @crop_event = CropEvent.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def crop_event_params
      params.require(:crop_event).permit(:name, :description, :event_type, :start_time, :end_time)
    end
end
