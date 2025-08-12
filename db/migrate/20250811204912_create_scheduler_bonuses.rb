class CreateSchedulerBonuses < ActiveRecord::Migration[8.0]
  def change
    create_table :scheduler_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :schedule_type, null: false
      t.string :cron_expression
      t.datetime :next_run_at
      t.datetime :last_run_at
      t.integer :execution_count, default: 0
      t.integer :max_executions

      t.timestamps
    end

    # Index already created by t.references
    add_index :scheduler_bonuses, :schedule_type
    add_index :scheduler_bonuses, :next_run_at
    add_index :scheduler_bonuses, :last_run_at
  end
end
