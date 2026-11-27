class CreateIdempotencyRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :idempotency_records do |t|
      t.string :idempotency_key, null: false
      t.string :request_path, null: false
      t.string :request_hash, null: false
      t.integer :response_status, null: false
      t.text :response_body, null: false

      t.timestamps
    end

    add_index :idempotency_records, [ :idempotency_key, :request_path ], unique: true, name: "idx_idempotency_key_path"
  end
end
