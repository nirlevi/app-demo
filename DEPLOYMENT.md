# Deployment Guide

This guide covers deploying the VoipAppz Rails monolith to production environments, including configuration, optimization, and monitoring.

## 🚀 Quick Production Deploy

### Heroku (Recommended for Quick Start)
```bash
# Install Heroku CLI
brew install heroku/brew/heroku  # macOS
# or download from https://devcenter.heroku.com/articles/heroku-cli

# Create Heroku app
heroku create your-app-name

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Add Redis for ActionCable
heroku addons:create heroku-redis:hobby-dev

# Deploy
git push heroku main

# Setup database
heroku run rails db:migrate db:seed

# Open app
heroku open
```

## 🏗️ Production Infrastructure

### Minimum Production Requirements
- **Server**: 1GB RAM, 1 CPU core, 10GB storage
- **Database**: PostgreSQL 12+
- **Cache**: Redis 6+ (for ActionCable)
- **Ruby**: 3.3.0+
- **Web Server**: Puma (included)
- **Reverse Proxy**: Nginx (recommended)

### Recommended Production Setup
- **Application Servers**: 2+ instances behind load balancer  
- **Database**: PostgreSQL with read replicas
- **Cache**: Redis cluster for high availability
- **CDN**: CloudFlare or AWS CloudFront for assets
- **SSL**: Let's Encrypt or commercial certificate

## 📋 Pre-Deployment Checklist

### Environment Configuration
- [ ] `RAILS_ENV=production`
- [ ] `RAILS_MASTER_KEY` set (from `config/master.key`)
- [ ] `DATABASE_URL` configured
- [ ] `REDIS_URL` configured (if using Redis for ActionCable)
- [ ] Domain and SSL certificate ready

### Security Configuration  
- [ ] Strong passwords for all services
- [ ] Database access restricted to application servers
- [ ] Redis access secured with password/firewall
- [ ] SSL/TLS certificates installed
- [ ] Security headers configured

### Performance Configuration
- [ ] Assets precompiled
- [ ] Database indexes created
- [ ] CDN configured for static assets
- [ ] Gzip compression enabled
- [ ] Caching strategy implemented

## 🔧 Platform-Specific Deployments

### Heroku Deployment

**1. Prepare Application**
```bash
# Add PostgreSQL gem to production
echo 'gem "pg", "~> 1.1"' >> web/Gemfile
cd web && bundle install

# Create Procfile
echo 'web: cd web && bundle exec puma -C config/puma.rb' > Procfile

# Configure ActionCable for Redis
# config/cable.yml - production section should use Redis
```

**2. Configure Heroku**
```bash
# Create app
heroku create your-voipappz-app

# Add addons
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create heroku-redis:hobby-dev

# Set environment variables
heroku config:set RAILS_ENV=production
heroku config:set RAILS_SERVE_STATIC_FILES=true
heroku config:set RAILS_LOG_TO_STDOUT=true

# Deploy
git add -A
git commit -m "Prepare for Heroku deployment"
git push heroku main

# Setup database
heroku run cd web && rails db:migrate db:seed
```

**3. Configure Domain (Optional)**
```bash
heroku domains:add yourdomain.com
heroku certs:auto:enable
```

### DigitalOcean App Platform

**1. Create App Spec**
```yaml
# .do/app.yaml
name: voipappz
services:
- name: web
  source_dir: /
  github:
    repo: your-github-username/your-repo
    branch: main
  run_command: cd web && bundle exec puma -C config/puma.rb
  environment_slug: ruby
  instance_count: 1
  instance_size_slug: basic-xxs
  http_port: 3000
  routes:
  - path: /
  envs:
  - key: RAILS_ENV
    value: production
  - key: RAILS_SERVE_STATIC_FILES  
    value: "true"
  - key: RAILS_MASTER_KEY
    value: your-master-key-here
databases:
- engine: PG
  name: voipappz-db
  num_nodes: 1
  size: db-s-dev-database
  version: "12"
```

**2. Deploy**
```bash
# Install doctl CLI
brew install doctl  # macOS

# Create app
doctl apps create .do/app.yaml

# Monitor deployment
doctl apps list
```

