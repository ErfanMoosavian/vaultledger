require "rails_helper"

RSpec.describe MoneyAmount do
  it "creates money from integer cents and formats cleanly" do
    amount = described_class.new(123_456, "USD")
    expect(amount.formatted).to eq("$1,234.56")
  end

  it "parses major units from String without floating point drift" do
    amount = described_class.from_major("19.99", "EUR")
    expect(amount.cents).to eq(1999)
    expect(amount.formatted).to eq("€19.99")
  end

  it "strictly rejects Float inputs to prevent rounding bugs" do
    expect { described_class.new(10.50, "USD") }.to raise_error(LedgerErrors::InvalidAmount)
    expect { described_class.from_major(19.99, "USD") }.to raise_error(LedgerErrors::InvalidAmount)
  end

  it "raises CurrencyMismatch when adding different currencies" do
    usd = described_class.new(100, "USD")
    eur = described_class.new(100, "EUR")
    expect { usd + eur }.to raise_error(LedgerErrors::CurrencyMismatch)
  end
end
