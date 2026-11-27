require "digest"

module Api
  module V1
    class BaseController < ActionController::API
      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "not_found", message: e.message }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "validation_failed", details: e.record.errors.full_messages }, status: :unprocessable_content
      end

      rescue_from LedgerErrors::Base do |e|
        render json: { error: e.class.name.demodulize.underscore, message: e.message }, status: :unprocessable_content
      end

      rescue_from LedgerErrors::IdempotencyConflict do |e|
        render json: { error: "idempotency_conflict", message: e.message }, status: :conflict
      end

      rescue_from LedgerErrors::AlreadyReversed do |e|
        render json: { error: "already_reversed", message: e.message }, status: :conflict
      end

      private

      def with_idempotency
        key = request.headers["Idempotency-Key"].to_s.strip
        if key.blank?
          status, payload = yield
          return render json: payload, status: status
        end

        request_hash = Digest::SHA256.hexdigest(request.raw_post.to_s)
        existing = IdempotencyRecord.find_by(idempotency_key: key, request_path: request.path)
        return replay_idempotent_response(existing, request_hash, key) if existing

        status, payload = yield
        IdempotencyRecord.create!(
          idempotency_key: key,
          request_path: request.path,
          request_hash: request_hash,
          response_status: Rack::Utils.status_code(status),
          response_body: payload.to_json
        )
        render json: payload, status: status
      rescue ActiveRecord::RecordNotUnique
        existing = IdempotencyRecord.find_by!(idempotency_key: key, request_path: request.path)
        replay_idempotent_response(existing, request_hash, key)
      end

      def replay_idempotent_response(record, request_hash, key)
        if record.request_hash != request_hash
          raise LedgerErrors::IdempotencyConflict, "Idempotency-Key '#{key}' was already used with a different payload."
        end

        response.set_header("X-Idempotent-Replayed", "true")
        render json: JSON.parse(record.response_body), status: record.response_status
      end

      def serialize_account(account)
        {
          id: account.id,
          name: account.name,
          account_number: account.account_number,
          account_type: account.account_type,
          currency: account.currency,
          balance_cents: account.balance_cents,
          balance_formatted: account.balance.formatted,
          allow_negative: account.allow_negative,
          created_at: account.created_at
        }
      end

      def serialize_transaction(txn)
        {
          id: txn.id,
          reference: txn.reference,
          description: txn.description,
          currency: txn.currency,
          total_volume_cents: txn.total_volume_cents,
          reversed: txn.reversed?,
          reverses_transaction_id: txn.reverses_transaction_id,
          metadata: txn.metadata,
          created_at: txn.created_at,
          entries: txn.ledger_entries.includes(:account).order(:id).map do |entry|
            {
              id: entry.id,
              account_id: entry.account_id,
              account_number: entry.account.account_number,
              entry_type: entry.entry_type,
              amount_cents: entry.amount_cents,
              balance_after_cents: entry.balance_after_cents
            }
          end
        }
      end
    end
  end
end
