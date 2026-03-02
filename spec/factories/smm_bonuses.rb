FactoryBot.define do
  factory :smm_bonus do
    association :smm_month_project
    association :manager, factory: :user

    status { "draft" }
    sequence(:code) { |n| "SMM_CODE_#{n}" }
    deposit { "100" }
    activation_limit { 100 }
    game { "book_of_dead" }
    fs_count { 20 }
    bet_value { "1" }
    wager_multiplier { 20 }
    max_win_multiplier { 100 }
    group { "general" }
    bonus_type { "freespins" }
    subject { "SMM Subject" }
    locale { "en" }
    currencies { %w[USD] }

    after(:build) do |smm_bonus|
      smm_bonus.smm_preset ||= build(:smm_preset, project: smm_bonus.smm_month_project.project, manager: smm_bonus.manager)
    end
  end
end
