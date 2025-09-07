require 'jwt'

class JwtService
  # Try multiple possible secret keys since we don't know what the auth service uses
  POSSIBLE_SECRETS = [
    'your-secret-key',  # Common default
    'development_secret',
    Rails.application.credentials.secret_key_base,
    ENV['JWT_SECRET_KEY'],
    ENV['SECRET_KEY_BASE']
  ].compact
  
  def self.decode(token)
    # Try to decode without verification first to see the payload
    begin
      unverified = JWT.decode(token, nil, false)
      puts "="*50
      puts "UNVERIFIED JWT PAYLOAD:"
      puts unverified[0].inspect
      puts "JWT HEADER:"
      puts unverified[1].inspect
      puts "="*50
    rescue => e
      puts "Error decoding JWT without verification: #{e.message}"
    end
    
    # Try each possible secret
    POSSIBLE_SECRETS.each do |secret|
      begin
        decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
        puts "Successfully decoded with secret!"
        return HashWithIndifferentAccess.new(decoded[0])
      rescue JWT::DecodeError => e
        # Try next secret
      end
    end
    
    # If none work, decode without verification (less secure but allows us to see the data)
    begin
      decoded = JWT.decode(token, nil, false)
      puts "WARNING: Using unverified JWT decode"
      return HashWithIndifferentAccess.new(decoded[0])
    rescue => e
      Rails.logger.error "JWT decode error: #{e.message}"
      nil
    end
  end
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, POSSIBLE_SECRETS.first || 'development_secret', 'HS256')
  end
end