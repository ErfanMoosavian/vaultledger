module Api
  module V1
    class AccountsController < BaseController
      def index
        accounts = Account.order(:id)
        accounts = accounts.by_currency(params[:currency]) if params[:currency].present?
        render json: { accounts: accounts.map { |a| serialize_account(a) } }
      end

      def show
        account = Account.find(params[:id])
        entries = account.ledger_entries.includes(:ledger_transaction).order(id: :desc).limit(50)
        render json: serialize_account(account).merge(
          recent_entries: entries.map do |e|
            {
              id: e.id,
              transaction_reference: e.ledger_transaction.reference,
              description: e.ledger_transaction.description,
              entry_type: e.entry_type,
              amount_cents: e.amount_cents,
              balance_after_cents: e.balance_after_cents,
              created_at: e.created_at
            }
          end
        )
      end

      def create
        account = Account.create!(account_params)
        render json: serialize_account(account), status: :created
      end

      private

      def account_params
        params.require(:account).permit(:name, :account_type, :currency, :allow_negative)
      end
    end
  end
end
