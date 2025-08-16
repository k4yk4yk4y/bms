class RemoveOldBonusTables < ActiveRecord::Migration[8.0]
  def up
    # Удаляем внешние ключи
    remove_foreign_key :deposit_bonuses, :bonuses if foreign_key_exists?(:deposit_bonuses, :bonuses)
    remove_foreign_key :input_coupon_bonuses, :bonuses if foreign_key_exists?(:input_coupon_bonuses, :bonuses)
    remove_foreign_key :manual_bonuses, :bonuses if foreign_key_exists?(:manual_bonuses, :bonuses)
    remove_foreign_key :collect_bonuses, :bonuses if foreign_key_exists?(:collect_bonuses, :bonuses)
    remove_foreign_key :groups_update_bonuses, :bonuses if foreign_key_exists?(:groups_update_bonuses, :bonuses)
    remove_foreign_key :scheduler_bonuses, :bonuses if foreign_key_exists?(:scheduler_bonuses, :bonuses)
    
    # Удаляем таблицы
    drop_table :deposit_bonuses, if_exists: true
    drop_table :input_coupon_bonuses, if_exists: true
    drop_table :manual_bonuses, if_exists: true
    drop_table :collect_bonuses, if_exists: true
    drop_table :groups_update_bonuses, if_exists: true
    drop_table :scheduler_bonuses, if_exists: true
    
    # Удаляем старую колонку bonus_type
    remove_column :bonuses, :bonus_type, :string if column_exists?(:bonuses, :bonus_type)
  end

  def down
    # Восстанавливаем bonus_type
    add_column :bonuses, :bonus_type, :string unless column_exists?(:bonuses, :bonus_type)
    
    # Заполняем bonus_type на основе event
    execute "UPDATE bonuses SET bonus_type = event WHERE event IS NOT NULL;"
    
    # Воссоздаем старые таблицы (простая структура)
    create_table :deposit_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.decimal :deposit_amount_required, precision: 10, scale: 2
      t.decimal :bonus_percentage, precision: 5, scale: 2
      t.decimal :max_bonus_amount, precision: 15, scale: 2
      t.boolean :first_deposit_only, default: false
      t.boolean :recurring_eligible, default: false
      t.timestamps
    end

    create_table :input_coupon_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :coupon_code, null: false
      t.integer :usage_limit, default: 1
      t.integer :usage_count, default: 0
      t.datetime :expires_at
      t.boolean :single_use, default: true
      t.timestamps
    end

    create_table :manual_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.text :admin_notes
      t.boolean :approval_required, default: true
      t.boolean :auto_apply, default: false
      t.text :conditions
      t.timestamps
    end

    create_table :collect_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.string :collection_type, null: false
      t.decimal :collection_amount, precision: 15, scale: 2
      t.string :collection_frequency, default: "daily"
      t.integer :collection_limit, default: 1
      t.integer :collected_count, default: 0
      t.timestamps
    end

    create_table :groups_update_bonuses do |t|
      t.references :bonus, null: false, foreign_key: true
      t.text :target_groups, null: false
      t.string :update_type, null: false
      t.text :update_parameters
      t.integer :batch_size, default: 100
      t.string :processing_status, default: "pending"
      t.timestamps
    end

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
  end
end
