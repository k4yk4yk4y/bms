class AddGinIndexesForCurrencyJsonbFilters < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :bonuses,
              "((COALESCE(currencies, '[]')::jsonb))",
              using: :gin,
              algorithm: :concurrently,
              name: "index_bonuses_on_currencies_jsonb"

    add_index :bonus_templates,
              "((COALESCE(currencies, '[]')::jsonb))",
              using: :gin,
              algorithm: :concurrently,
              name: "index_bonus_templates_on_currencies_jsonb"
  end

  def down
    remove_index :bonuses, name: "index_bonuses_on_currencies_jsonb"
    remove_index :bonus_templates, name: "index_bonus_templates_on_currencies_jsonb"
  end
end
