class StatisticsController < ApplicationController

  #caches_action :proglangs, :langtrends

  def index
  end

  def proglangs
    stats = Rails.cache.read('lang_stat')
    if stats.nil? or stats.empty?
      stats = StatisticService.language_project_count
      Rails.cache.write('lang_stat', stats)
    end
    results = []
    stats.each do |row|
      results << {name: row[0], value: row[1]}
    end

    render json: results
  end

  def langtrends
    stats = Rails.cache.read('lang_trend')
    if stats.nil? or stats.empty?
      stats = StatisticService.language_project_trend
      Rails.cache.write('lang_trend', stats)
    end
    render json: stats
  end
end
