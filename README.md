# VoipAppz Dashboard - Ruby on Rails Monolith

A modern VoIP call center dashboard application built as a Rails monolith with server-rendered views, real-time WebSocket connections, and responsive design. Features live agent monitoring, call analytics, and comprehensive reporting.

## ⚡ Quick Start Summary

**Prerequisites:** Ruby 3.3.0+, Git  
**Setup Time:** ~5 minutes

```bash
# 1. Clone and setup
git clone <this-repo> && cd shopify-app-template-ruby/web
bundle install

# 2. Create database with demo data  
bin/rails db:create db:migrate db:seed

# 3. Start server
bundle exec rails server

# 4. Login at http://localhost:3000
# Admin: admin@demo.com / password123
# Agent: agent@demo.com / password123
```

**What You Get:**
✅ Complete VoIP dashboard with real-time updates  
✅ User authentication (Devise + JWT)  
✅ Sample data (50+ call records)  
✅ Responsive design with modern CSS  
✅ Comprehensive test suite  
✅ Production-ready Rails 7 app

## 🚀 Quick Start From Scratch

### Prerequisites
```bash
# Required software
- Ruby 3.3.0+ (with bundler)
- Git
- Redis server (optional, for ActionCable in production)
```

### Step 1: Clone Repository
```bash
git clone <this-repo>
cd shopify-app-template-ruby/web
```

### Step 2: Install Dependencies
```bash
# Install Ruby gems
bundle install

# If bundler is not installed
gem install bundler
bundle install
```

### Step 3: Setup Database from Scratch
```bash
# Create database, run migrations, and seed with sample data
bin/rails db:create db:migrate db:seed

# Or run individually:
# bin/rails db:create    # Create the database
# bin/rails db:migrate   # Run all migrations
# bin/rails db:seed      # Seed with sample data
```

### Step 4: Verify Demo Users (Already Created by Seeds!)
The `bin/rails db:seed` command automatically creates demo users. You should see output like:
```
🌱 Seeding database...
✅ Created organization: Demo Company
✅ Created admin user: admin@demo.com
✅ Created agent user: agent@demo.com
📞 Creating sample call data...
✅ Created 50 sample call records
🎉 Seeding completed!

🔑 Demo Login Credentials:
  Admin: admin@demo.com / password123
  Agent: agent@demo.com / password123
```

**Manual Creation (if needed):**
```bash
# Only if seeds didn't work, create manually via Rails console
bin/rails console

# Create demo users manually (see seeds.rb for exact code)
# Then exit
```

### Step 5: Start Development Server
```bash
# Start Rails server
bundle exec rails server

# Server will be available at:
# http://localhost:3000
```

### Step 6: Login to Application
- **URL**: http://localhost:3000
- **Admin Login**: admin@demo.com / password123
- **Agent Login**: agent@demo.com / password123

### 🧪 Test User Credentials
For **testing purposes**, use these test user accounts:

**Production/Demo Users (created by db:seed):**
- **Admin**: admin@demo.com / password123
- **Agent**: agent@demo.com / password123

**Test Users (available in test fixtures for integration tests):**
- **Test User 1**: user@example.com / password123
- **Test User 2**: user2@example.com / password123

**Note**: Test fixture users are only available during test runs. Use the demo users (admin@demo.com, agent@demo.com) for manual testing and development.

### Demo Data Available
After seeding, you'll have:
- 2 demo users (admin and agent)
- Sample organization
- 50+ demo call records
- Live dashboard with real-time features

### Alternative: Automatic Demo User Setup
If you want demo users created automatically during `db:seed`, check the seed file:
```bash
# View current seed configuration
cat db/seeds.rb

# Seeds will automatically create:
# - Demo organization
# - Admin and agent users
# - Sample call data
```

## 📊 Features

### 🔴 Live Dashboard
- **Real-time Agent Monitoring**: Live agent status and call activity
- **Active Call Display**: Current calls with duration and status
- **WebSocket Integration**: Real-time updates using ActionCable
- **Agent Statistics**: Call counts and performance metrics

### 📈 Reports & Analytics  
- **Call Reports**: Comprehensive call history and analytics
- **Date Range Filtering**: Custom date range selection
- **Data Export**: CSV and PDF export capabilities
- **Visual Charts**: Interactive charts and graphs

