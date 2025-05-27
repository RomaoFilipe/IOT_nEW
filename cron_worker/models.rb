require "active_record"
require "pg"
require "dotenv/load"

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: ENV['DB_HOST'] || 'db',
  username: ENV['DB_USERNAME'] || 'admin123',
  password: ENV['DB_PASSWORD'] || 'admin123',
  database: ENV['DB_NAME'] || 'IOT_development'
)

class Sensor < ActiveRecord::Base
  self.inheritance_column = :_type_disabled  # ✅ isto desativa o STI
  has_many :irrigation_schedules
end

class IrrigationSchedule < ActiveRecord::Base
  belongs_to :sensor
end
