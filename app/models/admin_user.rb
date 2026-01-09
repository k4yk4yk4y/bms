class AdminUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  belongs_to :admin_role, optional: true
  validates :admin_role, presence: true

  before_validation :set_default_admin_role, if: :new_record?
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email", "id", "remember_created_at", "reset_password_sent_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "admin_role" ]
  end

  private

  def set_default_admin_role
    return if admin_role.present?

    self.admin_role = AdminRole.find_by(key: "superadmin")
  end
end
