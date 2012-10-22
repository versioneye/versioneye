class StatisticsController < ApplicationController

	caches_action :proglangs, :langtrends

	def index
		@page = "statistics"
	end

	def proglangs
		stats = Product.get_language_stat
		respond_to do |format|
			format.json{
				render :json => stats.sort {|a, b| b[1] <=> a[1]}
			}
		end
	end 

	def langtrends
		stats = Product.get_language_trend
		respond_to do |format|
			format.json {
				render :json => stats
			}
		end
	end

end