require 'json'

class StatisticsController < ApplicationController

	def index
		@page = "statistics"
	end

	def get_proglangs
		stats = Product.get_language_stat
		respond_to do |format|
			#format.html "Sorry, i speak only JSON"
			format.json{
				render :json => stats.sort {|a, b| b[1] <=> a[1]}
			}
		end
	end 
end