### AWS Elastic Beanstalk

**1. Prepare Application**
```ruby
# web/Gemfile - Add platform-specific gems
group :production do
  gem 'pg', '~> 1.1'
  gem 'aws-sdk-s3', require: false  # For Active Storage
end
```

**2. Configure Elastic Beanstalk**
```bash
# Install EB CLI
pip install awsebcli

# Initialize EB application
eb init -p ruby-3.3 voipappz-production

# Create environment
eb create production-env

# Deploy
eb deploy
```

**3. Configure Environment Variables**
```bash
eb setenv RAILS_ENV=production
eb setenv RAILS_MASTER_KEY=your-master-key
eb setenv DATABASE_URL=postgresql://...
eb setenv REDIS_URL=redis://...
```

### Docker Deployment

**1. Create Dockerfile**
```dockerfile
# Dockerfile
FROM ruby:3.3.0-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    nodejs \
    npm \
    tzdata

WORKDIR /app

# Install gems
COPY web/Gemfile web/Gemfile.lock ./
RUN bundle config --global frozen 1 && \
    bundle install --without development test

# Copy application
COPY web/ ./

# Precompile assets
RUN RAILS_ENV=production bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

**2. Build and Deploy**
```bash
# Build image
docker build -t voipappz-app .

# Run locally for testing
docker run -p 3000:3000 \
  -e RAILS_ENV=production \
  -e RAILS_MASTER_KEY=your-key \
  -e DATABASE_URL=postgresql://... \
  voipappz-app

# Deploy to container registry
docker tag voipappz-app your-registry/voipappz-app
docker push your-registry/voipappz-app
```

## ⚙️ Production Configuration

### Database Configuration

**PostgreSQL Setup**
```yaml
# config/database.yml
production:
  <<: *default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV['DATABASE_URL'] %>
  # For better performance
  prepared_statements: true
  advisory_locks: true
```

**Database Optimization**
```sql
-- Create indexes for better performance
CREATE INDEX idx_items_organization_id ON items(organization_id);
CREATE INDEX idx_items_status ON items(status);
CREATE INDEX idx_items_created_at ON items(created_at);
CREATE INDEX idx_users_organization_id ON users(organization_id);
```

### ActionCable Configuration

**Redis Configuration**
```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
  channel_prefix: voipappz_production
```

**AnyCable Configuration (Advanced)**
```yaml
# config/anycable.yml
production:
  rpc_host: "0.0.0.0:50051"
  redis_url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/1") %>
  log_level: info
  debug: false
```

### Asset Configuration

**Asset Compilation**
```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true
config.public_file_server.enabled = true
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000'
}
```

**CDN Configuration**
```ruby
# config/environments/production.rb
# For CloudFront or similar CDN
config.asset_host = 'https://cdn.yourdomain.com'
```

### Security Configuration

**SSL and Security Headers**
```ruby
# config/environments/production.rb
config.force_ssl = true
config.ssl_options = { hsts: { subdomains: true } }

# Security headers
config.force_ssl = true
config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data
  policy.img_src     :self, :data
  policy.object_src  :none
  policy.script_src  :self
  policy.style_src   :self, :unsafe_inline
end
```

**Environment Variables**
```bash
# Required production environment variables
export RAILS_ENV=production
export RAILS_MASTER_KEY=your-64-char-master-key
export DATABASE_URL=postgresql://user:password@host:5432/database
export REDIS_URL=redis://user:password@host:6379/0

# Optional but recommended
export RAILS_SERVE_STATIC_FILES=true
export RAILS_LOG_TO_STDOUT=true
export RAILS_MAX_THREADS=5
export WEB_CONCURRENCY=2
```

## 🔍 Monitoring and Logging

### Application Monitoring

**Health Check Endpoint**
```bash
# Monitor application health
curl https://yourapp.com/api/health

