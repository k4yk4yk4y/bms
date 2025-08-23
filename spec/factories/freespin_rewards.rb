# frozen_string_literal: true

FactoryBot.define do
  factory :freespin_reward do
    association :bonus
    spins_count { Faker::Number.between(from: 5, to: 100) }

    # Provide a default for the required field
    currency_freespin_bet_levels { { "EUR" => 0.20 } }

    trait :with_games do
      games { %w[Starburst Gonzo's_Quest Book_of_Dead] }
    end

    trait :with_bet_level do
      bet_level { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    end



    trait :with_code do
      code { "FS_#{Faker::Alphanumeric.alpha(number: 6).upcase}" }
    end

    trait :with_stag do
      stag { "FS_STAG_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    end

    trait :with_currency_bet_levels do
      currency_freespin_bet_levels do
        {
          'USD' => 0.25,
          'EUR' => 0.20,
          'RUB' => 15.00
        }
      end
    end

    trait :complete do
      with_games
      with_bet_level
      with_code
      with_currency_bet_levels
    end

    trait :single_game do
      games { [ 'Starburst' ] }
    end



    trait :high_spins do
      spins_count { Faker::Number.between(from: 100, to: 500) }
    end
  end
end
