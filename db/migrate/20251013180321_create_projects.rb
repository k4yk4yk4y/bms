class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :projects, :name, unique: true

    # Add project_id foreign key to permanent_bonuses
    add_reference :permanent_bonuses, :project, foreign_key: true

    # Migrate existing data from string project column to project_id
    # This needs to be done before removing the old column
    reversible do |dir|
      dir.up do
        # Get unique project names from permanent_bonuses
        project_names = execute("SELECT DISTINCT project FROM permanent_bonuses WHERE project IS NOT NULL").to_a.map { |row| row['project'] }

        # Create Project records for each unique project name
        project_names.each do |project_name|
          execute("INSERT INTO projects (name, created_at, updated_at) VALUES ('#{project_name}', NOW(), NOW()) ON CONFLICT (name) DO NOTHING")

          # Update permanent_bonuses to use project_id
          execute(<<-SQL
            UPDATE permanent_bonuses#{' '}
            SET project_id = (SELECT id FROM projects WHERE name = '#{project_name}')
            WHERE project = '#{project_name}'
          SQL
          )
        end
      end
    end

    # Remove the old string project column
    remove_column :permanent_bonuses, :project, :string
  end
end
