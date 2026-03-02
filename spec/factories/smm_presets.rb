FactoryBot.define do
  factory :smm_preset do
    association :project
    association :manager, factory: :user

    sequence(:name) { |n| "Preset #{n}" }
    subject { "Weekly SMM campaign" }
    bonus_type { "freespins" }
    activation_limit { 100 }
    fs_count { 25 }
    wager_multiplier { 30 }
    max_win_multiplier { 200 }
    locale { "en" }
    group { "general" }
    currencies { %w[USD EUR] }
  end
end
