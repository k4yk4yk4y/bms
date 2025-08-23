class FixBonusData < ActiveRecord::Migration[8.0]
  def up
    # Fix bonuses with empty project field
    execute <<-SQL
      UPDATE bonuses#{' '}
      SET project = 'All'#{' '}
      WHERE project = '' OR project IS NULL
    SQL

    # Fix bonuses with empty maximum_winnings_type field
    execute <<-SQL
      UPDATE bonuses#{' '}
      SET maximum_winnings_type = 'multiplier'#{' '}
      WHERE maximum_winnings_type = '' OR maximum_winnings_type IS NULL
    SQL

    # Fix bonuses with empty dsl_tag field
    execute <<-SQL
      UPDATE bonuses#{' '}
      SET dsl_tag = ''#{' '}
      WHERE dsl_tag IS NULL
    SQL
  end

  def down
    # This migration fixes data, so we can't easily revert it
    # But we can set project back to empty string for bonuses that were 'All'
    execute <<-SQL
      UPDATE bonuses#{' '}
      SET project = ''#{' '}
      WHERE project = 'All' AND id IN (
        SELECT id FROM bonuses WHERE project = 'All' LIMIT 100
      )
    SQL
  end
end