# Expected response:
{
  "status": "ok",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

**Performance Monitoring**
```ruby
# Add to Gemfile for production monitoring
gem 'newrelic_rpm'    # New Relic
gem 'skylight'        # Skylight
gem 'scout_apm'       # Scout APM
```

### Log Management

**Structured Logging**
```ruby
# config/environments/production.rb
config.log_level = :info
config.log_formatter = Logger::Formatter.new

# For JSON logging
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
```

**Log Aggregation**
```bash
# Ship logs to external service
# Papertrail, Logentries, Splunk, etc.

# Example: Papertrail with rsyslog
echo "*.* @logs.papertrailapp.com:12345" >> /etc/rsyslog.conf
```

### Database Monitoring

**Connection Pooling**
```ruby
# config/database.yml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000
  checkout_timeout: 5
```

**Query Performance**
```sql
-- PostgreSQL slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1 second
SELECT pg_reload_conf();
```

## 📊 Performance Optimization

### Application Performance

**Caching Strategy**
```ruby
# config/environments/production.rb
config.cache_classes = true
config.consider_all_requests_local = false
config.action_controller.perform_caching = true

# Use Redis for caching
config.cache_store = :redis_cache_store, {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
}
```

**Database Optimization**
```ruby
# Use connection pooling
# config/database.yml
production:
  pool: <%= ENV.fetch("DB_POOL", 5) %>
  
# Eager load associations to prevent N+1
@users = current_organization.users.includes(:items)
```

**Asset Optimization**
```bash
# Precompile assets with compression
cd web
RAILS_ENV=production bundle exec rails assets:precompile

# Use CDN for asset delivery
# Configure in config/environments/production.rb
config.asset_host = 'https://cdn.yourdomain.com'
```

### Server Configuration

**Puma Configuration**
```ruby
# config/puma.rb
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

port ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "development" }

# Preload application for better memory usage
preload_app!
```

**Nginx Configuration**
```nginx
# /etc/nginx/sites-available/voipappz
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    root /app/public;
    
    # Serve static assets
    location ~ ^/(assets|packs)/ {
        gzip_static on;
        expires 1y;
        add_header Cache-Control public;
        add_header ETag "";
        break;
    }
    
    # Proxy to Rails app
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket support for ActionCable
    location /cable {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🚨 Troubleshooting Production Issues

### Common Production Problems

**Asset Loading Issues**
```bash
# Check if assets are properly compiled
ls web/public/assets/

# Recompile assets
cd web
RAILS_ENV=production bundle exec rails assets:clobber
RAILS_ENV=production bundle exec rails assets:precompile
```

**Database Connection Issues**
```bash
# Check database connectivity
cd web
RAILS_ENV=production bundle exec rails db:version

# Check connection pool
RAILS_ENV=production bundle exec rails console
> ActiveRecord::Base.connection_pool.stat
```

**ActionCable Connection Issues**
```bash
# Check Redis connectivity
redis-cli ping

# Check cable.yml configuration
cat web/config/cable.yml

# Test WebSocket connection in browser console
ws = new WebSocket('wss://yourapp.com/cable')
```

**Memory Issues**
```bash
# Check memory usage
ps aux | grep puma

# Check for memory leaks
# Add to Gemfile: gem 'memory_profiler'
# Monitor over time
```

### Log Analysis

**Application Logs**
```bash
# Heroku logs
heroku logs --tail

# Server logs
tail -f /var/log/rails/production.log

# Look for common patterns
grep "ERROR" production.log
grep "500" production.log
```

**Database Logs**
```sql
-- PostgreSQL: Check slow queries
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;
```

## 🔄 Zero-Downtime Deployment

### Blue-Green Deployment
```bash
# Deploy to staging environment first
git push staging main

# Test staging environment
curl https://staging.yourdomain.com/api/health

# Deploy to production
git push production main

# Monitor deployment
watch curl https://yourdomain.com/api/health
```

### Database Migrations
```bash
# For safe migrations, run before deployment
heroku run rails db:migrate --app your-app

# For zero-downtime, use migration strategies:
# 1. Add new columns (nullable)
# 2. Deploy code that works with old and new schema  
# 3. Backfill data
# 4. Remove old columns in next deployment
```

This deployment guide should help you successfully deploy your Rails monolith to production while maintaining security, performance, and reliability.