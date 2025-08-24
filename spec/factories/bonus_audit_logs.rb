FactoryBot.define do
  factory :bonus_audit_log do
    bonus { nil }
    user { nil }
    action { "MyString" }
    changes_data { "MyText" }
    metadata { "MyText" }
  end
end
