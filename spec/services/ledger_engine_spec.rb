require "rails_helper"

RSpec.describe "Double-Entry Ledger Engine" do
  let!(:treasury) { Account.create!(name: "Treasury", account_type: "asset", currency: "USD") }
  let!(:alice)    { Account.create!(name: "Alice", account_type: "liability", currency: "USD") }
  let!(:bob)      { Account.create!(name: "Bob", account_type: "liability", currency: "USD") }
  let!(:fees)     { Account.create!(name: "Fees", account_type: "revenue", currency: "USD") }

  def fund_alice(cents)
    Ledger::PostTransaction.call(
      description: "Deposit",
      currency: "USD",
      entries: [
        { account_id: treasury.id, entry_type: "debit", amount_cents: cents },
        { account_id: alice.id, entry_type: "credit", amount_cents: cents }
      ]
    )
  end

  it "rejects unbalanced transactions where debits != credits" do
    expect do
      Ledger::PostTransaction.call(
        description: "Broken entry",
        currency: "USD",
        entries: [
          { account_id: treasury.id, entry_type: "debit", amount_cents: 1000 },
          { account_id: alice.id, entry_type: "credit", amount_cents: 900 }
        ]
      )
    end.to raise_error(LedgerErrors::UnbalancedTransaction)
    expect(LedgerTransaction.count).to eq(0)
  end

  it "executes a 3-leg transfer with fee split and preserves the global accounting equation" do
    fund_alice(10_000)

    Ledger::Transfer.call(
      from_account: alice,
      to_account: bob,
      amount_cents: 4_000,
      fee_cents: 150,
      fee_account: fees
    )

    expect(treasury.reload.balance_cents).to eq(10_000)
    expect(alice.reload.balance_cents).to eq(6_000)
    expect(bob.reload.balance_cents).to eq(3_850)
    expect(fees.reload.balance_cents).to eq(150)

    report = Ledger::AuditIntegrity.call
    expect(report.passed).to be(true)
    expect(report.currency_equations["USD"][:balanced]).to be(true)
  end

  it "atomically rolls back on insufficient funds without leaving partial entries" do
    fund_alice(500)

    expect do
      Ledger::Transfer.call(from_account: alice, to_account: bob, amount_cents: 1_000)
    end.to raise_error(LedgerErrors::InsufficientFunds)

    expect(alice.reload.balance_cents).to eq(500)
    expect(bob.reload.balance_cents).to eq(0)
    expect(LedgerTransaction.count).to eq(1)
  end

  it "enforces strict immutability on posted transactions and entries" do
    txn = fund_alice(2_000)
    entry = txn.ledger_entries.first

    expect { txn.update!(description: "Tampered") }.to raise_error(LedgerErrors::ImmutableRecord)
    expect { txn.destroy! }.to raise_error(LedgerErrors::ImmutableRecord)
    expect { entry.update!(amount_cents: 1) }.to raise_error(LedgerErrors::ImmutableRecord)
    expect { entry.destroy! }.to raise_error(LedgerErrors::ImmutableRecord)
  end

  it "reverses a transaction accurately and blocks duplicate reversals" do
    fund_alice(5_000)
    transfer = Ledger::Transfer.call(from_account: alice, to_account: bob, amount_cents: 2_000, fee_cents: 100, fee_account: fees)

    reversal = Ledger::ReverseTransaction.call(transaction: transfer, reason: "Customer refund")
    expect(reversal.reverses_transaction).to eq(transfer)
    expect(alice.reload.balance_cents).to eq(5_000)
    expect(bob.reload.balance_cents).to eq(0)
    expect(fees.reload.balance_cents).to eq(0)
    expect(Ledger::AuditIntegrity.call.passed).to be(true)

    expect do
      Ledger::ReverseTransaction.call(transaction: transfer)
    end.to raise_error(LedgerErrors::AlreadyReversed)
  end

  it "detects manual balance drift via AuditIntegrity" do
    fund_alice(3_000)
    alice.update_column(:balance_cents, 9_999) # Simulate out-of-band DB corruption

    report = Ledger::AuditIntegrity.call
    expect(report.passed).to be(false)
    expect(report.anomalies.join).to include("Balance drift")
  end
end
