# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_01_000004) do
  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_number", null: false
    t.string "account_type", null: false
    t.string "currency", default: "USD", null: false
    t.integer "balance_cents", default: 0, null: false
    t.boolean "allow_negative", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_accounts_on_account_number", unique: true
    t.index ["account_type", "currency"], name: "index_accounts_on_account_type_and_currency"
    t.check_constraint "account_type IN ('asset', 'liability', 'equity', 'revenue', 'expense')", name: "accounts_type_valid"
    t.check_constraint "allow_negative OR balance_cents >= 0", name: "accounts_balance_non_negative"
  end

  create_table "idempotency_records", force: :cascade do |t|
    t.string "idempotency_key", null: false
    t.string "request_path", null: false
    t.string "request_hash", null: false
    t.integer "response_status", null: false
    t.text "response_body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key", "request_path"], name: "idx_idempotency_key_path", unique: true
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.integer "ledger_transaction_id", null: false
    t.integer "account_id", null: false
    t.string "entry_type", null: false
    t.integer "amount_cents", null: false
    t.integer "balance_after_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_ledger_entries_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["ledger_transaction_id"], name: "index_ledger_entries_on_ledger_transaction_id"
    t.check_constraint "amount_cents > 0", name: "ledger_entries_amount_positive"
    t.check_constraint "entry_type IN ('debit', 'credit')", name: "ledger_entries_type_valid"
  end

  create_table "ledger_transactions", force: :cascade do |t|
    t.string "reference", null: false
    t.string "description", null: false
    t.string "currency", default: "USD", null: false
    t.json "metadata", default: {}, null: false
    t.integer "reverses_transaction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference"], name: "index_ledger_transactions_on_reference", unique: true
    t.index ["reverses_transaction_id"], name: "index_ledger_transactions_on_reverses_transaction_id", unique: true, where: "reverses_transaction_id IS NOT NULL"
  end

  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "ledger_transactions"
  add_foreign_key "ledger_transactions", "ledger_transactions", column: "reverses_transaction_id"
end
