# Development Guide

This guide provides comprehensive instructions for setting up, developing, and contributing to the VoipAppz Rails monolith application.

## 🚀 Quick Setup

### Prerequisites
- **Ruby**: 3.3.0 or higher
- **Bundler**: Latest version (`gem install bundler`)
- **Node.js**: 18+ (for asset compilation)
- **Git**: Version control
- **Redis**: Optional, for production-like ActionCable testing

### One-Command Setup
```bash
git clone <repository-url>
cd shopify-app-template-ruby
npm install && npm run db:setup && npm run dev
```

Your application will be running at http://localhost:3000

## 📋 Detailed Setup

### 1. Environment Setup

**Install Ruby (using rbenv recommended)**
```bash
# Install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Install Ruby 3.3.0
rbenv install 3.3.0
rbenv global 3.3.0

# Verify installation
ruby --version  # Should show Ruby 3.3.0
```

**Install Bundler**
```bash
gem install bundler
bundler --version
```

### 2. Project Setup

**Clone and Install Dependencies**
```bash
git clone <repository-url>
cd shopify-app-template-ruby

# Install Ruby gems
cd web && bundle install

# Return to project root
cd ..
```

### 3. Database Setup

**Create and Migrate Database**
```bash
npm run db:setup
# This runs: db:create, db:migrate, db:seed
```

**Manual Database Operations**
```bash
# Individual steps
cd web
bin/rails db:create    # Create database files
bin/rails db:migrate   # Run all migrations
bin/rails db:seed      # Create sample data
```

### 4. Asset Compilation

**Precompile Assets**
```bash
npm run build
# Or manually: cd web && bin/rails assets:precompile
```

### 5. Start Development Server

**Quick Start**
```bash
npm run dev
```

**Manual Start**
```bash
cd web && bundle exec rails server
```

## 🛠️ Development Workflow

### Daily Development

**Start Working**
```bash
git pull origin main        # Get latest changes
npm run dev                # Start development server
```

**Make Changes**
1. Edit code in your preferred editor
2. Changes auto-reload in development
3. Check browser at http://localhost:3000

**Test Changes**
```bash
npm run test               # Run test suite
npm run lint               # Check code style
```

**Commit Changes**
```bash
git add .
git commit -m "Description of changes"
git push origin feature-branch
```

### Database Development

**Create New Migration**
```bash
cd web
bin/rails generate migration CreateNewTable field1:string field2:integer
bin/rails db:migrate
```

**Reset Database (if needed)**
```bash
npm run db:setup          # Drops, creates, migrates, seeds
```

**Database Console**
```bash
cd web
bin/rails db            # SQLite console
bin/rails console       # Rails console with models
```

### Asset Development

**CSS Changes**
- Edit `web/app/assets/stylesheets/application.css`
- Changes are automatically recompiled in development

**JavaScript Changes**
- Edit Stimulus controllers in `web/app/javascript/controllers/`
- New controllers auto-register via `index.js`

**Force Asset Recompilation**
```bash
cd web
bin/rails assets:clobber
bin/rails assets:precompile
```

## 🧪 Testing

### Running Tests

**Full Test Suite**
```bash
npm run test
# Or: cd web && bundle exec rails test
```

**Specific Test Files**
```bash
cd web
bundle exec rails test test/models/user_test.rb
bundle exec rails test test/controllers/dashboard_controller_test.rb
```

**System Tests (Browser tests)**
```bash
cd web
bundle exec rails test:system
```

### Writing Tests

**Model Tests**
```ruby
# test/models/user_test.rb
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = users(:one)  # From fixtures
    assert user.valid?
  end

  test "should belong to organization" do
    user = users(:one)
    assert_respond_to user, :organization
  end
end
```

**Controller Tests**
```ruby
# test/controllers/dashboard_controller_test.rb
require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user  # Devise test helper
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
  end
end
```

**System Tests**
```ruby
# test/system/dashboard_test.rb
require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  test "visiting dashboard shows live stats" do
    user = users(:one)
    login_as user  # Custom helper

    visit dashboard_url
    assert_selector "h1", text: "Live Dashboard"
    assert_selector ".stat-card"
  end
end
```

### Test Data (Fixtures)

**Creating Fixtures**
```yaml
# test/fixtures/users.yml
one:
  email: user@example.com
  first_name: John
  last_name: Doe
  organization: one

two:
  email: admin@example.com  
  first_name: Jane
  last_name: Admin
  organization: one
```

## 🎨 Code Style

### Ruby Style (RuboCop)

**Check Code Style**
```bash
npm run lint
# Or: cd web && bundle exec rubocop
```

**Auto-fix Issues**
```bash
cd web && bundle exec rubocop -A
```

**Configuration**
- Rules defined in `web/.rubocop.yml`
- Based on standard Ruby style guide
- Excludes generated files and vendor code

### Rails Conventions

**Controller Naming**
```ruby
# Good
class DashboardController < AuthenticatedController
class CallsController < AuthenticatedController

# Bad
class DashBoardController < ApplicationController
```

**Model Naming**
```ruby
# Good
class User < ApplicationRecord
class Organization < ApplicationRecord

# Bad  
class Users < ApplicationRecord
```

**Route Naming**
```ruby
# config/routes.rb
# Good - RESTful routes
resources :calls
resources :reports, only: [:index]

# Bad - non-standard routes
get '/call_list'
```

### ERB Template Style