### 🎤 Call Management
- **Call History**: Detailed call records with filtering
- **Recording Playback**: Audio recording management
- **Search & Filter**: Advanced search and filtering options
- **Status Tracking**: Call status and duration tracking

### 🔐 Authentication & Security
- **Devise Authentication**: Secure user authentication system
- **Session Management**: Persistent login sessions
- **Protected Routes**: Authentication-based route protection
- **Organization Support**: Multi-tenant organization structure

### 🏗️ Modern Rails Architecture
- **Rails 7 Monolith**: Server-rendered ERB templates
- **Stimulus Controllers**: Progressive JavaScript enhancement
- **ActionCable**: Real-time WebSocket connections
- **Responsive Design**: Mobile-friendly CSS with modern layouts
- **Asset Pipeline**: Optimized asset compilation and delivery

## 💻 Development Commands

### Essential Commands
```bash
# Development
bundle exec rails server       # Start Rails server
bin/rails assets:precompile    # Build and precompile assets
bundle install                 # Install Ruby dependencies
bin/rails console              # Open Rails console

# Database
bin/rails db:create db:migrate db:seed  # Create, migrate, and seed database
bin/rails db:migrate           # Run migrations only
bin/rails db:seed               # Seed database with sample data

# Testing & Quality
bundle exec rails test                    # Run all Rails tests
bundle exec rails test test/integration/  # Run integration tests only
bundle exec rails test test/system/       # Run system tests (if available)
bundle exec rails test test/integration/login_test.rb  # Run login tests specifically
bundle exec rubocop                      # Run RuboCop linting
```

### Manual Commands (if needed)
```bash
# Manual dependency installation
bundle install                 # Install Ruby gems

# Manual database operations
bin/rails db:create            # Create database
bin/rails db:migrate           # Run migrations  
bin/rails db:seed              # Seed with sample data

# Manual server start
bundle exec rails server       # Start Rails server directly

# Asset compilation
bin/rails assets:precompile    # Precompile assets
```

## 📱 Application Structure

```
voipappz-mini-app-template/
├── web/                       # Rails application
│   ├── app/
│   │   ├── controllers/       # Rails controllers
│   │   │   ├── dashboard_controller.rb    # Live dashboard
│   │   │   ├── calls_controller.rb        # Call management
│   │   │   ├── reports_controller.rb      # Analytics
│   │   │   └── auth_controller.rb         # Authentication
│   │   ├── views/             # ERB templates
│   │   │   ├── dashboard/     # Dashboard views
│   │   │   ├── calls/         # Call management views
│   │   │   ├── reports/       # Report views
│   │   │   └── shared/        # Shared partials
│   │   ├── models/            # ActiveRecord models
│   │   │   ├── user.rb        # User with Devise
│   │   │   ├── organization.rb # Organization model
│   │   │   └── item.rb        # Call/Item model
│   │   ├── channels/          # ActionCable channels
│   │   │   └── dashboard_live_channel.rb
│   │   ├── javascript/        # Stimulus controllers
│   │   │   └── controllers/   # JavaScript controllers
│   │   │       ├── clock_controller.js
│   │   │       ├── live_updates_controller.js
│   │   │       └── filters_controller.js
│   │   ├── assets/            # CSS and assets
│   │   │   └── stylesheets/
│   │   │       └── application.css  # Main stylesheet
│   │   └── services/          # Business logic services
│   └── config/                # Rails configuration
├── README.md                  # This file
├── ARCHITECTURE.md            # Architecture documentation
├── DEVELOPMENT.md             # Development guide
└── DEPLOYMENT.md              # Deployment instructions
```

## 🔧 Tech Stack

