require "csv"

module Ledger
  class ExportStatement
    HEADERS = %w[Timestamp Reference Description EntryType Amount BalanceAfter Currency].freeze

    def self.call(account:)
      new(account: account).call
    end

    def initialize(account:)
      @account = account
    end

    def call
      entries = @account.ledger_entries.includes(:ledger_transaction).order(:id)

      CSV.generate(headers: true) do |csv|
        csv << HEADERS
        entries.each do |entry|
          csv << [
            entry.created_at.utc.iso8601,
            entry.ledger_transaction.reference,
            entry.ledger_transaction.description,
            entry.entry_type.upcase,
            entry.amount.formatted,
            entry.balance_after.formatted,
            @account.currency
          ]
        end
      end
    end
  end
end
