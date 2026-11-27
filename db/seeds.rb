return if Account.exists?

treasury = Account.create!(name: "Platform Treasury", account_type: "asset", currency: "USD")
alice    = Account.create!(name: "Alice Wallet", account_type: "liability", currency: "USD")
bob      = Account.create!(name: "Bob Wallet", account_type: "liability", currency: "USD")
fees     = Account.create!(name: "Platform Fees", account_type: "revenue", currency: "USD")

Ledger::PostTransaction.call(
  description: "Initial wire deposit for Alice",
  currency: "USD",
  entries: [
    { account_id: treasury.id, entry_type: "debit", amount_cents: 50_000 },
    { account_id: alice.id, entry_type: "credit", amount_cents: 50_000 }
  ]
)

Ledger::Transfer.call(
  from_account: alice,
  to_account: bob,
  amount_cents: 12_500,
  fee_cents: 250,
  fee_account: fees,
  description: "Invoice #1042 settlement"
)
