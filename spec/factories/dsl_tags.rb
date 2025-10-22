FactoryBot.define do
  factory :dsl_tag do
    sequence(:name) { |n| "DSL Tag #{n}" }
    description { "Description for #{name}" }
  end
end
