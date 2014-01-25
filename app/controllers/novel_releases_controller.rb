class NovelReleasesController < ApplicationController

  # caches_action :index

  def index
    @supported_languages = Product::A_LANGS_SUPPORTED
    @latest_releases     = Newest.balanced_novel(20)
  end

  def show
    page = params[:page] || 1
    @lang = Product.decode_language(params[:lang])
    @latest_releases = Newest.where(
      :language => @lang,
      :novel => true
    ).desc(:created_at).paginate(page: page, per_page: 30)
  end

  def stats
    time_span = :today
    time_span = params[:timespan].to_sym if params.has_key?(:timespan)
    render json: LanguageDailyStats.novel_releases(time_span)
  end

  def lang_timeline30
    lang = 'php'
    lang = params[:lang] if params.has_key?(:lang)

    lang = Product.decode_language(lang)
    render json: LanguageDailyStats.novel_releases_timeline30(lang)
  end
end
