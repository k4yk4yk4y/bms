namespace :templates do
  desc "Clear all bonus templates from database"
  task clear: :environment do
    count = BonusTemplate.count
    puts "Found #{count} bonus templates"

    if count > 0
      BonusTemplate.destroy_all
      puts "Successfully deleted all #{count} bonus templates"
    else
      puts "No bonus templates found"
    end
  end
end
