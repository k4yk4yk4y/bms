# frozen_string_literal: true

FactoryBot.define do
  factory :bonus_reward do
    association :bonus
    reward_type { 'bonus' }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    percentage { nil }

    trait :percentage_based do
      amount { nil }
      percentage { Faker::Number.between(from: 5, to: 100) }
    end

    trait :with_wager do
      wager { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    trait :with_max_win_fixed do
      max_win_type { "fixed" }
      max_win_value { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    end

    trait :with_max_win_multiplier do
      max_win_type { "multiplier" }
      max_win_value { Faker::Number.between(from: 5, to: 50) }
    end

    trait :with_availability do
      available { Faker::Number.between(from: 1, to: 100) }
    end

    trait :with_code do
      code { "REWARD_#{Faker::Alphanumeric.alpha(number: 6).upcase}" }
    end

    trait :with_duplicates_allowed do
      user_can_have_duplicates { true }
    end

    trait :with_stag do
      stag { "STAG_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    end

    # Traits for advanced params that are still in `config`
    trait :with_advanced_config_params do
      config do
        {
          'range' => "#{Faker::Number.between(from: 1, to: 100)}-#{Faker::Number.between(from: 101, to: 1000)}",
          'last_login_country' => Faker::Address.country_code,
          'profile_country' => Faker::Address.country_code,
          'current_ip_country' => Faker::Address.country_code,
          'total_deposits' => Faker::Number.between(from: 1, to: 10),
          'deposits_sum' => Faker::Number.decimal(l_digits: 3, r_digits: 2),
          'loss_sum' => Faker::Number.decimal(l_digits: 3, r_digits: 2),
          'deposits_count' => Faker::Number.between(from: 1, to: 50),
          'wager_sum' => Faker::Number.decimal(l_digits: 4, r_digits: 2),
          'bets_count' => Faker::Number.between(from: 10, to: 1000)
        }
      end
    end

    trait :complete do
      with_wager
      with_max_win_fixed
      with_availability
      with_code
    end
  end
end
