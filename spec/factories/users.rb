# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    password { "password123" }
    password_confirmation { "password123" }
    role { :admin }

    # Role-specific factories
    factory :admin_user_model, traits: [:admin_role]
    factory :promo_manager_user, traits: [:promo_manager_role]
    factory :shift_leader_user, traits: [:shift_leader_role]
    factory :support_agent_user, traits: [:support_agent_role]
    factory :marketing_manager_user, traits: [:marketing_manager_role]

    # Traits for different roles
    trait :admin_role do
      role { :admin }
    end

    trait :promo_manager_role do
      role { :promo_manager }
    end

    trait :shift_leader_role do
      role { :shift_leader }
    end

    trait :support_agent_role do
      role { :support_agent }
    end

    trait :marketing_manager_role do
      role { :marketing_manager }
    end
  end
end
