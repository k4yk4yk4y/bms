# frozen_string_literal: true

FactoryBot.define do
  factory :freespin_reward do
    association :bonus
    spins_count { Faker::Number.between(from: 5, to: 100) }
    game_restrictions { nil }
    config { {} }

    trait :with_games do
      config { { 'games' => %w[Starburst Gonzo's_Quest Book_of_Dead] } }
    end

    trait :with_bet_level do
      config { { 'bet_level' => Faker::Number.decimal(l_digits: 1, r_digits: 2) } }
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
      config { { 'code' => "FS_#{Faker::Alphanumeric.alpha(number: 6).upcase}" } }
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
      config { { 'tags' => %w[welcome_bonus weekend_bonus loyalty_reward] } }
    end

    trait :with_stag do
      config { { 'stag' => "FS_STAG_#{Faker::Alphanumeric.alpha(number: 8).upcase}" } }
    end

    trait :with_wagering_strategy do
      config { { 'wagering_strategy' => %w[bonus_first deposit_first].sample } }
    end

    trait :with_limits do
      config do
        {
          'no_more' => Faker::Number.between(from: 1, to: 10),
          'totally_no_more' => Faker::Number.between(from: 5, to: 20)
        }
      end
    end

    trait :with_currency_bet_levels do
      config do
        {
          'currency_bet_levels' => {
            'USD' => 0.25,
            'EUR' => 0.20,
            'RUB' => 15.0
          }
        }
      end
    end

    trait :with_advanced_params do
      config do
        {
          'auto_activate' => [true, false].sample,
          'duration' => Faker::Number.between(from: 1, to: 30),
          'activation_duration' => Faker::Number.between(from: 1, to: 7),
          'email_template' => 'freespins_welcome',
          'range' => "#{Faker::Number.between(from: 1, to: 100)}-#{Faker::Number.between(from: 101, to: 1000)}",
          'last_login_country' => Faker::Address.country_code,
          'profile_country' => Faker::Address.country_code,
          'current_ip_country' => Faker::Address.country_code,
          'user_can_have_duplicates' => [true, false].sample,
          'total_deposits' => Faker::Number.between(from: 1, to: 10),
          'deposits_sum' => Faker::Number.decimal(l_digits: 3, r_digits: 2),
          'loss_sum' => Faker::Number.decimal(l_digits: 3, r_digits: 2),
          'wager_done' => [true, false].sample
        }
      end
    end

    trait :complete do
      with_games
      with_bet_level
      with_max_win_fixed
      with_availability
      with_code
      with_currencies
      with_min_deposit
      with_groups
      with_tags
      with_limits
      with_currency_bet_levels
    end

    trait :single_game do
      config { { 'games' => ['Starburst'] } }
    end

    trait :unlimited_max_win do
      config { { 'max_win' => nil } }
    end

    trait :high_spins do
      spins_count { Faker::Number.between(from: 100, to: 500) }
    end
  end
end
