require 'net/http'
require 'json'

class AuthApiService
  AUTH_SERVICE_URL = ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3000')
  SERVICE_API_KEY = ENV.fetch('SERVICE_API_KEY', 'classroom_service_key_123')
  
  # Instance method versions for compatibility
  def fetch_user(external_id)
    self.class.fetch_user(external_id)
  end
  
  def fetch_users(external_ids)
    self.class.fetch_users(external_ids)
  end
  
  def self.fetch_user(external_id)
    Rails.logger.info "Fetching single user with external_id: #{external_id}"
    uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users/#{external_id}")
    request = Net::HTTP::Get.new(uri)
    request['X-Service-Api-Key'] = SERVICE_API_KEY
    request['Content-Type'] = 'application/json'
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to fetch user: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching user: #{e.message}"
    nil
  end
  
  def self.fetch_users(external_ids)
    return [] if external_ids.empty?
    
    Rails.logger.info "Fetching multiple users with external_ids: #{external_ids.inspect}"
    uri = URI("#{AUTH_SERVICE_URL}/api/v1/services/users")
    uri.query = URI.encode_www_form(external_ids.map { |id| ['external_ids[]', id] })
    Rails.logger.info "Request URL: #{uri}"
    
    request = Net::HTTP::Get.new(uri)
    request['X-Service-Api-Key'] = SERVICE_API_KEY
    request['Content-Type'] = 'application/json'
    Rails.logger.info "Using API Key: #{SERVICE_API_KEY}"
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"
    
    if response.code == '200'
      result = JSON.parse(response.body)
      Rails.logger.info "Successfully parsed #{result.length} users"
      result
    else
      Rails.logger.error "Failed to fetch users: #{response.code} - #{response.body}"
      []
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching users: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    []
  end
  
  def self.validate_token(token)
    uri = URI("#{AUTH_SERVICE_URL}/api/v1/auth/validate")
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'
    
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error validating token: #{e.message}"
    nil
  end
end