class CreateLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_entries do |t|
      t.references :ledger_transaction, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.integer :amount_cents, null: false
      t.integer :balance_after_cents, null: false

      t.timestamps
    end

    add_index :ledger_entries, [ :account_id, :created_at ]
    add_check_constraint :ledger_entries, "entry_type IN ('debit', 'credit')", name: "ledger_entries_type_valid"
    add_check_constraint :ledger_entries, "amount_cents > 0", name: "ledger_entries_amount_positive"
  end
end
