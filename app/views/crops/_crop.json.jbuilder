json.extract! crop, :id, :name, :planted_on, :expected_harvest, :notes, :created_at, :updated_at
json.url crop_url(crop, format: :json)
