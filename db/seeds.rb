puts "🧹 A limpar base de dados..."
User.destroy_all
Account.destroy_all

puts "✅ Criar Owner (Plataforma)"
owner_account = Account.create!(
  name: "Plataforma Central",
  nif: "999999999",
  farm_type: :agriculture
)

User.create!(
  name: "Dono Geral",
  email: "owner@agrilot.com",
  password: "password123",
  role: "owner",
  status: "active",
  account: owner_account
)

puts "🏢 Criar Conta da Empresa"
account = Account.create!(
  name: "GreenFields Lda",
  nif: "501234567",
  farm_type: :agriculture
)

puts "✅ Criar Admin da Empresa"
admin = User.new(
  name: "Ana Admin",
  email: "admin@greenfields.com",
  password: "password123",
  role: "admin",
  status: "active",
  account: account,
  company_nif: account.nif
)
admin.save!

puts "✅ Criar Manager da Empresa"
manager = User.new(
  name: "Manuel Manager",
  email: "manager@greenfields.com",
  password: "password123",
  role: "manager",
  status: "active",
  account: account,
  company_nif: account.nif
)
manager.save!

puts "✅ Criar Viewer da Empresa"
User.create!(
  name: "Vera Viewer",
  email: "viewer@greenfields.com",
  password: "password123",
  role: "viewer",
  status: "active",
  account: account
)

puts "🌱 Seeds criadas com sucesso!"
