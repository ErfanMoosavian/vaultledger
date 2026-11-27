module Api
  module V1
    class TransfersController < BaseController
      def create
        with_idempotency do
          from_account = Account.find(params.require(:from_account_id))
          to_account = Account.find(params.require(:to_account_id))
          fee_account = params[:fee_account_id].present? ? Account.find(params[:fee_account_id]) : nil

          txn = Ledger::Transfer.call(
            from_account: from_account,
            to_account: to_account,
            amount_cents: params.require(:amount_cents).to_i,
            fee_cents: params[:fee_cents].to_i,
            fee_account: fee_account,
            description: params[:description]
          )
          [ :created, serialize_transaction(txn) ]
        end
      end
    end
  end
end
