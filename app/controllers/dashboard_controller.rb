class DashboardController < ApplicationController
  def index
    @accounts = Account.order(:account_type, :id)
    @wallet_accounts = Account.where(account_type: "liability").order(:name)
    @treasury_accounts = Account.where(account_type: "asset").order(:name)
    @revenue_accounts = Account.where(account_type: "revenue").order(:name)
    @transactions = LedgerTransaction.includes(ledger_entries: :account, reversal_transaction: [], reverses_transaction: [])
                                     .order(id: :desc).limit(30)
    @audit_report = Ledger::AuditIntegrity.call
    @trial_balance = Ledger::TrialBalance.call(currency: "USD")
    @new_account = Account.new
  end

  def deposit
    treasury = Account.find(params[:treasury_account_id])
    wallet = Account.find(params[:wallet_account_id])
    money = MoneyAmount.from_major(params[:amount], wallet.currency)

    Ledger::PostTransaction.call(
      description: params[:description].presence || "Deposit to #{wallet.name}",
      currency: wallet.currency,
      entries: [
        { account_id: treasury.id, entry_type: "debit", amount_cents: money.cents },
        { account_id: wallet.id, entry_type: "credit", amount_cents: money.cents }
      ],
      metadata: { type: "deposit" }
    )
    redirect_to root_path, notice: t("notices.deposited", amount: money.formatted, wallet: wallet.name)
  rescue LedgerErrors::Base, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: e.message
  end

  def transfer
    from_acc = Account.find(params[:from_account_id])
    to_acc = Account.find(params[:to_account_id])
    money = MoneyAmount.from_major(params[:amount], from_acc.currency)
    fee_cents = params[:fee_amount].present? ? MoneyAmount.from_major(params[:fee_amount], from_acc.currency).cents : 0
    fee_acc = params[:fee_account_id].present? ? Account.find(params[:fee_account_id]) : nil

    txn = Ledger::Transfer.call(
      from_account: from_acc,
      to_account: to_acc,
      amount_cents: money.cents,
      fee_cents: fee_cents,
      fee_account: fee_acc,
      description: params[:description]
    )
    redirect_to root_path, notice: t("notices.transferred", ref: txn.reference, amount: money.formatted, from: from_acc.name, to: to_acc.name)
  rescue LedgerErrors::Base, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: e.message
  end

  def reverse
    txn = LedgerTransaction.find(params[:id])
    reversal = Ledger::ReverseTransaction.call(transaction: txn)
    redirect_to root_path, notice: t("notices.reversed", rev: reversal.reference, ref: txn.reference)
  rescue LedgerErrors::Base, ActiveRecord::RecordNotFound => e
    redirect_to root_path, alert: e.message
  end
end
