module CurrencyManagement
  extend ActiveSupport::Concern

  module ClassMethods
    # Фиатные валюты (2 знака после запятой)
    def fiat_currencies
      %w[RUB EUR USD UAH KZT NOK PLN TRY CAD AUD AZN NZD BRL INR ARS MXN PEN NGN ZAR CLP DKK SEK RON HUF JPY UZS GBP]
    end

    # Криптовалюты (до 8 знаков после запятой)
    def crypto_currencies
      %w[BTC ETH LTC BCH XRP TRX DOGE USDT]
    end

    # Все поддерживаемые валюты
    def all_currencies
      fiat_currencies + crypto_currencies
    end

    # Проверка, является ли валюта криптовалютой
    def crypto_currency?(currency)
      crypto_currencies.include?(currency.to_s.upcase)
    end

    # Проверка, является ли валюта фиатной
    def fiat_currency?(currency)
      fiat_currencies.include?(currency.to_s.upcase)
    end

    # Получить precision для валюты
    def currency_precision(currency)
      crypto_currency?(currency) ? 8 : 2
    end

    # Получить step для input поля
    def currency_step(currency)
      crypto_currency?(currency) ? 0.00000001 : 0.01
    end

    # Валидация суммы для определенной валюты
    def valid_amount_for_currency?(amount, currency)
      return true if amount.nil?

      precision = currency_precision(currency)
      # Проверяем количество знаков после запятой
      decimal_places = amount.to_s.split(".").last.length rescue 0
      decimal_places <= precision
    end
  end

  included do
    # Валидация валют (только для моделей с колонкой currencies)
    validate :validate_supported_currencies, if: :should_validate_currencies?

    private

    def should_validate_currencies?
      respond_to?(:currencies_changed?) && currencies_changed?
    end

    def validate_supported_currencies
      return unless currencies.present?

      invalid_currencies = currencies - self.class.all_currencies
      if invalid_currencies.any?
        errors.add(:currencies, "contains unsupported currencies: #{invalid_currencies.join(', ')}")
      end
    end
  end

  # Форматирование суммы с учетом типа валюты
  def format_amount_for_currency(amount, currency)
    return "0" if amount.nil? || amount.zero?

    precision = self.class.currency_precision(currency)
    formatted = sprintf("%.#{precision}f", amount)

    # Убираем лишние нули для криптовалют
    if self.class.crypto_currency?(currency)
      formatted = formatted.sub(/\.?0+$/, "")
    end

    "#{formatted} #{currency}"
  end
end
