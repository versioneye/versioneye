class StatisticsController < ApplicationController

	caches_action :proglangs, :langtrends

	def index
		@page = "statistics"
	end

	def proglangs
		stats = Rails.cache.read("lang_stat")
		if stats.nil? or stats.empty? 
			stats = StatisticService.language_project_count
			Rails.cache.write("lang_stat", stats)
		end
		respond_to do |format|
			format.json{
				render :json => stats.sort {|a, b| b[1] <=> a[1]}
			}
		end
	end 

	def langtrends
		stats = Rails.cache.read("lang_trend")
		if stats.nil? or stats.empty? 
			stats = StatisticService.language_project_trend
			Rails.cache.write("lang_trend", stats)
		end
		respond_to do |format|
			format.json {
				render :json => stats
			}
		end
	end

end