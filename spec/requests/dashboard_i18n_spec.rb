require "rails_helper"

RSpec.describe "Bilingual Dashboard & CSV Export", type: :request do
  let!(:alice) { Account.create!(name: "Alice Wallet", account_type: "liability", currency: "USD") }

  it "switches seamlessly between English (LTR) and Persian (RTL)" do
    get switch_locale_path(:fa)
    expect(response).to have_http_status(:redirect)

    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('dir="rtl"')
    expect(response.body).to include("هسته حسابداری دوبل")

    get switch_locale_path(:en)
    get root_path
    expect(response.body).to include('dir="ltr"')
    expect(response.body).to include("Double-Entry Core")
  end

  it "downloads a CSV statement for an account" do
    get export_account_path(alice)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include("#{alice.account_number}-statement.csv")
  end
end
