class AddProjectAndDslTagToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_column :bonuses, :project, :string
    add_column :bonuses, :dsl_tag, :string
    
    add_index :bonuses, :project
    add_index :bonuses, :dsl_tag
  end
end
