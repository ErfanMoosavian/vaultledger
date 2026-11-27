module Api
  module V1
    class AuditController < BaseController
      def show
        report = Ledger::AuditIntegrity.call
        render json: {
          passed: report.passed,
          checked_accounts: report.checked_accounts,
          checked_transactions: report.checked_transactions,
          currency_equations: report.currency_equations,
          anomalies: report.anomalies
        }, status: report.passed ? :ok : :unprocessable_entity
      end
    end
  end
end
