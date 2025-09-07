class StudentsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher

  def index
    # Handle both data structures - nested and flat
    teacher_external_id = current_user.dig('user', 'external_id') || current_user['external_id']
    Rails.logger.info "="*50
    Rails.logger.info "FETCHING STUDENTS FOR TEACHER"
    Rails.logger.info "Teacher external_id: #{teacher_external_id}"
    Rails.logger.info "Current user data: #{current_user.inspect}"
    
    @students = TeacherStudent.students_for_teacher(teacher_external_id)
    
    Rails.logger.info "Students found: #{@students.inspect}"
    Rails.logger.info "="*50
  end

  private

  def authenticate_user!
    unless logged_in?
      redirect_to login_path, alert: 'Please log in to continue'
    end
  end

  def require_teacher
    unless current_user && current_user['role'] == 'teacher'
      redirect_to posts_path, alert: 'Only teachers can view students.'
    end
  end
end