| Technology | Purpose | Version |
|------------|---------|---------|
| **Backend** |
| [Ruby on Rails](https://rubyonrails.org/) | Web framework, MVC architecture | 7.1.3 |
| [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) | WebSocket connections | Built-in |
| [Devise](https://github.com/heartcombo/devise) | Authentication framework | Latest |
| [SQLite](https://sqlite.org/) | Database (development) | 1.4+ |
| **Frontend** |
| [ERB Templates](https://ruby-doc.org/stdlib-3.0.0/libdoc/erb/rdoc/ERB.html) | Server-rendered views | Built-in |
| [Stimulus](https://stimulus.hotwired.dev/) | JavaScript framework | Built-in |
| [CSS3](https://www.w3.org/Style/CSS/) | Modern responsive styling | Built-in |
| [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html) | Asset compilation | Built-in |
| **Optional** |
| [Redis](https://redis.io/) | ActionCable adapter (production) | 4.0+ |
| [AnyCable](https://anycable.io/) | Scalable WebSocket connections | 1.5+ |

## 🧪 Testing

### Running Tests

The project includes comprehensive test coverage with both integration and unit tests.

**Test User Accounts:**
- **user@example.com** / password123 (Test User 1 - Owner role)  
- **user2@example.com** / password123 (Test User 2 - Admin role)

**Available Test Commands:**
```bash
# Run all tests
bundle exec rails test

# Run specific test types
bundle exec rails test test/integration/           # Integration tests
bundle exec rails test test/controllers/          # Controller tests
bundle exec rails test test/models/               # Model tests
bundle exec rails test test/services/             # Service tests

# Run specific test file
bundle exec rails test test/integration/login_test.rb

# Run tests with verbose output
bundle exec rails test -v
```

**Login Test Coverage:**
The `test/integration/login_test.rb` file includes comprehensive login functionality tests:
- ✅ Successful login with valid credentials
- ✅ Failed login with invalid email/password
- ✅ Redirect behavior for authenticated users
- ✅ Login form validation and accessibility
- ✅ Logout functionality
- ✅ Page content and branding verification

### Test Environment Setup
```bash
# Prepare test database (automatic, but can be run manually)
RAILS_ENV=test bin/rails db:create db:migrate

# Load test fixtures (automatic during test runs)
RAILS_ENV=test bin/rails db:fixtures:load
```

## 🔍 Troubleshooting

### Common Issues

**Server Won't Start**
```bash
# Check Ruby version
ruby --version  # Should be 3.3.0+

# Install dependencies
bundle install

# Check database
bin/rails db:migrate
```

**Port Already in Use**
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different port
bin/rails server -p 3001
```

**Asset Issues**
```bash
# Precompile assets manually
bin/rails assets:precompile

# Clear asset cache
bin/rails assets:clobber
bin/rails assets:precompile
```

**ActionCable Not Working**
```bash
# Check cable.yml configuration
# For development, use 'async' adapter
# For production, use 'redis' or 'any_cable'
```

**Authentication Issues**
```bash
# Generate new Devise secret key
bin/rails credentials:edit

# Reset database and reseed
bin/rails db:drop db:create db:migrate db:seed
```

**Missing Dependencies**
```bash
# Reinstall Ruby dependencies
bundle install

# Check for missing gems
bundle check
```

## 🛠️ Configuration

### Database Configuration
- **Development**: SQLite (file-based)
- **Test**: SQLite (in-memory)
- **Production**: Configurable (PostgreSQL recommended)

### ActionCable Configuration
```yaml
# config/cable.yml
development:
  adapter: async  # For development

production:
  adapter: redis  # For production
  url: redis://localhost:6379/1
```

### Authentication
- Uses Devise for user authentication
- JWT tokens for API authentication
- Session-based authentication for web interface
- Password recovery and user registration

## 🚢 Production Deployment

### Environment Setup
```bash
# Required environment variables
RAILS_ENV=production
RAILS_MASTER_KEY=your-master-key
DATABASE_URL=postgresql://user:pass@host:5432/dbname
REDIS_URL=redis://your-redis-server:6379/1  # If using Redis
```

### Build Commands
```bash
# Precompile assets
RAILS_ENV=production bin/rails assets:precompile

# Run database migrations
RAILS_ENV=production bin/rails db:migrate

# Start production server
RAILS_ENV=production bundle exec rails server
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review the `ARCHITECTURE.md` for technical details
- See `DEVELOPMENT.md` for development guidance

## 🔗 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical architecture details
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development setup and workflow
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment guide
- [CLAUDE.md](CLAUDE.md) - Claude Code specific instructions

### External Resources
- [Rails Guides](https://guides.rubyonrails.org/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
- [ActionCable Documentation](https://guides.rubyonrails.org/action_cable_overview.html)
- [Devise Documentation](https://github.com/heartcombo/devise)

---

**Built with ❤️ as a Rails monolith for VoIP call centers**