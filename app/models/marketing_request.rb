class MarketingRequest < ApplicationRecord
  # Constants for status and request types
  STATUSES = %w[pending activated rejected].freeze
  REQUEST_TYPES = [
    "promo_webs_50",
    "promo_webs_100",
    "promo_no_link_50",
    "promo_no_link_100",
    "promo_no_link_125",
    "promo_no_link_150",
    "deposit_bonuses_partners"
  ].freeze

  REQUEST_TYPE_LABELS = {
    "promo_webs_50" => "ПРОМО ВЕБОВ 50",
    "promo_webs_100" => "ПРОМО ВЕБОВ 100",
    "promo_no_link_50" => "ПРОМО БЕЗ ССЫЛКИ 50",
    "promo_no_link_100" => "ПРОМО БЕЗ ССЫЛКИ 100",
    "promo_no_link_125" => "ПРОМО БЕЗ ССЫЛКИ 125",
    "promo_no_link_150" => "ПРОМО БЕЗ ССЫЛКИ 150",
    "deposit_bonuses_partners" => "ДЕПОЗИТНЫЕ БОНУСЫ ОТ ПАРТНЁРОВ"
  }.freeze

  STATUS_LABELS = {
    "pending" => "Ожидает",
    "activated" => "Активирован",
    "rejected" => "Отклонён"
  }.freeze

  # Validations
  validates :manager, presence: true, length: { maximum: 255 }
  validates :platform, length: { maximum: 1000 }, allow_blank: true
  validates :partner_email, presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "должен быть валидным email" },
            length: { maximum: 255 }
  validates :promo_code, presence: true, length: { maximum: 2000 }
  validates :stag, presence: true, length: { maximum: 50 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :request_type, presence: true, inclusion: { in: REQUEST_TYPES }

  # Custom validations based on partner rules
  validate :stag_uniqueness_across_all_types
  validate :promo_codes_uniqueness_across_all_types
  validate :no_spaces_in_stag_and_codes
  validate :valid_promo_codes_format

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_request_type, ->(request_type) { where(request_type: request_type) }
  scope :pending, -> { where(status: "pending") }
  scope :activated, -> { where(status: "activated") }
  scope :rejected, -> { where(status: "rejected") }

  # Callbacks
  before_validation :normalize_promo_code_and_stag
  before_update :reset_to_pending_if_changed

  # Instance methods
  def status_label
    STATUS_LABELS[status] || status
  end

  def request_type_label
    REQUEST_TYPE_LABELS[request_type] || request_type
  end

  def pending?
    status == "pending"
  end

  def activated?
    status == "activated"
  end

  def rejected?
    status == "rejected"
  end

  def activate!
    update!(status: "activated", activation_date: Time.current)
  end

  def reject!
    update!(status: "rejected", activation_date: nil)
  end

  def reset_to_pending!
    update!(status: "pending", activation_date: nil)
  end

  # Methods for working with multiple promo codes
  def promo_codes_array
    return [] if promo_code.blank?
    promo_code.split(/[,\n\r]+/).map(&:strip).reject(&:blank?)
  end

  def promo_codes_array=(codes_array)
    if codes_array.is_a?(Array)
      self.promo_code = codes_array.compact.map(&:strip).reject(&:blank?).join(", ")
    elsif codes_array.is_a?(String)
      self.promo_code = codes_array
    end
  end

  def formatted_promo_codes
    codes = promo_codes_array
    return promo_code if codes.empty?
    codes.join(", ")
  end

  def first_promo_code
    promo_codes_array.first
  end

  # Check if this partner (stag) has other requests
  def existing_partner_request
    return nil if stag.blank?
    self.class.where(stag: stag).where.not(id: id).first
  end

  def has_existing_partner_request?
    existing_partner_request.present?
  end

  # Получение пользователя по email менеджера
  def user
    return nil if manager.blank?
    User.find_by(email: manager)
  end

  # Проверка, принадлежит ли заявка указанному пользователю
  def belongs_to_user?(user)
    return false if user.nil? || manager.blank?
    manager == user.email
  end

  private

  def normalize_promo_code_and_stag
    # Normalize promo codes - each code should be uppercase and trimmed
    if promo_code.present?
      normalized_codes = promo_code.split(/[,\n\r]+/).map(&:strip).reject(&:blank?).map(&:upcase)
      self.promo_code = normalized_codes.join(", ")
    end

    # Normalize stag - remove spaces and keep case sensitivity
    self.stag = stag&.strip&.gsub(/\s+/, "") if stag.present?
  end

  def reset_to_pending_if_changed
    # При любом редактировании заявки возвращаем в статус "Ожидает"
    # Исключение - изменение только статуса или activation_date
    changed_attrs = changed_attributes.keys - [ "status", "activation_date", "updated_at" ]

    if changed_attrs.any? && !pending?
      self.status = "pending"
      self.activation_date = nil
    end
  end

  # Partner rule validations
  def stag_uniqueness_across_all_types
    return if stag.blank?

    existing_request = self.class.where(stag: stag).where.not(id: id).first
    if existing_request
      errors.add(:stag, "уже используется в заявке типа \"#{existing_request.request_type_label}\" (ID: #{existing_request.id}). " \
                        "Согласно правилам, для одного партнера может быть только одна заявка. " \
                        "Удалите существующую заявку или измените STAG.")
    end
  end

  def promo_codes_uniqueness_across_all_types
    return if promo_code.blank?

    current_codes = promo_codes_array
    return if current_codes.empty?

    # Check each code for uniqueness across all requests
    current_codes.each do |code|
      # Find all requests that contain this code (excluding current request)
      # Use LIKE with UPPER for PostgreSQL compatibility
      conflicting_requests = self.class.where.not(id: id).where(
        "UPPER(promo_code) LIKE ?", "%#{code.upcase}%"
      ).select do |request|
        request.promo_codes_array.map(&:upcase).include?(code.upcase)
      end

      if conflicting_requests.any?
        conflicting_request = conflicting_requests.first
        errors.add(:promo_code, "содержит код \"#{code}\", который уже используется в заявке " \
                                "типа \"#{conflicting_request.request_type_label}\" (ID: #{conflicting_request.id})")
      end
    end
  end

  def no_spaces_in_stag_and_codes
    if stag.present? && stag.include?(" ")
      errors.add(:stag, "не должен содержать пробелы")
    end

    if promo_code.present?
      codes_with_spaces = promo_codes_array.select { |code| code.include?(" ") }
      if codes_with_spaces.any?
        errors.add(:promo_code, "содержит коды с пробелами: #{codes_with_spaces.join(', ')}")
      end
    end
  end

  def valid_promo_codes_format
    return if promo_code.blank?

    codes = promo_codes_array
    if codes.empty?
      errors.add(:promo_code, "должен содержать хотя бы один валидный код")
      return
    end

    # Check for valid code format (alphanumeric and underscores only)
    invalid_codes = codes.select { |code| code !~ /\A[A-Z0-9_]+\z/i }
    if invalid_codes.any?
      errors.add(:promo_code, "содержит коды с недопустимыми символами: #{invalid_codes.join(', ')}. " \
                              "Разрешены только буквы, цифры и подчеркивания.")
    end
  end
end
