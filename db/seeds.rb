puts "🌱 A criar utilizador admin..."

User.create!(
  name: "Administrador",
  email: "admin@iot.local",
  password: "admin123",
  password_confirmation: "admin123",
  role: "admin",
  company_nif: "999999990"
)

puts "✅ Utilizador admin criado com sucesso!"
