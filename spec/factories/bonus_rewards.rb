# frozen_string_literal: true

FactoryBot.define do
  factory :bonus_reward do
    association :bonus
    reward_type { 'bonus' }
    amount { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    percentage { nil }
    config { {} }

    trait :percentage_based do
      amount { nil }
      percentage { Faker::Number.between(from: 5, to: 100) }
    end

    trait :with_wager do
      config { { 'wager' => Faker::Number.decimal(l_digits: 2, r_digits: 2) } }
    end

    trait :with_max_win_fixed do
      config { { 'max_win' => Faker::Number.decimal(l_digits: 3, r_digits: 2).to_s } }
    end

    trait :with_max_win_multiplier do
      config { { 'max_win' => "x#{Faker::Number.between(from: 5, to: 50)}" } }
    end

    trait :with_availability do
      config { { 'available' => Faker::Number.between(from: 1, to: 100) } }
    end

    trait :with_code do
      config { { 'code' => "REWARD_#{Faker::Alphanumeric.alpha(number: 6).upcase}" } }
    end

    trait :with_currencies do
      config { { 'currencies' => %w[USD EUR RUB] } }
    end

    trait :with_min_deposit do
      config { { 'min' => Faker::Number.decimal(l_digits: 2, r_digits: 2) } }
    end

    trait :with_groups do
      config { { 'groups' => %w[VIP Regular Premium] } }
    end

    trait :with_tags do
      config { { 'tags' => %w[new_player returning_player high_roller] } }
    end

    trait :with_duplicates_allowed do
      config { { 'user_can_have_duplicates' => true } }
    end

    trait :with_limits do
      config do
        {
          'no_more' => Faker::Number.between(from: 1, to: 10),
          'totally_no_more' => Faker::Number.between(from: 5, to: 20)
        }
      end
    end

    trait :with_wagering_strategy do
      config { { 'wagering_strategy' => %w[bonus_first deposit_first].sample } }
    end

    trait :with_stag do
      config { { 'stag' => "STAG_#{Faker::Alphanumeric.alpha(number: 8).upcase}" } }
    end

    trait :with_advanced_params do
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
      with_currencies
      with_min_deposit
      with_groups
      with_tags
      with_limits
    end
  end
end
