class AccountsController < ApplicationController
  def create
    @account = Account.new(account_params)
    if @account.save
      redirect_to root_path, notice: t("notices.account_created", name: @account.name, number: @account.account_number)
    else
      redirect_to root_path, alert: @account.errors.full_messages.to_sentence
    end
  end

  def show
    @account = Account.find(params[:id])
    @entries = @account.ledger_entries.includes(:ledger_transaction).order(id: :desc)
    @audit_report = Ledger::AuditIntegrity.call
  end

  def export
    account = Account.find(params[:id])
    csv_data = Ledger::ExportStatement.call(account: account)
    send_data csv_data, filename: "#{account.account_number}-statement.csv", type: "text/csv; charset=utf-8"
  end

  private

  def account_params
    params.require(:account).permit(:name, :account_type, :currency, :allow_negative)
  end
end