**Good Practices**
```erb
<!-- Use Rails helpers -->
<%= link_to "Dashboard", dashboard_path, class: "nav-link" %>

<!-- Proper indentation -->
<div class="container">
  <%= render 'shared/sidebar' %>
  <main class="content">
    <%= yield %>
  </main>
</div>

<!-- Use semantic HTML -->
<nav class="sidebar">
  <ul>
    <li><%= link_to "Home", root_path %></li>
  </ul>
</nav>
```

### CSS Style

**Organization**
```css
/* Global styles first */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

/* Layout components */
.app-container { /* ... */ }
.sidebar { /* ... */ }

/* Specific components */
.dashboard-stats { /* ... */ }
.call-table { /* ... */ }

/* Responsive styles last */
@media (max-width: 768px) {
  /* Mobile styles */
}
```

## 🔧 Common Development Tasks

### Adding a New Page

**1. Create Controller**
```bash
cd web
bin/rails generate controller NewPage index
```

**2. Add Route**
```ruby
# config/routes.rb
get 'new_page', to: 'new_page#index'
```

**3. Create View**
```erb
<!-- app/views/new_page/index.html.erb -->
<% content_for :page_title, "New Page" %>

<div class="new-page">
  <h1>New Page Content</h1>
</div>
```

**4. Add Navigation Link**
```erb
<!-- app/views/shared/_sidebar.html.erb -->
<li class="<%= 'active' if controller_name == 'new_page' %>">
  <%= link_to new_page_path do %>
    <span class="icon">📄</span>
    New Page
  <% end %>
</li>
```

### Adding a New Model

**1. Generate Model**
```bash
cd web
bin/rails generate model Product name:string price:decimal organization:references
bin/rails db:migrate
```

**2. Add Associations**
```ruby
# app/models/product.rb
class Product < ApplicationRecord
  belongs_to :organization
  
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(active: true) }
end

# app/models/organization.rb
class Organization < ApplicationRecord
  has_many :products, dependent: :destroy
end
```

**3. Create Controller**
```bash
bin/rails generate controller Products index show new create edit update destroy
```

### Adding Real-time Features

**1. Create ActionCable Channel**
```bash
cd web
bin/rails generate channel Product
```

**2. Configure Channel**
```ruby
# app/channels/product_channel.rb
class ProductChannel < ApplicationCable::Channel
  def subscribed
    stream_from "product_#{current_user.organization.id}"
  end
end
```

**3. Broadcast Updates**
```ruby
# app/models/product.rb
after_create_commit :broadcast_creation

private

def broadcast_creation
  ActionCable.server.broadcast(
    "product_#{organization.id}",
    { action: 'created', product: self }
  )
end
```

**4. Create Stimulus Controller**
```javascript
// app/javascript/controllers/products_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  connect() {
    this.subscription = createConsumer().subscriptions.create("ProductChannel", {
      received: (data) => {
        if (data.action === 'created') {
          this.addProduct(data.product)
        }
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  addProduct(product) {
    // Add product to DOM
  }
}
```

### Debugging

**Rails Console**
```bash
cd web
bin/rails console

# In console:
User.count
Organization.first.users
User.joins(:organization).where(organizations: { name: 'Test Org' })
```

**View Debugging**
```erb
<!-- In any view -->
<%= debug params %>
<%= debug current_user %>
```

**Log Debugging**
```ruby
# In any controller/model
Rails.logger.info "Debug info: #{variable.inspect}"
logger.debug "Current user: #{current_user.id}"
```

**Database Queries**
```bash
# Check what SQL is being generated
cd web
bin/rails console
> ActiveRecord::Base.logger = Logger.new(STDOUT)
> User.joins(:organization).load  # Will show SQL
```

## 🚨 Troubleshooting

### Common Issues

**Server Won't Start**
```bash
# Check for port conflicts
lsof -ti:3000 | xargs kill -9

# Check Ruby version
ruby --version

# Reinstall gems
cd web && bundle install
```

**Database Issues**
```bash
# Reset database
cd web
bin/rails db:drop db:create db:migrate db:seed

# Check database file permissions
ls -la db/
```

**Asset Issues**
```bash
# Clear and recompile assets
cd web
bin/rails assets:clobber
bin/rails assets:precompile

# Check asset paths in browser dev tools
```

**Missing Routes**
```bash
# Check all routes
cd web
bin/rails routes

# Check specific route
bin/rails routes | grep dashboard
```

**ActionCable Not Working**
```bash
# Check cable.yml configuration
cat config/cable.yml

# For development, ensure using 'async' adapter
# Check browser console for WebSocket errors
```

### Performance Issues

**Slow Database Queries**
```bash
# Enable query logging
cd web
bin/rails console
> ActiveRecord::Base.logger.level = 0

# Check for N+1 queries, add includes:
User.includes(:organization).all
```

**Slow Asset Loading**
```bash
# In development, disable asset debugging
# config/environments/development.rb
config.assets.debug = false
```

**Memory Issues**
```bash
# Check memory usage
ps aux | grep rails

# Restart server if needed
pkill -f rails
npm run dev
```

## 📚 Learning Resources

### Rails-Specific
- [Rails Guides](https://guides.rubyonrails.org/) - Official documentation
- [Rails API Documentation](https://api.rubyonrails.org/) - API reference
- [Rails Tutorial](https://www.railstutorial.org/) - Comprehensive tutorial

### Testing
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)

### Frontend
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
- [ActionCable Guide](https://guides.rubyonrails.org/action_cable_overview.html)

### Ruby Language
- [Ruby Documentation](https://ruby-doc.org/)
- [Ruby Style Guide](https://rubystyle.guide/)

This development guide should help you get up and running quickly while following best practices for Rails development.