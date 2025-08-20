namespace :bonuses do
  desc "Clear all bonuses from database"
  task clear: :environment do
    count = Bonus.count
    puts "Found #{count} bonuses"

    if count > 0
      Bonus.destroy_all
      puts "Successfully deleted all #{count} bonuses"
    else
      puts "No bonuses found"
    end
  end
end
