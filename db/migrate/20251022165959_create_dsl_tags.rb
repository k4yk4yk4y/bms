class CreateDslTags < ActiveRecord::Migration[8.0]
  def change
    create_table :dsl_tags do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :dsl_tags, :name, unique: true
  end
end
