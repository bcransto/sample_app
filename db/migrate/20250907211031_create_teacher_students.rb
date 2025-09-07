class CreateTeacherStudents < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_students do |t|
      t.string :teacher_external_id, null: false
      t.string :student_external_id, null: false

      t.timestamps
    end

    add_index :teacher_students, :teacher_external_id
    add_index :teacher_students, :student_external_id
    add_index :teacher_students, [:teacher_external_id, :student_external_id], unique: true, name: 'index_teacher_students_on_teacher_and_student'
  end
end
