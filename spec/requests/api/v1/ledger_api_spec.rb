require "rails_helper"

RSpec.describe "Api::V1 Ledger Endpoints", type: :request do
  let!(:treasury) { Account.create!(name: "Treasury", account_type: "asset", currency: "USD") }
  let!(:alice)    { Account.create!(name: "Alice", account_type: "liability", currency: "USD") }
  let!(:bob)      { Account.create!(name: "Bob", account_type: "liability", currency: "USD") }
  let!(:fees)     { Account.create!(name: "Fees", account_type: "revenue", currency: "USD") }

  before do
    Ledger::PostTransaction.call(
      description: "Seed deposit",
      currency: "USD",
      entries: [
        { account_id: treasury.id, entry_type: "debit", amount_cents: 10_000 },
        { account_id: alice.id, entry_type: "credit", amount_cents: 10_000 }
      ]
    )
  end

  describe "POST /api/v1/transfers with Idempotency-Key" do
    let(:payload) do
      {
        from_account_id: alice.id,
        to_account_id: bob.id,
        amount_cents: 2_500,
        fee_cents: 100,
        fee_account_id: fees.id,
        description: "API payment"
      }
    end

    it "executes once, replays identically on retry, and returns 409 Conflict on payload mismatch" do
      headers = { "Idempotency-Key" => "pay-order-001" }

      # 1st request: executes transfer
      post "/api/v1/transfers", params: payload, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      first_body = JSON.parse(response.body)
      expect(alice.reload.balance_cents).to eq(7_500)
      expect(bob.reload.balance_cents).to eq(2_400)
      expect(fees.reload.balance_cents).to eq(100)

      # 2nd request (network retry): replays cached response without moving funds again
      post "/api/v1/transfers", params: payload, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(response.headers["X-Idempotent-Replayed"]).to eq("true")
      expect(JSON.parse(response.body)["reference"]).to eq(first_body["reference"])
      expect(alice.reload.balance_cents).to eq(7_500)

      # 3rd request (key reused with different amount): rejected with 409 Conflict
      post "/api/v1/transfers", params: payload.merge(amount_cents: 9_999), headers: headers, as: :json
      expect(response).to have_http_status(:conflict)
      expect(JSON.parse(response.body)["error"]).to eq("idempotency_conflict")
    end
  end

  describe "GET /api/v1/audit" do
    it "returns 200 OK with balanced accounting equation" do
      get "/api/v1/audit", as: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["passed"]).to be(true)
      expect(body["currency_equations"]["USD"]["balanced"]).to be(true)
    end
  end
end
