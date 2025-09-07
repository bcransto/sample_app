class Post < ApplicationRecord
  validates :title, presence: true
  validates :content, presence: true
  validates :author_external_id, presence: true
  
  def author
    @author ||= AuthApiService.fetch_user(author_external_id)
  end
  
  def author_name
    author ? "#{author['first_name']} #{author['last_name']}" : 'Unknown Author'
  end
  
  def author_email
    author ? author['email'] : nil
  end
end
