# Architecture Documentation

This document provides a detailed technical overview of the VoipAppz Rails monolith architecture, design decisions, and implementation patterns.

## 🏗️ System Overview

The VoipAppz application is built as a traditional Ruby on Rails monolith following the Model-View-Controller (MVC) pattern with modern enhancements for real-time functionality and progressive JavaScript.

### Core Principles
- **Server-Side Rendering**: HTML generated on the server for fast initial page loads
- **Progressive Enhancement**: JavaScript adds functionality without breaking basic features
- **Real-time Updates**: WebSocket connections for live dashboard updates
- **Responsive Design**: Mobile-first CSS with modern layout techniques
- **Security First**: Authentication and authorization at every layer

## 📐 Architecture Layers

### 1. Presentation Layer (Views)
```
app/views/
├── layouts/
│   └── application.html.erb       # Main application layout
├── shared/
│   ├── _sidebar.html.erb          # Navigation sidebar
│   └── _topbar.html.erb           # Top navigation bar
├── auth/
│   └── login.html.erb             # Authentication pages
├── dashboard/
│   └── index.html.erb             # Live dashboard
├── calls/
│   └── index.html.erb             # Call management
└── reports/
    └── index.html.erb             # Analytics and reports
```

**Technologies:**
- **ERB Templates**: Server-rendered HTML with embedded Ruby
- **CSS3**: Modern responsive styling with Grid and Flexbox
- **Semantic HTML**: Accessible markup with proper ARIA attributes

### 2. Controller Layer (Business Logic)
```
app/controllers/
├── application_controller.rb      # Base controller with common functionality
├── authenticated_controller.rb    # Authentication base for protected routes
├── auth_controller.rb             # Authentication pages (login/logout)
├── dashboard_controller.rb        # Live dashboard functionality
├── calls_controller.rb            # Call management and history
├── reports_controller.rb          # Analytics and reporting
└── api/                           # JSON API endpoints
    ├── application_controller.rb  # API base controller
    ├── auth/                      # API authentication
    ├── items_controller.rb        # Item/Call API
    ├── organizations_controller.rb # Organization API
    └── users_controller.rb        # User management API
```

**Key Patterns:**
- Inheritance hierarchy for shared functionality
- Authentication before_actions for security
- Consistent error handling and response formats
- Separation of web and API concerns

### 3. Model Layer (Data)
```
app/models/
├── application_record.rb          # Base ActiveRecord model
├── user.rb                        # User authentication with Devise
├── organization.rb                # Multi-tenant organization
└── item.rb                        # Items/Calls (flexible data model)
```

**Data Relationships:**
```ruby
User belongs_to Organization
User has_many Items (as created_by)
Organization has_many Users
Organization has_many Items
```

**Key Features:**
- Devise authentication with JWT support
- Multi-tenancy via organization scoping
- Rich scopes for querying (active, recent, today, etc.)
- Validation and data integrity constraints

### 4. Real-time Layer (ActionCable)
```
app/channels/
├── application_cable/
│   ├── channel.rb                 # Base channel
│   └── connection.rb              # WebSocket connection
└── dashboard_live_channel.rb      # Live dashboard updates
```

**WebSocket Flow:**
1. Client connects to `/cable` endpoint
2. Subscribes to organization-specific channel
3. Server broadcasts updates when data changes
4. Client receives updates and updates UI

### 5. JavaScript Layer (Stimulus)
```
app/javascript/controllers/
├── application.js                 # Stimulus application
├── index.js                       # Controller registration
├── clock_controller.js            # Real-time clock display
├── live_updates_controller.js     # WebSocket connection management
└── filters_controller.js          # Form filtering and search
```

**Stimulus Philosophy:**
- Minimal JavaScript for maximum impact
- Progressive enhancement of server-rendered HTML
- Data attributes for configuration
- Event-driven interactions

## 🔄 Request Flow

### Web Request Flow
1. **HTTP Request** → Rails Router
2. **Authentication Check** → Devise middleware
3. **Controller Action** → Business logic execution
4. **Model Interaction** → Database queries
5. **View Rendering** → ERB template compilation
6. **HTML Response** → Styled content delivery

