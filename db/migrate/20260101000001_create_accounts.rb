class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :account_number, null: false
      t.string :account_type, null: false
      t.string :currency, null: false, default: "USD"
      t.integer :balance_cents, null: false, default: 0
      t.boolean :allow_negative, null: false, default: false

      t.timestamps
    end

    add_index :accounts, :account_number, unique: true
    add_index :accounts, [ :account_type, :currency ]
    add_check_constraint :accounts, "account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')", name: "accounts_type_valid"
    add_check_constraint :accounts, "allow_negative OR balance_cents >= 0", name: "accounts_balance_non_negative"
  end
end
