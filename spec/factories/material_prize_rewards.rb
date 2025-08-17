# frozen_string_literal: true

FactoryBot.define do
  factory :material_prize_reward do
    association :bonus
    prize_name { Faker::Commerce.product_name }
    prize_value { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    config { {} }

    trait :electronics do
      prize_name { ['iPhone 15', 'MacBook Pro', 'PlayStation 5', 'iPad Air', 'Samsung Galaxy'].sample }
      prize_value { Faker::Number.between(from: 500, to: 3000) }
    end

    trait :luxury_items do
      prize_name { ['Rolex Watch', 'Diamond Ring', 'Gold Necklace', 'Designer Handbag'].sample }
      prize_value { Faker::Number.between(from: 1000, to: 10000) }
    end

    trait :gift_cards do
      prize_name { ['Amazon Gift Card', 'iTunes Gift Card', 'Steam Gift Card', 'Google Play Card'].sample }
      prize_value { Faker::Number.between(from: 25, to: 500) }
    end

    trait :cars do
      prize_name { ['BMW X5', 'Mercedes C-Class', 'Audi A4', 'Tesla Model 3', 'Porsche 911'].sample }
      prize_value { Faker::Number.between(from: 30000, to: 100000) }
    end

    trait :travel_packages do
      prize_name { ['Trip to Bali', 'European Tour', 'Caribbean Cruise', 'Tokyo Adventure'].sample }
      prize_value { Faker::Number.between(from: 2000, to: 15000) }
    end

    trait :cash_equivalent do
      prize_name { 'Cash Prize' }
      prize_value { [1000, 5000, 10000, 25000, 50000].sample }
    end

    trait :no_monetary_value do
      prize_name { ['Trophy', 'Certificate', 'Medal', 'Recognition Award'].sample }
      prize_value { nil }
    end

    trait :low_value do
      prize_name { ['T-Shirt', 'Mug', 'Keychain', 'Sticker Pack'].sample }
      prize_value { Faker::Number.between(from: 5, to: 50) }
    end

    trait :medium_value do
      prize_name { ['Tablet', 'Smartwatch', 'Headphones', 'Gaming Console'].sample }
      prize_value { Faker::Number.between(from: 100, to: 800) }
    end

    trait :high_value do
      prize_name { ['Luxury Car', 'House Down Payment', 'Investment Portfolio'].sample }
      prize_value { Faker::Number.between(from: 50000, to: 500000) }
    end

    trait :seasonal do
      prize_name { ['Christmas Hamper', 'Easter Basket', 'Halloween Costume', 'New Year Package'].sample }
      prize_value { Faker::Number.between(from: 50, to: 300) }
    end

    trait :branded_merchandise do
      prize_name { ['Casino Branded Watch', 'Premium Poker Set', 'VIP Jacket', 'Engraved Flask'].sample }
      prize_value { Faker::Number.between(from: 75, to: 400) }
    end
  end
end
