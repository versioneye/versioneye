class Settings::EmailsettingsController < ApplicationController

  before_filter :authenticate_admin

  def index
    @emailsetting = EmailSetting.first
    if @emailsetting.nil?
      @emailsetting = EmailSetting.new
      @emailsetting.save
    end
  end

  def update
    es = EmailSetting.first
    if es.update_attributes params
      flash[:success] = 'Email settings updated'
    else
      flash[:error] = "Something went wrong - #{es.errors.full_messages.to_sentence}"
    end
    redirect_to settings_emailsettings_path
  end

end
