module LedgerErrors
  class Base < StandardError; end
  class InvalidAmount < Base; end
  class CurrencyMismatch < Base; end
  class UnbalancedTransaction < Base; end
  class InsufficientFunds < Base; end
  class ImmutableRecord < Base; end
  class IdempotencyConflict < Base; end
  class AlreadyReversed < Base; end
  class InvalidTransaction < Base; end
end
