FactoryBot.define do
  factory :retention_chain do
    sequence(:name) { |n| "Retention Chain #{n}" }
    association :project
    status { "draft" }
    launch_date { nil }
  end
end
