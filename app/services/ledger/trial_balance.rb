module Ledger
  class TrialBalance
    Row = Data.define(:account, :debit_cents, :credit_cents, :balance_cents)
    Report = Data.define(:currency, :rows, :total_debit_cents, :total_credit_cents, :balanced)

    def self.call(currency: "USD")
      new(currency: currency).call
    end

    def initialize(currency: "USD")
      @currency = currency.to_s.upcase
    end

    def call
      accounts = Account.by_currency(@currency).order(:account_type, :id)
      grouped_totals = LedgerEntry.joins(:account)
                                  .where(accounts: { currency: @currency })
                                  .group(:account_id, :entry_type)
                                  .sum(:amount_cents)

      rows = accounts.map do |account|
        debits = grouped_totals.fetch([ account.id, "debit" ], 0)
        credits = grouped_totals.fetch([ account.id, "credit" ], 0)
        Row.new(
          account: account,
          debit_cents: debits,
          credit_cents: credits,
          balance_cents: account.balance_cents
        )
      end

      total_debits = rows.sum(&:debit_cents)
      total_credits = rows.sum(&:credit_cents)

      Report.new(
        currency: @currency,
        rows: rows,
        total_debit_cents: total_debits,
        total_credit_cents: total_credits,
        balanced: total_debits == total_credits
      )
    end
  end
end
