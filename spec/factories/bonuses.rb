# frozen_string_literal: true

FactoryBot.define do
  factory :bonus do
    transient do
      dsl_tag_string { nil } # Allow setting dsl_tag string via transient attribute
    end

    name { Faker::Commerce.product_name }
    code { "BONUS_#{Faker::Alphanumeric.alpha(number: 8).upcase}" }
    event { 'deposit' } # Default to deposit event to avoid validation issues
    status { 'active' }
    availability_start_date { 1.day.ago }
    availability_end_date { 1.month.from_now }
    currencies { %w[USD EUR RUB] }
    minimum_deposit { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    wager { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    maximum_winnings { Faker::Number.decimal(l_digits: 3, r_digits: 2) }
    wagering_strategy { %w[bonus_first deposit_first].sample }
    user_group { Faker::Company.name }
    tags { "#{Faker::Lorem.word}, #{Faker::Lorem.word}" }
    country { Faker::Address.country_code }
    project { %w[VOLNA ROX FRESH SOL JET].sample }
    description { Faker::Lorem.paragraph }
    groups { [ user_group ] }

    after(:build) do |bonus, evaluator|
      bonus.currency_minimum_deposits ||= bonus.currencies.index_with { |_| bonus.minimum_deposit || 0.0 }
      # Set dsl_tag string attribute directly to bypass the association setter
      # Only set if dsl_tag_string is provided and dsl_tag_id is not already set (via association)
      if evaluator.dsl_tag_string.present? && bonus.dsl_tag_id.nil?
        bonus.write_attribute(:dsl_tag, evaluator.dsl_tag_string)
      elsif bonus.dsl_tag_id.nil? && bonus.read_attribute(:dsl_tag).blank?
        # Default value only if neither association nor string is set
        bonus.write_attribute(:dsl_tag, %w[welcome_bonus reload_cash birthday cashback].sample)
      end
    end

    trait :draft do
      status { 'draft' }
    end

    trait :active do
      status { 'active' }
    end

    trait :inactive do
      status { 'inactive' }
    end

    trait :expired do
      status { 'expired' }
      availability_start_date { 2.days.ago }
      availability_end_date { 1.day.ago }
    end

    trait :deposit_event do
      event { 'deposit' }
      minimum_deposit { 50.0 }
    end

    trait :input_coupon_event do
      event { 'input_coupon' }
      minimum_deposit { nil }
      currency_minimum_deposits { {} }
    end

    trait :manual_event do
      event { 'manual' }
      minimum_deposit { nil }
      currency_minimum_deposits { {} }
    end

    trait :collection_event do
      event { 'collection' }
      minimum_deposit { nil }
      currency_minimum_deposits { {} }
    end

    trait :groups_update_event do
      event { 'groups_update' }
      minimum_deposit { nil }
      currency_minimum_deposits { {} }
    end

    trait :scheduler_event do
      event { 'scheduler' }
      minimum_deposit { nil }
      currency_minimum_deposits { {} }
    end

    trait :with_multiple_currencies do
      currencies { %w[USD EUR RUB] }
      currency_minimum_deposits { { 'USD' => 50.0, 'EUR' => 45.0, 'RUB' => 3000.0 } }
    end

    trait :with_usd_only do
      currencies { [ 'USD' ] }
      currency_minimum_deposits { { 'USD' => minimum_deposit } }
    end

    trait :with_multiple_groups do
      groups { %w[VIP Regular Premium] }
    end

    trait :permanent do
      status { 'active' }
      after(:build) do |bonus|
        bonus.write_attribute(:dsl_tag, %w[welcome_bonus reload_cash birthday cashback].sample)
      end
    end

    trait :available_now do
      availability_start_date { 1.hour.ago }
      availability_end_date { 1.hour.from_now }
      status { 'active' }
    end

    trait :future do
      availability_start_date { 1.day.from_now }
      availability_end_date { 1.week.from_now }
    end

    trait :past do
      availability_start_date { 1.week.ago }
      availability_end_date { 1.day.ago }
    end

    # Reward association traits
    trait :with_bonus_rewards do
      after(:create) do |bonus|
        create(:bonus_reward, bonus: bonus)
      end
    end

    trait :with_freespin_rewards do
      after(:create) do |bonus|
        create(:freespin_reward, bonus: bonus)
      end
    end

    trait :with_bonus_buy_rewards do
      after(:create) do |bonus|
        create(:bonus_buy_reward, bonus: bonus)
      end
    end

    trait :with_comp_point_rewards do
      after(:create) do |bonus|
        create(:comp_point_reward, bonus: bonus)
      end
    end

    trait :with_bonus_code_rewards do
      after(:create) do |bonus|
        create(:bonus_code_reward, bonus: bonus)
      end
    end

    trait :with_freechip_rewards do
      after(:create) do |bonus|
        create(:freechip_reward, bonus: bonus)
      end
    end

    trait :with_material_prize_rewards do
      after(:create) do |bonus|
        create(:material_prize_reward, bonus: bonus)
      end
    end

    trait :with_all_reward_types do
      after(:create) do |bonus|
        create(:bonus_reward, bonus: bonus)
        create(:freespin_reward, bonus: bonus)
        create(:bonus_buy_reward, bonus: bonus)
        create(:comp_point_reward, bonus: bonus)
        create(:bonus_code_reward, bonus: bonus)
        create(:freechip_reward, bonus: bonus)
        create(:material_prize_reward, bonus: bonus)
      end
    end

    trait :with_multiple_bonus_rewards do
      after(:create) do |bonus|
        create_list(:bonus_reward, 3, bonus: bonus)
      end
    end

    trait :with_multiple_freespin_rewards do
      after(:create) do |bonus|
        create_list(:freespin_reward, 2, bonus: bonus)
      end
    end
  end
end
