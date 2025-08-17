# frozen_string_literal: true

FactoryBot.define do
  factory :bonus_code_reward do
    association :bonus
    code { "CODE_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    code_type { 'set_bonus_code' }
    config { {} }

    # Alternative names for attributes for compatibility
    trait :with_set_bonus_code do
      code { "SET_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
      code_type { 'set_bonus_code' }
    end

    trait :with_title do
      config { { 'title' => "#{Faker::Lorem.words(number: 2).join(' ')} Bonus Code" } }
    end

    trait :with_config_json do
      config do
        {
          'title' => "#{Faker::Lorem.words(number: 2).join(' ')} Code",
          'description' => Faker::Lorem.sentence,
          'usage_limit' => Faker::Number.between(from: 1, to: 1000),
          'expiry_date' => Faker::Date.forward(days: 30).iso8601
        }
      end
    end

    trait :welcome_code do
      code { "WELCOME#{Faker::Number.number(digits: 3)}" }
      config { { 'title' => 'Welcome Bonus Code' } }
    end

    trait :vip_code do
      code { "VIP#{Faker::Number.number(digits: 4)}" }
      config { { 'title' => 'VIP Exclusive Code' } }
    end

    trait :weekend_code do
      code { "WEEKEND#{Faker::Number.number(digits: 3)}" }
      config { { 'title' => 'Weekend Special Code' } }
    end

    trait :limited_use do
      config do
        {
          'title' => 'Limited Use Code',
          'usage_limit' => Faker::Number.between(from: 1, to: 10)
        }
      end
    end

    trait :unlimited_use do
      config do
        {
          'title' => 'Unlimited Use Code',
          'usage_limit' => nil
        }
      end
    end

    trait :expiring_soon do
      config do
        {
          'title' => 'Expiring Soon Code',
          'expiry_date' => 1.day.from_now.iso8601
        }
      end
    end
  end
end
