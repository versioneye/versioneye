class StatisticsController < ApplicationController

  def index
  end

  def proglangs
    stats = StatisticService.language_project_count
    results = []
    stats.each do |row|
      results << {name: row[0], value: row[1]}
    end

    render json: results
  end

  def langtrends
    render json: StatisticService.language_project_trend
  end

end
