FactoryBot.define do
  factory :permanent_bonus do
    project { "Test Project" }
    association :bonus
  end
end
