module Ledger
  class ReverseTransaction
    def self.call(transaction:, reason: nil)
      raise LedgerErrors::AlreadyReversed, "Transaction #{transaction.reference} has already been reversed." if transaction.reversed?
      raise LedgerErrors::InvalidTransaction, "Cannot reverse a reversal transaction." if transaction.reversal?

      inverse_entries = transaction.ledger_entries.order(:id).map do |entry|
        {
          account_id: entry.account_id,
          entry_type: entry.entry_type == "debit" ? "credit" : "debit",
          amount_cents: entry.amount_cents
        }
      end

      PostTransaction.call(
        description: reason.presence || "Reversal of #{transaction.reference}: #{transaction.description}",
        currency: transaction.currency,
        entries: inverse_entries,
        reverses_transaction: transaction,
        metadata: { type: "reversal", reversed_reference: transaction.reference }
      )
    rescue ActiveRecord::RecordNotUnique
      raise LedgerErrors::AlreadyReversed, "Transaction #{transaction.reference} has already been reversed."
    end
  end
end
