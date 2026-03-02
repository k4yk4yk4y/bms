FactoryBot.define do
  factory :smm_month do
    sequence(:name) { |n| "SMM Month #{n}" }
    starts_on { Date.current.beginning_of_month }
  end
end
