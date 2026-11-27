class LedgerTransaction < ApplicationRecord
  has_many :ledger_entries, dependent: :restrict_with_exception
  belongs_to :reverses_transaction, class_name: "LedgerTransaction", optional: true
  has_one :reversal_transaction, class_name: "LedgerTransaction", foreign_key: :reverses_transaction_id, dependent: :restrict_with_exception

  validates :reference, presence: true, uniqueness: true
  validates :description, presence: true
  validates :currency, presence: true, inclusion: { in: Account::SUPPORTED_CURRENCIES }

  before_validation :assign_reference, on: :create
  before_update :prevent_mutation!
  before_destroy :prevent_mutation!, prepend: true

  def delete
    prevent_mutation!
  end

  def reversed?
    reversal_transaction.present?
  end

  def reversal?
    reverses_transaction_id.present?
  end

  def total_volume_cents
    ledger_entries.where(entry_type: "debit").sum(:amount_cents)
  end

  def total_volume
    MoneyAmount.new(total_volume_cents, currency)
  end

  private

  def assign_reference
    self.reference ||= "TXN-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def prevent_mutation!
    raise LedgerErrors::ImmutableRecord, "Ledger transactions are immutable; post a reversal transaction instead."
  end
end
