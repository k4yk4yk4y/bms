FactoryBot.define do
  factory :permanent_bonus do
    association :project
    association :bonus
  end
end
