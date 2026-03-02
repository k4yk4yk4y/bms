FactoryBot.define do
  factory :retention_email do
    association :retention_chain
    sequence(:subject) { |n| "Retention Subject #{n}" }
    sequence(:header) { |n| "Retention Header #{n}" }
    preheader { "Retention preheader" }
    body { "Retention body content" }
    send_timing { "24h" }
    description { "Retention email description" }
    status { "draft" }
    launch_date { nil }
  end
end
