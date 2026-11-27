module LedgerUiHelper
  TYPE_BADGE_CLASSES = {
    "asset"     => "bg-sky-500/15 text-sky-300 border-sky-400/30",
    "liability" => "bg-indigo-500/15 text-indigo-300 border-indigo-400/30",
    "revenue"   => "bg-emerald-500/15 text-emerald-300 border-emerald-400/30",
    "expense"   => "bg-amber-500/15 text-amber-300 border-amber-400/30",
    "equity"    => "bg-fuchsia-500/15 text-fuchsia-300 border-fuchsia-400/30"
  }.freeze

  def glass_card(extra = "")
    "bg-white/5 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl shadow-black/30 #{extra}".strip
  end

  def glass_input_class
    "w-full rounded-xl bg-slate-950/70 border border-white/15 px-3.5 py-2.5 text-sm text-slate-100 placeholder-slate-500 focus:border-emerald-400/60 focus:ring-2 focus:ring-emerald-400/20 focus:outline-none transition"
  end

  def glass_select_class
    "w-full rounded-xl bg-slate-950/80 border border-white/15 px-3 py-2.5 text-sm text-slate-100 focus:border-emerald-400/60 focus:outline-none transition"
  end

  def account_type_badge(account)
    classes = TYPE_BADGE_CLASSES.fetch(account.account_type, "bg-white/10 text-slate-200 border-white/20")
    label = t("account_types.#{account.account_type}", default: account.account_type.capitalize)
    content_tag(:span, label, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border #{classes}")
  end

  def entry_side_badge(entry_type, short: false)
    is_debit = entry_type.to_s == "debit"
    classes = is_debit ? "bg-rose-500/15 text-rose-300 border-rose-400/30" : "bg-emerald-500/15 text-emerald-300 border-emerald-400/30"
    key = short ? (is_debit ? "sides.dr" : "sides.cr") : "sides.#{entry_type}"
    content_tag(:span, t(key), class: "inline-flex items-center font-mono text-xs font-bold px-2 py-0.5 rounded-md border #{classes}")
  end

  def money_display(money_amount, extra_class: "")
    content_tag(:span, money_amount.formatted, dir: "ltr", class: "font-mono tabular-nums #{extra_class}".strip)
  end

  def currency_summary(accounts, account_type, currency = "USD")
    total_cents = accounts.select { |a| a.currency == currency && a.account_type == account_type }.sum(&:balance_cents)
    MoneyAmount.new(total_cents, currency)
  end

  def localized_account_type_options
    Account::TYPES.map { |type| [ t("account_types.#{type}"), type ] }
  end
end
