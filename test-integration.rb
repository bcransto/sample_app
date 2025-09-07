#!/usr/bin/env ruby

# Test script for Sample App integration with Cranston Auth Service
# Run this from the sample_app directory: ruby test-integration.rb

require 'net/http'
require 'json'
require 'uri'

# Configuration
AUTH_SERVICE_URL = ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3000')
SERVICE_API_KEY = ENV.fetch('SERVICE_API_KEY', 'classroom_service_key_123')

# Colors for output
class Colors
  RED = "\033[0;31m"
  GREEN = "\033[0;32m"
  YELLOW = "\033[1;33m"
  BLUE = "\033[0;34m"
  NC = "\033[0m" # No Color
end

def print_header(message)
  puts "\n#{Colors::YELLOW}=== #{message} ===#{Colors::NC}"
end

def print_success(message)
  puts "#{Colors::GREEN}✓ #{message}#{Colors::NC}"
end

def print_error(message)
  puts "#{Colors::RED}✗ #{message}#{Colors::NC}"
end

def print_info(message)
  puts "#{Colors::BLUE}ℹ #{message}#{Colors::NC}"
end

# Test methods
def test_fetch_single_user
  print_header "Test 1: Fetch Single User"
  
  # Admin user external_id from seed data
  external_id = "02392ed0-0936-4bf6-966f-1271c56363eb"
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users/#{external_id}")
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = SERVICE_API_KEY
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '200'
    user = JSON.parse(response.body)
    print_success "Successfully fetched user: #{user['email']}"
    print_info "User details: #{user['first_name']} #{user['last_name']} (#{user['role']})"
    true
  else
    print_error "Failed to fetch user: #{response.code} - #{response.body}"
    false
  end
rescue => e
  print_error "Error: #{e.message}"
  false
end

def test_fetch_multiple_users
  print_header "Test 2: Fetch Multiple Users"
  
  # Multiple user external_ids from seed data
  external_ids = [
    "02392ed0-0936-4bf6-966f-1271c56363eb", # admin
    "3a87c741-89ba-4f69-aca8-f7bb78b86a82", # teacher1
    "0b5ed94e-d9e0-4e65-b43f-d9f3e4038bb3"  # student1
  ]
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users")
  uri.query = URI.encode_www_form(external_ids.map { |id| ['external_ids[]', id] })
  
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = SERVICE_API_KEY
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '200'
    users = JSON.parse(response.body)
    print_success "Successfully fetched #{users.length} users"
    users.each do |user|
      print_info "  - #{user['email']} (#{user['role']})"
    end
    true
  else
    print_error "Failed to fetch users: #{response.code} - #{response.body}"
    false
  end
rescue => e
  print_error "Error: #{e.message}"
  false
end

def test_invalid_api_key
  print_header "Test 3: Invalid API Key (Should Fail)"
  
  external_id = "02392ed0-0936-4bf6-966f-1271c56363eb"
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users/#{external_id}")
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = 'invalid_key_123'
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '401'
    print_success "Correctly rejected invalid API key with 401"
    true
  else
    print_error "Should have rejected invalid key, got: #{response.code}"
    false
  end
rescue => e
  print_error "Error: #{e.message}"
  false
end

def test_nonexistent_user
  print_header "Test 4: Fetch Non-existent User"
  
  external_id = "00000000-0000-0000-0000-000000000000"
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users/#{external_id}")
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = SERVICE_API_KEY
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '404'
    print_success "Correctly returned 404 for non-existent user"
    true
  else
    print_error "Should have returned 404, got: #{response.code}"
    false
  end
rescue => e
  print_error "Error: #{e.message}"
  false
end

def test_empty_batch_request
  print_header "Test 5: Empty Batch Request"
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users")
  
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = SERVICE_API_KEY
  request['Content-Type'] = 'application/json'
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '400'
    print_success "Correctly returned 400 for empty batch request"
    true
  else
    print_error "Should have returned 400, got: #{response.code}"
    false
  end
rescue => e
  print_error "Error: #{e.message}"
  false
end

def check_auth_service_running
  print_header "Checking Auth Service Status"
  
  uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users/test")
  request = Net::HTTP::Get.new(uri)
  request['X-Service-Api-Key'] = SERVICE_API_KEY
  
  response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 2, read_timeout: 2) do |http|
    http.request(request)
  end
  
  print_success "Auth service is running at #{AUTH_SERVICE_URL}"
  true
rescue Errno::ECONNREFUSED
  print_error "Auth service is not running at #{AUTH_SERVICE_URL}"
  print_info "Please start the auth service with: cd ../cranston_auth && rails server"
  false
rescue => e
  print_error "Error checking service: #{e.message}"
  false
end

# Main execution
def run_tests
  puts "#{Colors::BLUE}╔════════════════════════════════════════════════════════╗#{Colors::NC}"
  puts "#{Colors::BLUE}║     Sample App → Cranston Auth Integration Test       ║#{Colors::NC}"
  puts "#{Colors::BLUE}╚════════════════════════════════════════════════════════╝#{Colors::NC}"
  
  print_info "Auth Service URL: #{AUTH_SERVICE_URL}"
  print_info "Service API Key: #{SERVICE_API_KEY[0..20]}..."
  
  unless check_auth_service_running
    puts "\n#{Colors::RED}Tests aborted: Auth service is not available#{Colors::NC}"
    exit 1
  end
  
  results = []
  
  # Run all tests
  results << test_fetch_single_user
  results << test_fetch_multiple_users
  results << test_invalid_api_key
  results << test_nonexistent_user
  results << test_empty_batch_request
  
  # Summary
  print_header "Test Summary"
  passed = results.count(true)
  failed = results.count(false)
  total = results.length
  
  if failed == 0
    puts "#{Colors::GREEN}✓ All #{total} tests passed!#{Colors::NC}"
  else
    puts "#{Colors::YELLOW}Tests completed: #{passed}/#{total} passed, #{failed} failed#{Colors::NC}"
  end
  
  puts "\n#{Colors::BLUE}Integration Points Tested:#{Colors::NC}"
  puts "  • Service-to-service authentication with API key"
  puts "  • Single user lookup by external_id"
  puts "  • Batch user lookup by multiple external_ids"
  puts "  • Error handling for invalid credentials"
  puts "  • Error handling for non-existent users"
  puts "  • Validation of empty requests"
end

# Run the tests
run_tests