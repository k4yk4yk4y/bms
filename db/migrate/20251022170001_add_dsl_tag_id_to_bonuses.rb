class AddDslTagIdToBonuses < ActiveRecord::Migration[8.0]
  def change
    add_reference :bonuses, :dsl_tag, null: true, foreign_key: true
  end
end
