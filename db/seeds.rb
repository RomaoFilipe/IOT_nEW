# Criar utilizador principal
user = User.find_or_create_by!(email: "admin@farm.com") do |u|
  u.password = "password"
  u.name = "Admin"
  u.admin = true
end

# Criar campos
fields = [
  { name: "North Field", area: 12.5, field_type: "Milho", latitude: 41.15, longitude: -8.61 },
  { name: "South Field", area: 9.2, field_type: "Trigo", latitude: 41.14, longitude: -8.60 },
  { name: "East Field",  area: 7.8, field_type: "Girassol", latitude: 41.16, longitude: -8.59 }
]

fields.each do |f|
  field = user.fields.create!(f.merge(notes: "Campo de teste gerado por seed"))
  
  # Adicionar sensores simulados a cada campo
  3.times do |i|
    field.sensors.create!(
      name: "Sensor #{i+1}",
      sensor_type: Sensor::SENSOR_TYPES.sample,
      status: "active",
      last_value: "#{rand(30..90)}%",
      battery: rand(50..100),
      signal: rand(60..100),
      last_reading: Time.current
    )
  end
end
