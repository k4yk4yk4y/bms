class SeedProjectsFromBonuses < ActiveRecord::Migration[8.0]
  def up
    # Get all unique project names from bonuses table
    project_names = execute("SELECT DISTINCT project FROM bonuses WHERE project IS NOT NULL AND project != ''").to_a.map { |row| row['project'] }

    # Also get project names from bonus_templates table
    template_project_names = execute("SELECT DISTINCT project FROM bonus_templates WHERE project IS NOT NULL AND project != '' AND project != 'All'").to_a.map { |row| row['project'] }

    # Combine and make unique
    all_project_names = (project_names + template_project_names).uniq.sort

    # Create Project records for each unique project name
    all_project_names.each do |project_name|
      execute("INSERT INTO projects (name, created_at, updated_at) VALUES ('#{project_name}', NOW(), NOW()) ON CONFLICT (name) DO NOTHING")
    end

    puts "Created #{all_project_names.length} projects: #{all_project_names.join(', ')}"
  end

  def down
    # Don't delete projects on rollback as they might be in use
    puts "Skipping project deletion on rollback to preserve data integrity"
  end
end
