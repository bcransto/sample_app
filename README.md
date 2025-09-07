# Simple Blog App - Rails MVP

A minimal blog application that integrates with the Cranston Auth microservice for authentication.

## Features

- JWT-based authentication via external auth service
- CRUD operations for blog posts
- Simple, clean interface
- Authorization (users can only edit/delete their own posts)

## Setup

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Configure database:**
   ```bash
   rails db:create
   rails db:migrate
   ```

3. **Set environment variables:**
   ```bash
   # In .env or your shell
   export AUTH_SERVICE_URL=http://localhost:3000  # Your auth service URL
   export SERVICE_API_KEY=classroom_service_key_123  # Your service API key
   ```

4. **Start the server:**
   ```bash
   rails server -p 3001  # Run on port 3001 to avoid conflict with auth service
   ```

## Authentication Flow

1. User clicks "Login" → redirected to auth service
2. Auth service handles login → redirects back with JWT token
3. Token validated and user session created
4. User can now create/edit/delete posts

## API Integration

The app communicates with the auth service to:
- Validate JWT tokens
- Fetch user information via service-to-service API

## Development

- Ruby 3.4.5
- Rails 8.0
- MySQL database
- JWT for token handling

## Testing

Test users from auth service:
- admin@cranston.edu / password123
- teacher1@cranston.edu / password123
- student1@cranston.edu / password123
