class LatestReleasesController < ApplicationController

  # caches_action :index

  def index
    @supported_languages = Product::A_LANGS_SUPPORTED
    @latest_releases = Newest.balanced_newest(20)
  end

  def show
    page = params[:page] || 1
    @lang = Product.decode_language(params[:lang])
    @latest_releases = Newest.where(
      :language => @lang,
      :created_at.gte => 30.days.ago.at_midnight
    ).desc(:created_at).paginate(page: page, per_page: 30)
  end

  def stats
    time_span = :today
    time_span = params[:timespan].to_sym if params.has_key?(:timespan)
    render json: LanguageDailyStats.latest_versions(time_span)
  end

  def lang_timeline30
    lang = 'php'
    lang = params[:lang] if params.has_key?(:lang)
    lang = Product.decode_language(lang)
    render json: LanguageDailyStats.versions_timeline30(lang)
  end
end
