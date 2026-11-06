# frozen_string_literal: true

# DropDormantExamScaffold — removes the old generator-produced exam tables.
#
# The app is pre-release, so the scaffold is replaced wholesale rather than
# migrated. Child tables are dropped before their parents to satisfy FKs.
class DropDormantExamScaffold < ActiveRecord::Migration[8.1]
  def up
    drop_table :answer_tag_appointments, if_exists: true
    drop_table :question_tag_appointments, if_exists: true
    drop_table :exam_tag_appointments, if_exists: true
    drop_table :exam_group_tag_appointments, if_exists: true
    drop_table :employee_exam_appointments, if_exists: true
    drop_table :answers, if_exists: true
    drop_table :questions, if_exists: true
    drop_table :exams, if_exists: true
    drop_table :exam_groups, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The dormant exam scaffold is not recreated"
  end
end
