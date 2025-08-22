class AddFieldsToFreespinRewards < ActiveRecord::Migration[8.0]
  def change
    add_column :freespin_rewards, :games, :text, default: [].to_yaml
    add_column :freespin_rewards, :bet_level, :float
    add_column :freespin_rewards, :max_win_value, :decimal
    add_column :freespin_rewards, :max_win_type, :string, default: "fixed"
    add_column :freespin_rewards, :available, :integer
    add_column :freespin_rewards, :code, :string
    add_column :freespin_rewards, :stag, :string
  end
end
