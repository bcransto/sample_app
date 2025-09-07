require 'net/http'
require 'json'

class SessionsController < ApplicationController
  # No authentication needed for login/logout actions
  
  def new
    # Show login form
  end
  
  def create
    # Call auth service API to login
    auth_response = login_to_auth_service(params[:email], params[:password])
    
    puts "="*50
    puts "AUTH RESPONSE:"
    puts auth_response.inspect
    puts "="*50
    
    if auth_response && auth_response['token']
      # Validate the token and get user data
      user_data = AuthApiService.validate_token(auth_response['token'])
      
      puts "="*50
      puts "USER DATA FROM TOKEN VALIDATION:"
      puts user_data.inspect
      puts "="*50
      
      # Also decode the JWT to get additional claims like role
      token_payload = JwtService.decode(auth_response['token'])
      puts "="*50
      puts "JWT TOKEN PAYLOAD:"
      puts token_payload.inspect
      puts "="*50
      
      if user_data
        # The role might be in the token payload under 'user' or at the root level
        if token_payload
          role = token_payload['role'] || token_payload.dig('user', 'role')
          if role && !user_data['role']
            user_data['role'] = role
            puts "Added role from JWT: #{role}"
          end
          
          # Also check if the entire user object is in the token
          if token_payload['user'] && token_payload['user']['role']
            user_data['role'] ||= token_payload['user']['role']
          end
        end
        
        session[:user_data] = user_data
        session[:token] = auth_response['token']
        
        puts "="*50
        puts "USER LOGGED IN SUCCESSFULLY"
        puts "="*50
        puts "User Data: #{user_data.inspect}"
        puts "User ID: #{user_data['id']}"
        puts "External ID: #{user_data['external_id']}"
        puts "Email: #{user_data['email']}"
        puts "Name: #{user_data['first_name']} #{user_data['last_name']}"
        puts "Role: #{user_data['role']}"
        puts "="*50
        
        redirect_to posts_path, notice: "Welcome, #{user_data['first_name']}!"
      else
        redirect_to login_path, alert: 'Authentication failed'
      end
    else
      redirect_to login_path, alert: auth_response&.dig('error') || 'Invalid email or password'
    end
  end
  
  def destroy
    session.delete(:user_data)
    session.delete(:token)
    redirect_to posts_path, notice: 'You have been logged out.'
  end
  
  private
  
  def login_to_auth_service(email, password)
    uri = URI("#{ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3000')}/api/v1/auth/login")
    
    puts "Attempting login to: #{uri}"
    puts "Email: #{email}"
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = { email: email, password: password }.to_json
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    puts "Response code: #{response.code}"
    puts "Response body: #{response.body}"
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      JSON.parse(response.body) rescue { 'error' => 'Authentication failed' }
    end
  rescue StandardError => e
    Rails.logger.error "Login error: #{e.message}"
    { 'error' => "Connection error: #{e.message}" }
  end
end