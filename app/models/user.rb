class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Define user roles using enum
  enum :role, {
    admin: 0,
    promo_manager: 1,
    shift_leader: 2,
    support_agent: 3
  }

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  # Callbacks
  before_validation :set_default_role, if: :new_record?

  # Scopes
  scope :admins, -> { where(role: :admin) }
  scope :promo_managers, -> { where(role: :promo_manager) }
  scope :shift_leaders, -> { where(role: :shift_leader) }
  scope :support_agents, -> { where(role: :support_agent) }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "first_name", "id", "last_name", "remember_created_at", "reset_password_sent_at", "role", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  # Role helper methods
  def display_role
    role.humanize
  end

  def can_manage_bonuses?
    admin? || promo_manager?
  end

  def can_view_marketing?
    admin? || promo_manager? || shift_leader?
  end

  def can_access_support?
    admin? || support_agent?
  end

  def can_access_admin?
    admin?
  end

  private

  def set_default_role
    self.role ||= :support_agent
  end
end
