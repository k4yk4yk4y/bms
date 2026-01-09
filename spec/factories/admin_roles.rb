FactoryBot.define do
  factory :admin_role do
    sequence(:key) { |n| "role_#{n}" }
    sequence(:name) { |n| "Role #{n}" }
    permissions do
      AdminRole.normalize_permissions_hash(AdminRole.section_keys.index_with { "manage" })
    end
  end
end
