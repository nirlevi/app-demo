# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Seeding database..."

# Create demo organization
org = Organization.find_or_create_by(slug: "demo-company") do |o|
  o.name = "Demo Company"
end
puts "✅ Created organization: #{org.name}"

# Create admin user
admin = User.find_or_create_by(email: "admin@demo.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.first_name = "Demo"
  u.last_name = "Admin"
  u.organization = org
  u.role = "admin"
end
puts "✅ Created admin user: #{admin.email}"

# Create agent user
agent = User.find_or_create_by(email: "agent@demo.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"  
  u.first_name = "Demo"
  u.last_name = "Agent"
  u.organization = org
  u.role = "agent"
end
puts "✅ Created agent user: #{agent.email}"

# Create sample call data
if Item.count == 0
  puts "📞 Creating sample call data..."
  
  50.times do |i|
    Item.create!(
      name: "Call #{i + 1}",
      description: "Demo call record",
      category: "communication",
      status: ["active", "inactive", "archived"].sample,
      metadata: { duration: rand(30..600) },
      organization: org,
      created_by: admin,
      created_at: rand(30.days.ago..Time.current)
    )
  end
  
  puts "✅ Created #{Item.count} sample call records"
end

puts "🎉 Seeding completed!"
puts
puts "🔑 Demo Login Credentials:"
puts "  Admin: admin@demo.com / password123"
puts "  Agent: agent@demo.com / password123"
puts
puts "🚀 Start the server: bundle exec rails server"
puts "🌐 Visit: http://localhost:3000"
