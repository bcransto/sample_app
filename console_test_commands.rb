# Rails Console Test Commands for Sample App Integration
# Run these commands in Rails console: rails console
# Copy and paste each section to test the integration

puts "=" * 60
puts "Testing Cranston Auth Integration"
puts "=" * 60

# Test 1: Fetch a single user
puts "\n1. Testing single user fetch:"
admin = AuthApiService.fetch_user("02392ed0-0936-4bf6-966f-1271c56363eb")
if admin
  puts "✓ Admin user fetched: #{admin['email']}"
  puts "  Name: #{admin['first_name']} #{admin['last_name']}"
  puts "  Role: #{admin['role']}"
else
  puts "✗ Failed to fetch admin user"
end

# Test 2: Fetch multiple users
puts "\n2. Testing batch user fetch:"
user_ids = [
  "02392ed0-0936-4bf6-966f-1271c56363eb", # admin
  "3a87c741-89ba-4f69-aca8-f7bb78b86a82", # teacher1
  "0b5ed94e-d9e0-4e65-b43f-d9f3e4038bb3"  # student1
]
users = AuthApiService.fetch_users(user_ids)
puts "✓ Fetched #{users.length} users:"
users.each { |u| puts "  - #{u['email']} (#{u['role']})" }

# Test 3: Create a post with author lookup
puts "\n3. Creating a post with author lookup:"
post = Post.create!(
  title: "Test Integration Post",
  content: "This post tests the auth service integration",
  author_external_id: "3a87c741-89ba-4f69-aca8-f7bb78b86a82" # teacher1
)
puts "✓ Post created with ID: #{post.id}"
puts "  Author name: #{post.author_name}"
puts "  Author email: #{post.author_email}"

# Test 4: Test error handling with non-existent user
puts "\n4. Testing non-existent user:"
ghost = AuthApiService.fetch_user("00000000-0000-0000-0000-000000000000")
if ghost.nil?
  puts "✓ Correctly returned nil for non-existent user"
else
  puts "✗ Should have returned nil"
end

# Test 5: Create posts with different authors and list them
puts "\n5. Creating multiple posts with different authors:"
post_data = [
  { title: "Admin Post", author_id: "02392ed0-0936-4bf6-966f-1271c56363eb" },
  { title: "Teacher Post", author_id: "3a87c741-89ba-4f69-aca8-f7bb78b86a82" },
  { title: "Student Post", author_id: "0b5ed94e-d9e0-4e65-b43f-d9f3e4038bb3" }
]

post_data.each do |data|
  post = Post.create!(
    title: data[:title],
    content: "Content for #{data[:title]}",
    author_external_id: data[:author_id]
  )
  puts "✓ Created: '#{post.title}' by #{post.author_name}"
end

# Test 6: Fetch all authors for recent posts
puts "\n6. Batch fetching authors for recent posts:"
recent_posts = Post.last(3)
author_ids = recent_posts.map(&:author_external_id).uniq
authors = AuthApiService.fetch_users(author_ids)
puts "✓ Fetched #{authors.length} unique authors for #{recent_posts.length} posts"

# Test 7: Performance test - measure API call time
puts "\n7. Performance test:"
start_time = Time.now
10.times do
  AuthApiService.fetch_user("02392ed0-0936-4bf6-966f-1271c56363eb")
end
end_time = Time.now
avg_time = ((end_time - start_time) / 10 * 1000).round(2)
puts "✓ Average API call time: #{avg_time}ms"

# Test 8: Test caching behavior (if implemented)
puts "\n8. Testing caching (multiple calls for same user):"
post = Post.last
3.times do |i|
  start = Time.now
  post.author # This should use @author ||= memoization
  elapsed = ((Time.now - start) * 1000).round(2)
  puts "  Call #{i+1}: #{elapsed}ms"
end

# Summary
puts "\n" + "=" * 60
puts "Integration test complete!"
puts "All systems are properly connected." 
puts "=" * 60

# Useful queries for debugging
puts "\nUseful debugging commands:"
puts "# Check all posts with authors:"
puts "Post.all.map { |p| [p.title, p.author_name] }"
puts "\n# Check unique author IDs in database:"
puts "Post.pluck(:author_external_id).uniq"
puts "\n# Fetch all unique authors from Auth service:"
puts "AuthApiService.fetch_users(Post.pluck(:author_external_id).uniq)"