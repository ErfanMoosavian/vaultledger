module Api
  module V1
    class TransactionsController < BaseController
      def index
        txns = LedgerTransaction.includes(ledger_entries: :account).order(id: :desc).limit(50)
        render json: { transactions: txns.map { |t| serialize_transaction(t) } }
      end

      def show
        txn = LedgerTransaction.find(params[:id])
        render json: serialize_transaction(txn)
      end

      def create
        with_idempotency do
          entries = Array(params[:entries]).map do |e|
            {
              account_id: e[:account_id].to_i,
              entry_type: e[:entry_type].to_s,
              amount_cents: e[:amount_cents].to_i
            }
          end

          txn = Ledger::PostTransaction.call(
            description: params.require(:description),
            currency: params[:currency] || "USD",
            entries: entries,
            metadata: params[:metadata]&.to_unsafe_h || {}
          )
          [ :created, serialize_transaction(txn) ]
        end
      end

      def reverse
        with_idempotency do
          txn = LedgerTransaction.find(params[:id])
          reversal = Ledger::ReverseTransaction.call(transaction: txn, reason: params[:reason])
          [ :created, serialize_transaction(reversal) ]
        end
      end
    end
  end
end
