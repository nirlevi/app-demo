# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a VoipAppz mini app template built as a Ruby on Rails monolith. It's structured as a traditional Rails application with server-rendered ERB views, Stimulus for JavaScript interactions, and ActionCable for real-time features. Includes JWT authentication, organization management, and a responsive dashboard interface.

## Development Commands

### Primary Development
- `docker-compose up -d postgres` - Start PostgreSQL database (required first)
- `bundle exec rails server` - Start Rails development server
- `bin/rails assets:precompile` - Build and precompile Rails assets
- `bundle install` - Install Ruby dependencies
- `bin/rails db:create db:migrate db:seed` - Set up the Rails app (database, migrations, seeds)

### AnyCable WebSocket Development
- `anycable` - Start AnyCable RPC server (in separate terminal)
- `anycable-go --port=8080` - Start AnyCable WebSocket server (optional, for production-like setup)

### Rails-specific Commands
- `bundle exec rails server` - Start Rails server
- `bin/rails console` - Open Rails console
- `bundle exec rails test` - Run test suite
- `bundle exec rubocop` - Run linting

### Database
- `docker-compose up -d postgres` - Start PostgreSQL container
- `docker-compose down` - Stop all containers
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Seed database

## Architecture

### Rails Monolith
- **Framework**: Ruby on Rails 7.1.3
- **Database**: PostgreSQL 15 (development), configurable for production
- **Authentication**: Devise with JWT tokens
- **Views**: Server-rendered ERB templates with responsive CSS
- **JavaScript**: Stimulus controllers for interactivity
- **Real-time**: ActionCable with AnyCable for WebSocket connections
- **Styling**: Custom CSS with modern flexbox/grid layouts

### Frontend Architecture
- **Views**: ERB templates in `app/views/`
- **Styling**: CSS in `app/assets/stylesheets/`
- **JavaScript**: Stimulus controllers in `app/javascript/controllers/`
- **Real-time**: ActionCable channels for live dashboard updates

### Key Files & Directories
- `config/routes.rb` - Application routes (dashboard, auth, API)
- `app/controllers/authenticated_controller.rb` - Base controller for authenticated requests
- `app/controllers/dashboard_controller.rb` - Main dashboard pages
- `app/services/` - Business logic services (ItemCreator, ItemCounter)
- `app/models/user.rb` - User model with Devise authentication
- `app/models/organization.rb` - Organization model
- `app/models/item.rb` - Item/Call model
- `app/channels/dashboard_live_channel.rb` - Real-time dashboard updates

### Page Structure
- `/` - Redirects to dashboard (if authenticated) or login
- `/login` - Authentication page
- `/dashboard` - Live dashboard with real-time stats
- `/calls` - Call management with filtering and search
- `/reports` - Analytics and reporting with date ranges
- `/api/*` - JSON API endpoints for AJAX requests

### Real-time Features
The app uses ActionCable for real-time functionality:
- Live dashboard updates via WebSocket connections
- Real-time call status changes
- Agent activity monitoring
- Live statistics updates

## Environment Configuration

Required environment variables:
- `RAILS_ENV` - Rails environment (development/test/production)
- `RAILS_MASTER_KEY` - Rails master key for encrypted credentials
- `DATABASE_USER` - PostgreSQL username (default: postgres)
- `DATABASE_PASSWORD` - PostgreSQL password (default: mysecretpassword)
- `DATABASE_HOST` - PostgreSQL host (default: localhost)
- `DATABASE_PORT` - PostgreSQL port (default: 5433)
- `DATABASE_URL` - Database connection string (production)
- `REDIS_URL` - Redis connection for ActionCable (production)

Optional environment variables:
- `PORT` - Server port (defaults to 3000)

For convenience, copy the `.env` file in the web directory with the default development settings.

## Testing

- **Framework**: Minitest (Rails default)
- **System Testing**: Capybara + Selenium WebDriver
- **Mocking**: WebMock for HTTP requests, Mocha for method stubbing
- **Test Files**: Located in `test/`

## Code Style

- **Ruby**: Uses RuboCop with Shopify style guide (`rubocop-shopify` gem)
- **Configuration**: `rubocop.yml`
- **Exclusions**: Database files, bin scripts, test temp files, vendor bundles

## Session Management

The app uses Devise for session management:
- **User Authentication**: Devise-based user sessions with persistent login
- **Session Storage**: Server-side session storage with secure cookies
- **JWT Support**: API authentication via JWT tokens for headless clients
- **Organization Context**: Multi-tenant support via organization association

## Common Patterns

### Controller Architecture
- Inherit from `AuthenticatedController` for protected pages
- Use `before_action :authenticate_user!` for Devise authentication
- Access current user via `current_user` helper
- Access user's organization via `current_user.organization`
- Respond with HTML for web pages, JSON for API endpoints

### Service Objects
- Inherit from `ApplicationService`
- Use `call` method as the primary interface
- Handle business logic separate from controllers
- Return consistent success/error responses

### ERB Templates
- Use semantic HTML with proper accessibility attributes
- Include `data-controller` attributes for Stimulus integration
- Use Rails helpers for forms (`form_with`) and links (`link_to`)
- Implement responsive design with CSS Grid and Flexbox

### Stimulus Controllers
- Keep JavaScript minimal and progressive
- Use data attributes for configuration
- Handle form submissions and dynamic content updates
- Connect to ActionCable channels for real-time features

### ActionCable Integration
- Subscribe to organization-specific channels
- Broadcast updates when data changes (create/update/delete)
- Handle WebSocket connection errors gracefully
- Use `current_user` for authentication in channels