class ApplicationController < ActionController::Base
  around_action :switch_locale
  helper_method :rtl?

  private

  def switch_locale(&action)
    locale = session[:locale]&.to_sym
    locale = I18n.default_locale unless I18n.available_locales.include?(locale)
    I18n.with_locale(locale, &action)
  end

  def rtl?
    I18n.locale == :fa
  end
end
