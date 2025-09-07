require 'test_helper'
require 'webmock/minitest'

class AuthApiServiceTest < ActiveSupport::TestCase
  def setup
    @auth_url = ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3000')
    @api_key = ENV.fetch('SERVICE_API_KEY', 'classroom_service_key_123')
    
    # Sample user data
    @admin_user = {
      'external_id' => '02392ed0-0936-4bf6-966f-1271c56363eb',
      'email' => 'admin@cranston.edu',
      'role' => 'admin',
      'first_name' => 'Admin',
      'last_name' => 'User',
      'lasid' => nil
    }
    
    @teacher_user = {
      'external_id' => '3a87c741-89ba-4f69-aca8-f7bb78b86a82',
      'email' => 'teacher1@cranston.edu',
      'role' => 'teacher',
      'first_name' => 'Jane',
      'last_name' => 'Smith',
      'lasid' => nil
    }
  end
  
  test "fetch_user returns user data for valid external_id" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users/#{@admin_user['external_id']}")
      .with(headers: { 'X-Service-Api-Key' => @api_key })
      .to_return(status: 200, body: @admin_user.to_json, headers: { 'Content-Type' => 'application/json' })
    
    result = AuthApiService.fetch_user(@admin_user['external_id'])
    
    assert_not_nil result
    assert_equal @admin_user['email'], result['email']
    assert_equal @admin_user['role'], result['role']
  end
  
  test "fetch_user returns nil for non-existent user" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users/non-existent-id")
      .with(headers: { 'X-Service-Api-Key' => @api_key })
      .to_return(status: 404, body: { error: 'User not found' }.to_json)
    
    result = AuthApiService.fetch_user('non-existent-id')
    
    assert_nil result
  end
  
  test "fetch_user returns nil on network error" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users/#{@admin_user['external_id']}")
      .with(headers: { 'X-Service-Api-Key' => @api_key })
      .to_timeout
    
    result = AuthApiService.fetch_user(@admin_user['external_id'])
    
    assert_nil result
  end
  
  test "fetch_users returns array of users for valid external_ids" do
    external_ids = [@admin_user['external_id'], @teacher_user['external_id']]
    users_data = [@admin_user, @teacher_user]
    
    stub_request(:get, "#{@auth_url}/api/v1/services/users")
      .with(
        headers: { 'X-Service-Api-Key' => @api_key },
        query: { 'external_ids' => external_ids }
      )
      .to_return(status: 200, body: users_data.to_json, headers: { 'Content-Type' => 'application/json' })
    
    result = AuthApiService.fetch_users(external_ids)
    
    assert_equal 2, result.length
    assert_equal @admin_user['email'], result[0]['email']
    assert_equal @teacher_user['email'], result[1]['email']
  end
  
  test "fetch_users returns empty array for empty input" do
    result = AuthApiService.fetch_users([])
    
    assert_equal [], result
  end
  
  test "fetch_users returns empty array on error" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users")
      .with(
        headers: { 'X-Service-Api-Key' => @api_key },
        query: { 'external_ids' => ['id1', 'id2'] }
      )
      .to_return(status: 401, body: { error: 'Unauthorized' }.to_json)
    
    result = AuthApiService.fetch_users(['id1', 'id2'])
    
    assert_equal [], result
  end
  
  test "validate_token returns user data for valid token" do
    token = 'valid_jwt_token'
    user_data = {
      'user' => @admin_user,
      'token' => token,
      'exp' => 24.hours.from_now.to_i
    }
    
    stub_request(:get, "#{@auth_url}/api/v1/auth/validate")
      .with(headers: { 'Authorization' => "Bearer #{token}" })
      .to_return(status: 200, body: user_data.to_json, headers: { 'Content-Type' => 'application/json' })
    
    result = AuthApiService.validate_token(token)
    
    assert_not_nil result
    assert_equal @admin_user['email'], result['user']['email']
  end
  
  test "validate_token returns nil for invalid token" do
    stub_request(:get, "#{@auth_url}/api/v1/auth/validate")
      .with(headers: { 'Authorization' => "Bearer invalid_token" })
      .to_return(status: 401, body: { error: 'Invalid token' }.to_json)
    
    result = AuthApiService.validate_token('invalid_token')
    
    assert_nil result
  end
  
  # Integration test with Post model
  test "Post model can fetch author from auth service" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users/#{@teacher_user['external_id']}")
      .with(headers: { 'X-Service-Api-Key' => @api_key })
      .to_return(status: 200, body: @teacher_user.to_json, headers: { 'Content-Type' => 'application/json' })
    
    post = Post.new(
      title: 'Test Post',
      content: 'Test content',
      author_external_id: @teacher_user['external_id']
    )
    
    assert_equal 'Jane Smith', post.author_name
    assert_equal 'teacher1@cranston.edu', post.author_email
  end
  
  test "Post model handles missing author gracefully" do
    stub_request(:get, "#{@auth_url}/api/v1/services/users/missing-id")
      .with(headers: { 'X-Service-Api-Key' => @api_key })
      .to_return(status: 404, body: { error: 'User not found' }.to_json)
    
    post = Post.new(
      title: 'Test Post',
      content: 'Test content',
      author_external_id: 'missing-id'
    )
    
    assert_equal 'Unknown Author', post.author_name
    assert_nil post.author_email
  end
end

# To run these tests:
# 1. Add to Gemfile (test group): gem 'webmock'
# 2. Run: bundle install
# 3. Run: rails test test/services/auth_api_service_test.rb