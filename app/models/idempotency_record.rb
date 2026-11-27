class IdempotencyRecord < ApplicationRecord
  validates :idempotency_key, presence: true, uniqueness: { scope: :request_path }
  validates :request_path, :request_hash, :response_status, :response_body, presence: true
end
