FactoryBot.define do
  factory :admin_user do
    association :admin_role
    email { Faker::Internet.email }
    password { "password" }
    password_confirmation { "password" }
  end
end
