require "rails_helper"

RSpec.describe "Trial Balance & CSV Statement Export" do
  let!(:treasury) { Account.create!(name: "Treasury", account_type: "asset", currency: "USD") }
  let!(:alice)    { Account.create!(name: "Alice", account_type: "liability", currency: "USD") }

  before do
    Ledger::PostTransaction.call(
      description: "Wire funding",
      currency: "USD",
      entries: [
        { account_id: treasury.id, entry_type: "debit", amount_cents: 25_000 },
        { account_id: alice.id, entry_type: "credit", amount_cents: 25_000 }
      ]
    )
  end

  it "computes a balanced GAAP trial balance across accounts" do
    report = Ledger::TrialBalance.call(currency: "USD")
    expect(report.balanced).to be(true)
    expect(report.total_debit_cents).to eq(25_000)
    expect(report.total_credit_cents).to eq(25_000)
    expect(report.rows.size).to eq(2)
  end

  it "exports an RFC-4180 CSV account statement with running balances" do
    csv = Ledger::ExportStatement.call(account: alice)
    expect(csv).to include("Timestamp,Reference,Description,EntryType,Amount,BalanceAfter,Currency")
    expect(csv).to include("Wire funding,CREDIT,$250.00,$250.00,USD")
  end

  it "parses Persian digits safely in MoneyAmount without allowing Floats" do
    money = MoneyAmount.from_major("۱۲۵.۵۰", "USD")
    expect(money.cents).to eq(12_550)
    expect(money.formatted).to eq("$125.50")
  end
end
