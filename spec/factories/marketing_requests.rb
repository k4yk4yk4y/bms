# frozen_string_literal: true

FactoryBot.define do
  factory :marketing_request do
    manager { Faker::Internet.email }
    platform { Faker::Internet.domain_name }
    partner_email { Faker::Internet.email }
    promo_code { "PROMO#{Faker::Alphanumeric.alpha(number: 6).upcase}" }
    stag { "STAG#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    status { 'pending' }
    request_type { MarketingRequest::REQUEST_TYPES.sample }
    activation_date { nil }

    trait :pending do
      status { 'pending' }
      activation_date { nil }
    end

    trait :activated do
      status { 'activated' }
      activation_date { Faker::Time.between(from: 1.week.ago, to: Time.current) }
    end

    trait :rejected do
      status { 'rejected' }
      activation_date { nil }
    end

    trait :promo_webs_50 do
      request_type { 'promo_webs_50' }
    end

    trait :promo_webs_100 do
      request_type { 'promo_webs_100' }
    end

    trait :promo_no_link_50 do
      request_type { 'promo_no_link_50' }
    end

    trait :promo_no_link_100 do
      request_type { 'promo_no_link_100' }
    end

    trait :promo_no_link_125 do
      request_type { 'promo_no_link_125' }
    end

    trait :promo_no_link_150 do
      request_type { 'promo_no_link_150' }
    end

    trait :deposit_bonuses_partners do
      request_type { 'deposit_bonuses_partners' }
    end

    trait :with_multiple_promo_codes do
      promo_code { "PROMO1#{Faker::Alphanumeric.alpha(number: 4).upcase}, PROMO2#{Faker::Alphanumeric.alpha(number: 4).upcase}, PROMO3#{Faker::Alphanumeric.alpha(number: 4).upcase}" }
    end

    trait :with_platform_details do
      platform { "#{Faker::Internet.domain_name} - #{Faker::Company.name}" }
    end

    trait :with_long_stag do
      stag { "STAG#{Faker::Alphanumeric.alpha(number: 15).upcase}" }
    end

    trait :with_short_stag do
      stag { "ST#{Faker::Alphanumeric.alpha(number: 3).upcase}" }
    end

    trait :recently_activated do
      status { 'activated' }
      activation_date { 1.day.ago }
    end

    trait :old_activation do
      status { 'activated' }
      activation_date { 1.month.ago }
    end

    trait :with_special_characters_removed do
      # Эта фабрика тестирует callback нормализации
      promo_code { "test code, with spaces" }
      stag { "test stag with spaces" }
    end

    trait :duplicate_stag do
      # Для тестирования валидации уникальности
      stag { 'DUPLICATE_STAG' }
    end

    trait :duplicate_promo_code do
      # Для тестирования валидации уникальности
      promo_code { 'DUPLICATE_CODE' }
    end

    trait :invalid_email do
      partner_email { 'invalid-email' }
    end

    trait :empty_promo_code do
      promo_code { '' }
    end

    trait :empty_stag do
      stag { '' }
    end

    trait :valid_data do
      manager { 'manager@example.com' }
      platform { 'example.com' }
      partner_email { 'partner@example.com' }
      promo_code { 'VALIDCODE123' }
      stag { 'VALIDSTAG123' }
      request_type { 'promo_webs_50' }
    end



    trait :with_unique_stag do
      stag { "UNIQUE_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    end

    trait :with_unique_promo_code do
      promo_code { "UNIQUE_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    end

    trait :complete_valid_request do
      with_unique_stag
      with_unique_promo_code
      valid_data
    end
  end
end
