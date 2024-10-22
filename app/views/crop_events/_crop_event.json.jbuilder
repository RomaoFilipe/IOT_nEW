json.extract! crop_event, :id, :name, :description, :event_type, :start_time, :end_time, :created_at, :updated_at
json.url crop_event_url(crop_event, format: :json)
