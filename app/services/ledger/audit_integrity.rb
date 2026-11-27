module Ledger
  class AuditIntegrity
    Report = Data.define(:passed, :checked_accounts, :checked_transactions, :currency_equations, :anomalies)

    def self.call
      new.call
    end

    def call
      anomalies = []

      # 1. Verify every account balance equals the exact sum of its immutable ledger entries
      accounts = Account.all.to_a
      accounts.each do |account|
        debits = account.ledger_entries.where(entry_type: "debit").sum(:amount_cents)
        credits = account.ledger_entries.where(entry_type: "credit").sum(:amount_cents)
        expected = account.debit_normal? ? (debits - credits) : (credits - debits)

        if expected != account.balance_cents
          anomalies << "Balance drift on #{account.account_number}: stored=#{account.balance_cents}, computed=#{expected}"
        end
      end

      # 2. Verify every transaction obeys sum(debits) == sum(credits)
      txns = LedgerTransaction.includes(:ledger_entries).all.to_a
      txns.each do |txn|
        debits = txn.ledger_entries.select { |e| e.entry_type == "debit" }.sum(&:amount_cents)
        credits = txn.ledger_entries.select { |e| e.entry_type == "credit" }.sum(&:amount_cents)
        if debits != credits || debits.zero?
          anomalies << "Unbalanced transaction #{txn.reference}: debits=#{debits}, credits=#{credits}"
        end
      end

      # 3. Verify global accounting equation per currency: Assets + Expenses == Liabilities + Equity + Revenue
      currency_equations = {}
      accounts.group_by(&:currency).each do |currency, curr_accounts|
        left_side = curr_accounts.select(&:debit_normal?).sum(&:balance_cents)
        right_side = curr_accounts.select(&:credit_normal?).sum(&:balance_cents)
        balanced = (left_side == right_side)
        currency_equations[currency] = {
          debit_normal_cents: left_side,
          credit_normal_cents: right_side,
          balanced: balanced
        }
        anomalies << "Global equation imbalance in #{currency}: #{left_side} != #{right_side}" unless balanced
      end

      Report.new(
        passed: anomalies.empty?,
        checked_accounts: accounts.size,
        checked_transactions: txns.size,
        currency_equations: currency_equations,
        anomalies: anomalies
      )
    end
  end
end
