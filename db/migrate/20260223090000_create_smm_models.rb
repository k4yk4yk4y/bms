class CreateSmmModels < ActiveRecord::Migration[7.1]
  def change
    create_table :smm_months do |t|
      t.string :name, null: false
      t.date :starts_on, null: false
      t.bigint :created_by
      t.string :created_by_type
      t.bigint :updated_by
      t.string :updated_by_type
      t.timestamps
    end

    create_table :smm_month_projects do |t|
      t.references :smm_month, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.bigint :created_by
      t.string :created_by_type
      t.bigint :updated_by
      t.string :updated_by_type
      t.timestamps
    end
    add_index :smm_month_projects, [ :smm_month_id, :project_id ], unique: true

    create_table :smm_presets do |t|
      t.string :name, null: false
      t.references :project, null: false, foreign_key: true
      t.references :manager, foreign_key: { to_table: :users }
      t.string :subject
      t.string :bonus_type
      t.integer :activation_limit
      t.integer :fs_count
      t.decimal :wager_multiplier, precision: 10, scale: 2
      t.decimal :max_win_multiplier, precision: 10, scale: 2
      t.string :locale
      t.string :group
      t.jsonb :currencies, default: []
      t.bigint :created_by
      t.string :created_by_type
      t.bigint :updated_by
      t.string :updated_by_type
      t.timestamps
    end
    create_table :smm_bonuses do |t|
      t.references :smm_month_project, null: false, foreign_key: true
      t.references :smm_preset, foreign_key: true
      t.references :bonus, foreign_key: true
      t.references :manager, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "draft"
      t.string :code
      t.string :deposit
      t.integer :activation_limit
      t.string :game
      t.integer :fs_count
      t.string :bet_value
      t.decimal :wager_multiplier, precision: 10, scale: 2
      t.decimal :max_win_multiplier, precision: 10, scale: 2
      t.string :group
      t.string :bonus_type
      t.string :subject
      t.string :locale
      t.jsonb :currencies, default: []
      t.bigint :created_by
      t.string :created_by_type
      t.bigint :updated_by
      t.string :updated_by_type
      t.timestamps
    end
  end
end
