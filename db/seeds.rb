# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
CropYield.create!([
  { month: "Jan", corn_yield: 4000, wheat_yield: 3000 },
  { month: "Feb", corn_yield: 2500, wheat_yield: 2000 },
  { month: "Mar", corn_yield: 10000, wheat_yield: 1500 },
  { month: "Apr", corn_yield: 3000, wheat_yield: 3500 },
  { month: "May", corn_yield: 5000, wheat_yield: 4000 },
  { month: "Jun", corn_yield: 4000, wheat_yield: 4200 },
  { month: "Jul", corn_yield: 4700, wheat_yield: 4600 }
])