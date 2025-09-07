class TestAuthController < ApplicationController
  def check_users
    # Try to fetch specific users by email to get their external_ids
    test_emails = ['student1@cranston.edu', 'student2@cranston.edu', 'student3@cranston.edu']
    
    results = {}
    test_emails.each do |email|
      # Try logging in as each user to get their data
      uri = URI("#{ENV.fetch('AUTH_SERVICE_URL', 'http://localhost:3000')}/api/v1/auth/login")
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request.body = { email: email, password: 'password123' }.to_json
      
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      
      if response.code == '200'
        data = JSON.parse(response.body)
        token = data['token']
        
        # Decode the token to get user info
        if token
          decoded = JWT.decode(token, nil, false) rescue nil
          if decoded
            results[email] = decoded[0]
          end
        end
      end
    end
    
    render json: results
  end
end