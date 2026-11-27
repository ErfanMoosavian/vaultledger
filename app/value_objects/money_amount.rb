class MoneyAmount
  include Comparable

  SYMBOLS = { "USD" => "$", "EUR" => "€", "GBP" => "£" }.freeze
  PERSIAN_DIGITS = "۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩".freeze
  ASCII_DIGITS   = "01234567890123456789".freeze

  attr_reader :cents, :currency

  def initialize(cents, currency = "USD")
    raise LedgerErrors::InvalidAmount, "Money must be an Integer in cents, not #{cents.class}" unless cents.is_a?(Integer)

    @cents = cents
    @currency = currency.to_s.upcase.freeze
    freeze
  end

  def self.from_major(value, currency = "USD")
    raise LedgerErrors::InvalidAmount, "Pass String or BigDecimal, never Float" if value.is_a?(Float)

    normalized = value.to_s.strip.tr(PERSIAN_DIGITS, ASCII_DIGITS).delete(",")
    decimal = BigDecimal(normalized)
    new((decimal * 100).round.to_i, currency)
  rescue ArgumentError
    raise LedgerErrors::InvalidAmount, "Invalid monetary value: #{value}"
  end

  def +(other)
    ensure_same_currency!(other)
    self.class.new(cents + other.cents, currency)
  end

  def -(other)
    ensure_same_currency!(other)
    self.class.new(cents - other.cents, currency)
  end

  def <=>(other)
    return nil unless other.is_a?(self.class) && currency == other.currency

    cents <=> other.cents
  end

  def positive? = cents.positive?
  def zero? = cents.zero?
  def negative? = cents.negative?

  def formatted
    sign = negative? ? "-" : ""
    abs_cents = cents.abs
    whole = abs_cents / 100
    frac = format("%02d", abs_cents % 100)
    formatted_whole = whole.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    symbol = SYMBOLS[currency]
    symbol ? "#{sign}#{symbol}#{formatted_whole}.#{frac}" : "#{sign}#{formatted_whole}.#{frac} #{currency}"
  end

  def to_s = formatted

  private

  def ensure_same_currency!(other)
    raise LedgerErrors::CurrencyMismatch, "Cannot combine #{currency} and #{other.currency}" unless currency == other.currency
  end
end
