class LatestReleasesController < ApplicationController
  caches_action :index

  def index
    @supported_languages = Product.supported_languages
    @latest_releases = Newest.balanced_newest(20)
    @stats_today = ProductService.stats_today_releases 
    @stats_yesterday = ProductService.stats_yesterday_releases
    @stats_week = ProductService.stats_current_week_releases
    @stats_month = ProductService.stats_current_month_releases
  end

  def show
    page = params[:page] || 1
    @lang = Product.decode_language(params[:lang])
    @latest_releases = Newest.where(
      :language => @lang,
      :updated_at.gte => 30.days.ago.at_midnight
    ).desc(:updated_at).paginate(page: page, per_page: 30) 
  end
end
