# frozen_string_literal: true

FactoryBot.define do
  factory :freechip_reward do
    association :bonus
    chip_value { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    chips_count { Faker::Number.between(from: 1, to: 20) }
    config { {} }

    trait :low_value do
      chip_value { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
      chips_count { Faker::Number.between(from: 1, to: 5) }
    end

    trait :medium_value do
      chip_value { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
      chips_count { Faker::Number.between(from: 5, to: 10) }
    end

    trait :high_value do
      chip_value { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
      chips_count { Faker::Number.between(from: 10, to: 20) }
    end

    trait :single_chip do
      chips_count { 1 }
      chip_value { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    trait :multiple_chips do
      chips_count { Faker::Number.between(from: 5, to: 50) }
      chip_value { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    end

    trait :round_values do
      chip_value { [ 1.0, 5.0, 10.0, 25.0, 50.0, 100.0 ].sample }
      chips_count { [ 1, 2, 5, 10, 20 ].sample }
    end
  end
end
