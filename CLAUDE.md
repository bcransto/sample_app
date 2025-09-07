# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sample App - A Rails 8.0 blog application that integrates with the Cranston Auth microservice for authentication and user management. This is a downstream service that demonstrates service-to-service communication patterns.

**Tech Stack:** Ruby 3.4.5, Rails 8.0, MySQL, JWT authentication

## Development Commands

```bash
# Start development server
rails server -p 3001  # Port 3001 to avoid conflict with Auth service on 3000

# Database operations  
rails db:create
rails db:migrate
rails db:seed

# Console access
rails console

# View routes
rails routes
rails routes | grep posts
rails routes | grep students

# Testing
rails test
rails test test/services/auth_api_service_test.rb  # Service integration tests

# Linting
rubocop
brakeman  # Security analysis

# Integration testing with Auth service
ruby test-integration.rb  # Test service-to-service auth
rails runner "$(cat console_test_commands.rb)"  # Rails console tests
```

## Architecture

### Authentication Flow
This app uses **hybrid authentication** with the Cranston Auth service:

1. **User Authentication (JWT)**: Users login via the Auth service, receive JWT tokens, and the app validates these tokens
2. **Service Authentication (API Key)**: The app uses `classroom_service_key_123` to fetch user data from Auth service

### Key Components

**AuthApiService** (`app/services/auth_api_service.rb`)
- Central service for all Auth API communication
- Methods: `fetch_user(external_id)`, `fetch_users(external_ids)`, `validate_token(token)`
- Uses service-to-service authentication with API key
- Instance and class method versions for flexibility

**Authentication Concern** (`app/controllers/concerns/authentication.rb`)
- Provides `current_user`, `logged_in?`, `authenticate_user!` helpers
- Handles both session-based and JWT token authentication
- Used by all controllers requiring authentication

**Models with External References**
- `Post`: References users via `author_external_id` 
- `TeacherStudent`: Maps teacher-student relationships using external_ids
- No local user storage - all user data fetched from Auth service

### Data Flow Pattern

1. **Posts** store only `author_external_id` (not full user data)
2. When displaying posts, the app fetches author details from Auth service
3. Teacher-student relationships stored locally, user details fetched on-demand
4. Uses memoization (`@author ||=`) to minimize API calls

## Environment Configuration

Required environment variables (in `.env`):
```
AUTH_SERVICE_URL=http://localhost:3000
SERVICE_API_KEY=classroom_service_key_123
```

## Service Integration Points

### Endpoints This App Calls
- `GET /api/v1/services/users/:external_id` - Fetch single user
- `GET /api/v1/services/users?external_ids[]=` - Batch fetch users
- `GET /api/v1/auth/validate` - Validate JWT tokens

### Features Demonstrating Integration
- **Posts**: Authors fetched from Auth service
- **Students page**: Teachers can view their assigned students
- **Test endpoints**: `/test_auth/check_users` (development only)

## Database Schema

Two main tables:
- `posts`: Blog posts with `author_external_id` foreign key
- `teacher_students`: Many-to-many relationship mapping

## Testing Integration

### Manual Testing
1. Ensure Auth service is running on port 3000
2. Start this app on port 3001
3. Use test credentials from Auth service seed data

### Automated Testing
- `test-integration.rb` - Standalone integration tests
- `test/services/auth_api_service_test.rb` - Unit tests with mocked responses (requires webmock gem)
- `console_test_commands.rb` - Interactive Rails console tests

### Test Users (from Auth service)
- Admin: `admin@cranston.edu` / `password123`
- Teacher: `teacher1@cranston.edu` / `password123`  
- Students: `student1@cranston.edu` / `password123`

## Common Tasks

### Adding Teacher-Student Relationships
```ruby
# In Rails console
TeacherStudent.create!(
  teacher_external_id: "teacher_uuid_here",
  student_external_id: "student_uuid_here"
)
```

### Debugging Auth Service Communication
```ruby
# Check service connectivity
AuthApiService.fetch_user("02392ed0-0936-4bf6-966f-1271c56363eb")

# View logs for API calls
tail -f log/development.log | grep "Auth"
```

### Running Both Services Together
```bash
# Terminal 1: Auth service
cd ../cranston_auth && rails server

# Terminal 2: Sample app
rails server -p 3001
```

## Key Implementation Notes

- User data is never cached in the database, only external_ids
- All user lookups go through AuthApiService for consistency
- Teachers can only see students explicitly assigned to them via TeacherStudent
- The app gracefully handles Auth service downtime (returns nil/empty arrays)