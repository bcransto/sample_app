class TeacherStudent < ApplicationRecord
  validates :teacher_external_id, presence: true
  validates :student_external_id, presence: true
  validates :teacher_external_id, uniqueness: { scope: :student_external_id }

  def teacher
    @teacher ||= AuthApiService.new.fetch_user(teacher_external_id)
  end

  def student
    @student ||= AuthApiService.new.fetch_user(student_external_id)
  end

  def self.students_for_teacher(teacher_external_id)
    Rails.logger.info "Looking for students for teacher: #{teacher_external_id}"
    student_ids = where(teacher_external_id: teacher_external_id).pluck(:student_external_id)
    Rails.logger.info "Found student_ids: #{student_ids.inspect}"
    
    return [] if student_ids.empty?
    
    auth_service = AuthApiService.new
    result = auth_service.fetch_users(student_ids)
    Rails.logger.info "Auth service returned: #{result.inspect}"
    result
  end

  def self.teachers_for_student(student_external_id)
    teacher_ids = where(student_external_id: student_external_id).pluck(:teacher_external_id)
    return [] if teacher_ids.empty?
    
    auth_service = AuthApiService.new
    auth_service.fetch_users(teacher_ids)
  end
end