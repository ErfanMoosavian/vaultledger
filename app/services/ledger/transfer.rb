module Ledger
  class Transfer
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(from_account:, to_account:, amount_cents:, description: nil, fee_cents: 0, fee_account: nil, metadata: {})
      @from_account = from_account
      @to_account = to_account
      @amount_cents = amount_cents
      @description = description
      @fee_cents = fee_cents.to_i
      @fee_account = fee_account
      @metadata = metadata
    end

    def call
      raise LedgerErrors::InvalidTransaction, "Source and destination accounts must differ." if @from_account.id == @to_account.id
      raise LedgerErrors::InvalidAmount, "Transfer amount must be positive." unless @amount_cents.is_a?(Integer) && @amount_cents.positive?
      raise LedgerErrors::InvalidAmount, "Fee cannot be negative or exceed transfer amount." if @fee_cents.negative? || @fee_cents >= @amount_cents
      raise LedgerErrors::InvalidTransaction, "Fee account is required when fee_cents > 0." if @fee_cents.positive? && @fee_account.nil?

      net_to_recipient = @amount_cents - @fee_cents

      # Customer wallets are Liability accounts:
      # Debit reduces sender balance, Credit increases recipient balance and fee revenue.
      entries = [
        { account_id: @from_account.id, entry_type: "debit", amount_cents: @amount_cents },
        { account_id: @to_account.id, entry_type: "credit", amount_cents: net_to_recipient }
      ]

      if @fee_cents.positive?
        entries << { account_id: @fee_account.id, entry_type: "credit", amount_cents: @fee_cents }
      end

      PostTransaction.call(
        description: @description.presence || "Transfer from #{@from_account.name} to #{@to_account.name}",
        currency: @from_account.currency,
        entries: entries,
        metadata: @metadata.merge(
          type: "transfer",
          gross_amount_cents: @amount_cents,
          fee_cents: @fee_cents,
          net_amount_cents: net_to_recipient
        )
      )
    end
  end
end
