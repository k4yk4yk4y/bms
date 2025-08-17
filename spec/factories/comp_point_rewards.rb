# frozen_string_literal: true

FactoryBot.define do
  factory :comp_point_reward do
    association :bonus
    points_amount { Faker::Number.between(from: 10, to: 1000) }
    multiplier { nil }
    config { {} }

    trait :low_amount do
      points_amount { Faker::Number.between(from: 10, to: 50) }
      config { { 'title' => 'Low Points Reward' } }
    end

    trait :medium_amount do
      points_amount { Faker::Number.between(from: 100, to: 300) }
      config { { 'title' => 'Medium Points Reward' } }
    end

    trait :high_amount do
      points_amount { Faker::Number.between(from: 500, to: 1000) }
      config { { 'title' => 'High Points Reward' } }
    end

    trait :with_multiplier do
      multiplier { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    end

    trait :vip_reward do
      points_amount { Faker::Number.between(from: 1000, to: 5000) }
      multiplier { Faker::Number.decimal(l_digits: 1, r_digits: 1) }
      config { { 'title' => 'VIP Points Reward' } }
    end

    trait :with_config_json do
      config do
        {
          'title' => "#{Faker::Lorem.words(number: 2).join(' ')} Points",
          'description' => Faker::Lorem.sentence,
          'bonus_percentage' => Faker::Number.between(from: 5, to: 25),
          'expiry_days' => Faker::Number.between(from: 30, to: 365)
        }
      end
    end

    trait :welcome_points do
      points_amount { 100 }
      multiplier { 1.5 }
      config { { 'title' => 'Welcome Points' } }
    end

    trait :loyalty_points do
      points_amount { 250 }
      multiplier { 2.0 }
      config { { 'title' => 'Loyalty Points' } }
    end
  end
end
