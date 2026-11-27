class Account < ApplicationRecord
  TYPES = %w[asset liability equity revenue expense].freeze
  DEBIT_NORMAL_TYPES = %w[asset expense].freeze
  SUPPORTED_CURRENCIES = %w[USD EUR GBP].freeze

  has_many :ledger_entries, dependent: :restrict_with_exception

  validates :name, presence: true, length: { maximum: 100 }
  validates :account_number, presence: true, uniqueness: true
  validates :account_type, presence: true, inclusion: { in: TYPES }
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
  validates :balance_cents, numericality: { only_integer: true }

  before_validation :assign_defaults, on: :create

  scope :by_currency, ->(curr) { where(currency: curr.to_s.upcase) }

  def debit_normal?
    DEBIT_NORMAL_TYPES.include?(account_type)
  end

  def credit_normal?
    !debit_normal?
  end

  def balance
    MoneyAmount.new(balance_cents, currency)
  end

  def signed_delta(entry_type, amount_cents)
    case entry_type.to_s
    when "debit"  then debit_normal? ? amount_cents : -amount_cents
    when "credit" then credit_normal? ? amount_cents : -amount_cents
    else raise LedgerErrors::InvalidTransaction, "Unknown entry type: #{entry_type}"
    end
  end

  private

  def assign_defaults
    self.currency = currency.to_s.upcase.presence || "USD"
    return if account_number.present?

    prefix = account_type.to_s[0..2].upcase.presence || "ACC"
    loop do
      candidate = "#{prefix}-#{SecureRandom.hex(4).upcase}"
      unless Account.exists?(account_number: candidate)
        self.account_number = candidate
        break
      end
    end
  end
end
