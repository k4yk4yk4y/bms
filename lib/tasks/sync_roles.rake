namespace :roles do
  desc "Sync frontend roles and permissions with current definitions"
  task sync: :environment do
    User.roles.keys.each do |key|
      role = Role.find_or_initialize_by(key: key)
      role.name ||= key.tr("_", " ").split.map(&:capitalize).join(" ")
      role.permissions = Role.normalize_permissions_hash(role.permissions.presence || Role.default_permissions_for(key))
      role.save!
    end

    Role.find_each do |role|
      normalized = Role.normalize_permissions_hash(role.permissions)
      next if normalized == role.permissions

      role.update!(permissions: normalized)
    end

    puts "Frontend roles synced."
  end
end

namespace :admin_roles do
  desc "Sync admin roles and permissions with current definitions"
  task sync: :environment do
    AdminRole.find_each do |role|
      normalized = AdminRole.normalize_permissions_hash(role.permissions)
      next if normalized == role.permissions

      role.update!(permissions: normalized)
    end

    puts "Admin roles synced."
  end
end