### API Request Flow
1. **HTTP Request** → Rails Router (`/api/*`)
2. **Authentication Check** → JWT token validation
3. **API Controller** → JSON-focused logic
4. **Model Interaction** → Database operations
5. **JSON Response** → Structured data delivery

### WebSocket Flow
1. **WebSocket Connection** → ActionCable server
2. **Channel Subscription** → Organization-specific channel
3. **Data Change Event** → Model callbacks
4. **Broadcast Update** → All subscribers notified
5. **Client Update** → JavaScript updates DOM

## 🛠️ Technology Stack Deep Dive

### Backend Technologies

#### Ruby on Rails 7.1.3
- **MVC Architecture**: Clear separation of concerns
- **Convention over Configuration**: Standardized project structure
- **Active Record**: Object-relational mapping with rich associations
- **Asset Pipeline**: Automatic compilation and optimization
- **Built-in Security**: CSRF protection, SQL injection prevention

#### Authentication & Authorization
- **Devise**: Full-featured authentication solution
- **JWT Integration**: Token-based API authentication
- **Session Management**: Secure server-side sessions
- **Password Security**: BCrypt hashing with salts

#### Database Layer
- **Development**: SQLite for simplicity and portability
- **Production**: PostgreSQL recommended for scalability
- **Migrations**: Version-controlled database schema changes
- **ActiveRecord**: Rich querying with scopes and associations

#### Real-time Features
- **ActionCable**: WebSocket integration built into Rails
- **Channel-based Architecture**: Organize real-time features
- **Async Adapter**: Development WebSocket handling
- **Redis Adapter**: Production-ready message broadcasting

### Frontend Technologies

#### Server-Side Rendering
- **ERB Templates**: Ruby embedded in HTML
- **Layouts and Partials**: Reusable template components
- **Rails Helpers**: URL generation, form helpers, asset helpers
- **Internationalization**: Built-in i18n support

#### Styling and Design
- **CSS3**: Modern styling with custom properties
- **Flexbox & Grid**: Responsive layout systems
- **Mobile-First**: Progressive responsive design
- **Semantic HTML**: Accessibility and SEO friendly

#### Progressive JavaScript
- **Stimulus Framework**: Lightweight JavaScript framework
- **Importmap**: ES6 module management without bundling
- **Progressive Enhancement**: Works without JavaScript
- **Event-Driven**: DOM-based interactions

## 📊 Data Architecture

