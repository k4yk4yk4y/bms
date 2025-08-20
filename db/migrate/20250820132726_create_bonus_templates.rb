class CreateBonusTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :bonus_templates do |t|
      t.string :name
      t.string :dsl_tag
      t.string :project
      t.string :event
      t.string :currency
      t.decimal :minimum_deposit
      t.decimal :wager
      t.decimal :maximum_winnings
      t.integer :no_more
      t.integer :totally_no_more
      t.text :currencies
      t.text :groups
      t.text :currency_minimum_deposits
      t.text :description

      t.timestamps
    end

    add_index :bonus_templates, :dsl_tag
    add_index :bonus_templates, :project
    add_index :bonus_templates, [ :dsl_tag, :project, :name ], unique: true, name: 'index_bonus_templates_on_dsl_tag_project_name'
  end
end
