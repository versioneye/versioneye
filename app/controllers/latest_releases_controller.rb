class LatestReleasesController < ApplicationController
  caches_action :index

  def index
    @supported_languages = Product.supported_languages
    @latest_releases = Newest.balanced_newest(20)
  end

  def show
    page = params[:page] || 1
    @lang = Product.decode_language(params[:lang])
    @latest_releases = Newest.where(
      :language => @lang,
      :updated_at.gte => 30.days.ago.at_midnight
    ).desc(:updated_at).paginate(page: page, per_page: 30)
  end

  def stats_today
    NewestDailyCount.update_counts
    render json: NewestDailyCount.stats_today
  end

  def stats_current_week
    NewestDailyCount.update_counts
    render json: NewestDailyCount.stats_current_week
  end

  def stats_current_month
    NewestDailyCount.update_counts
    render json: NewestDailyCount.stats_current_month
  end

  def stats_last_month
    NewestDailyCount.update_counts
    render json: NewestDailyCount.stats_last_month
  end

  def timeline_30days
    lang = "clojure"
    lang = params[:lang] if params.has_key?(:lang)
    lang = lang.gsub("\.", "")
    lang = "node.js" if lang == "nodejs"

    NewestDailyCount.update_counts #can i run it as prefilter?
    render json: NewestDailyCount.language_30days_timeline(lang)
  end
end
