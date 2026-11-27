class CreateLedgerTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_transactions do |t|
      t.string :reference, null: false
      t.string :description, null: false
      t.string :currency, null: false, default: "USD"
      t.json :metadata, null: false, default: {}
      t.references :reverses_transaction, foreign_key: { to_table: :ledger_transactions },
                   index: { unique: true, where: "reverses_transaction_id IS NOT NULL" }

      t.timestamps
    end

    add_index :ledger_transactions, :reference, unique: true
  end
end
