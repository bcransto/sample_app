# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding teacher-student relationships..."

# Clear existing records first to avoid duplicates with old UUIDs
TeacherStudent.destroy_all

# Teacher 1 (teacher1@cranston.edu) has students 1 and 2
# Using the actual external_ids from the auth service
TeacherStudent.find_or_create_by!(
  teacher_external_id: '2d65e8dc-470b-4f84-8210-5bc09dd13fd3',  # teacher1@cranston.edu
  student_external_id: '74063cab-7dbb-42b9-8bae-5eeef06d1830'   # student1@cranston.edu
)

TeacherStudent.find_or_create_by!(
  teacher_external_id: '2d65e8dc-470b-4f84-8210-5bc09dd13fd3',  # teacher1@cranston.edu
  student_external_id: 'a9a6c279-9e69-45eb-bbaf-c6cabc48f0f7'   # student2@cranston.edu
)

# Teacher 2 (teacher2@cranston.edu) has students 2 and 3
# Note: You'll need to login as teacher2 to get their actual external_id
# For now using placeholder, update after logging in as teacher2
TeacherStudent.find_or_create_by!(
  teacher_external_id: '88c3e0c9-9f1f-4b6f-b8e4-e7e8d2f3a4b5',  # placeholder - update with teacher2's actual external_id
  student_external_id: 'a9a6c279-9e69-45eb-bbaf-c6cabc48f0f7'   # student2@cranston.edu
)

TeacherStudent.find_or_create_by!(
  teacher_external_id: '88c3e0c9-9f1f-4b6f-b8e4-e7e8d2f3a4b5',  # placeholder - update with teacher2's actual external_id
  student_external_id: '09a599b7-f5cf-42c5-9a3a-3ed37db81955'   # student3@cranston.edu
)

puts "Created #{TeacherStudent.count} teacher-student relationships"
puts "Teacher 1 (teacher1@cranston.edu) has students: student1 and student2"
puts "Teacher 2 (teacher2@cranston.edu) has students: student2 and student3"