### Database Schema
```sql
-- Users table (Devise managed)
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  email VARCHAR NOT NULL,
  first_name VARCHAR,
  last_name VARCHAR,
  organization_id BIGINT REFERENCES organizations(id),
  active BOOLEAN DEFAULT true,
  -- Devise fields (encrypted_password, etc.)
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Organizations table (Multi-tenancy)
CREATE TABLE organizations (
  id BIGINT PRIMARY KEY,
  name VARCHAR NOT NULL,
  settings JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Items table (Flexible data model)
CREATE TABLE items (
  id BIGINT PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  category VARCHAR,
  status VARCHAR DEFAULT 'active',
  organization_id BIGINT REFERENCES organizations(id),
  created_by_id BIGINT REFERENCES users(id),
  metadata JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### Data Access Patterns
- **Organization Scoping**: All queries filtered by current user's organization
- **Efficient Indexing**: Database indexes on commonly queried fields
- **Eager Loading**: Includes associations to prevent N+1 queries
- **Scoped Queries**: Rich ActiveRecord scopes for common filters

## 🔒 Security Architecture

### Authentication Flow
1. User submits credentials to `/users/sign_in`
2. Devise validates against encrypted password
3. Session created with secure, HTTP-only cookie
4. Subsequent requests authenticated via session
5. API requests use JWT tokens in Authorization header

### Authorization Patterns
- **Controller-level**: `before_action :authenticate_user!`
- **Organization Scoping**: Automatic filtering by user's organization
- **Route Protection**: Authenticated routes separate from public routes
- **CSRF Protection**: Built-in Rails CSRF tokens for forms

### Security Features
- **SQL Injection Protection**: ActiveRecord parameterized queries
- **XSS Prevention**: Automatic HTML escaping in templates
- **CSRF Protection**: Anti-forgery tokens in forms
- **Secure Headers**: Content Security Policy, XSS protection
- **Password Security**: BCrypt with work factor 12

## 🚀 Performance Considerations

### Server-Side Optimizations
- **Database Indexing**: Strategic indexes on frequently queried columns
- **Eager Loading**: Prevent N+1 queries with `includes`
- **Caching**: Fragment caching for expensive view renders
- **Asset Compilation**: Minification and compression in production

### Client-Side Optimizations
- **Progressive Loading**: Critical CSS inlined, non-critical deferred
- **Image Optimization**: Responsive images with proper sizing
- **JavaScript Minimization**: Only load required Stimulus controllers
- **HTTP/2 Push**: Asset preloading for faster page loads

### Real-time Performance
- **Selective Broadcasting**: Only send updates to relevant users
- **Connection Pooling**: Efficient WebSocket connection management
- **Channel Isolation**: Separate channels for different features
- **Message Optimization**: Minimal payload size for WebSocket messages

## 📈 Scalability Architecture

### Horizontal Scaling Options
- **Load Balancers**: Multiple Rails server instances
- **Database Read Replicas**: Separate read and write databases
- **Redis Clustering**: Distributed ActionCable message broadcasting
- **CDN Integration**: Static asset delivery optimization

### Vertical Scaling Optimizations
- **Connection Pooling**: Database connection management
- **Background Jobs**: Asynchronous processing with Sidekiq
- **Caching Layers**: Redis for session storage and caching
- **Asset Optimization**: Compression and minification

## 🔧 Development Patterns

### Code Organization
- **Service Objects**: Business logic extraction from controllers
- **Concerns**: Shared functionality modules
- **Decorators/Helpers**: View logic separation
- **Form Objects**: Complex form handling

### Testing Strategy
- **Unit Tests**: Model and service testing with Minitest
- **Integration Tests**: Controller and route testing
- **System Tests**: End-to-end browser testing with Capybara
- **WebSocket Testing**: ActionCable channel testing

### Development Workflow
- **Hot Reloading**: Automatic code reload in development
- **Asset Compilation**: Live asset recompilation
- **Database Seeds**: Consistent development data
- **Environment Configuration**: Environment-specific settings

## 🎯 Design Decisions

### Why Rails Monolith?
- **Simplicity**: Single deployment, easier debugging
- **Developer Productivity**: Convention over configuration
- **Feature Completeness**: Full-stack solution in one framework
- **Team Efficiency**: Single technology stack to maintain

### Why Server-Side Rendering?
- **SEO Benefits**: Search engine friendly HTML
- **Performance**: Fast initial page loads
- **Accessibility**: Works without JavaScript
- **Development Speed**: Faster feature development

### Why Stimulus over React?
- **Progressive Enhancement**: Works with server-rendered HTML
- **Smaller Bundle Size**: Minimal JavaScript payload
- **Rails Integration**: Designed specifically for Rails applications
- **Learning Curve**: Easier for Rails developers to adopt

### Why ActionCable over External WebSocket Service?
- **Integration**: Built into Rails framework
- **Development Simplicity**: No external service dependencies
- **Authentication**: Leverages existing user sessions
- **Deployment**: Single application deployment

## 📋 Maintenance and Monitoring

### Health Checks
- **Application Health**: `/api/health` endpoint
- **Database Connectivity**: ActiveRecord connection checks
- **WebSocket Status**: ActionCable connection monitoring
- **Asset Delivery**: Static file serving verification

### Logging Strategy
- **Request Logging**: All HTTP requests logged with timing
- **Error Logging**: Exception tracking with stack traces
- **WebSocket Logging**: Connection and message logging
- **Performance Logging**: Database query timing

### Monitoring Points
- **Response Times**: Controller action performance
- **Database Performance**: Query execution times
- **WebSocket Connections**: Active connection counts
- **Error Rates**: Application exception frequency

This architecture provides a solid foundation for a modern Rails application with real-time features while maintaining simplicity and developer productivity.