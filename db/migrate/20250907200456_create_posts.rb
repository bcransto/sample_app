class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :author_external_id, null: false

      t.timestamps
    end
    
    add_index :posts, :author_external_id
  end
end
