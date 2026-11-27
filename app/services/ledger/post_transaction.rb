module Ledger
  class PostTransaction
    # entries: Array of hashes { account_id:, entry_type: ("debit"|"credit"), amount_cents: Integer }
    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(description:, entries:, currency: "USD", reference: nil, metadata: {}, reverses_transaction: nil)
      @description = description
      @entries = entries
      @currency = currency.to_s.upcase
      @reference = reference
      @metadata = metadata || {}
      @reverses_transaction = reverses_transaction
    end

    def call
      validate_entries_structure!

      ActiveRecord::Base.transaction do
        # Lock accounts in ascending ID order to prevent database deadlocks under concurrent transfers.
        account_ids = @entries.map { |e| e.fetch(:account_id).to_i }.uniq.sort
        locked_accounts = Account.where(id: account_ids).order(:id).lock.index_by(&:id)

        if locked_accounts.size != account_ids.size
          raise LedgerErrors::InvalidTransaction, "One or more accounts do not exist."
        end

        validate_currencies!(locked_accounts.values)

        txn = LedgerTransaction.create!(
          reference: @reference,
          description: @description,
          currency: @currency,
          metadata: @metadata,
          reverses_transaction: @reverses_transaction
        )

        running_balances = locked_accounts.transform_values(&:balance_cents)

        @entries.each do |leg|
          account = locked_accounts.fetch(leg.fetch(:account_id).to_i)
          entry_type = leg.fetch(:entry_type).to_s
          amount_cents = leg.fetch(:amount_cents)

          delta = account.signed_delta(entry_type, amount_cents)
          new_balance = running_balances[account.id] + delta
          running_balances[account.id] = new_balance

          LedgerEntry.create!(
            ledger_transaction: txn,
            account: account,
            entry_type: entry_type,
            amount_cents: amount_cents,
            balance_after_cents: new_balance
          )
        end

        locked_accounts.each do |id, account|
          final_balance = running_balances[id]
          if !account.allow_negative? && final_balance.negative?
            raise LedgerErrors::InsufficientFunds,
                  "Account #{account.account_number} (#{account.name}) has insufficient funds."
          end

          account.update!(balance_cents: final_balance)
        end

        txn
      end
    end

    private

    def validate_entries_structure!
      raise LedgerErrors::InvalidTransaction, "A transaction requires at least 2 ledger entries." if @entries.blank? || @entries.size < 2

      total_debits = 0
      total_credits = 0

      @entries.each do |leg|
        amount = leg[:amount_cents]
        unless amount.is_a?(Integer) && amount.positive?
          raise LedgerErrors::InvalidAmount, "Entry amount_cents must be a positive Integer."
        end

        case leg[:entry_type].to_s
        when "debit"  then total_debits += amount
        when "credit" then total_credits += amount
        else raise LedgerErrors::InvalidTransaction, "Invalid entry_type: #{leg[:entry_type]}"
        end
      end

      return if total_debits == total_credits

      raise LedgerErrors::UnbalancedTransaction,
            "Double-entry invariant violated: debits (#{total_debits}) != credits (#{total_credits})"
    end

    def validate_currencies!(accounts)
      mismatched = accounts.find { |a| a.currency != @currency }
      return unless mismatched

      raise LedgerErrors::CurrencyMismatch,
            "Account #{mismatched.account_number} currency (#{mismatched.currency}) does not match transaction currency (#{@currency})."
    end
  end
end
