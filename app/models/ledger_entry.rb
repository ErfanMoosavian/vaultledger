class LedgerEntry < ApplicationRecord
  ENTRY_TYPES = %w[debit credit].freeze

  belongs_to :ledger_transaction
  belongs_to :account

  validates :entry_type, presence: true, inclusion: { in: ENTRY_TYPES }
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :balance_after_cents, presence: true, numericality: { only_integer: true }

  before_update :prevent_mutation!
  before_destroy :prevent_mutation!

  def delete
    prevent_mutation!
  end

  def amount
    MoneyAmount.new(amount_cents, account.currency)
  end

  def balance_after
    MoneyAmount.new(balance_after_cents, account.currency)
  end

  private

  def prevent_mutation!
    raise LedgerErrors::ImmutableRecord, "Ledger entries are strictly immutable."
  end
end
