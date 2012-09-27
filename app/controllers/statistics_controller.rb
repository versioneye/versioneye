require 'json'
require 'date'

class StatisticsController < ApplicationController

	caches_action :get_proglangs, :get_langtrends

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

	def parse_date_string(dt_string)
		return nil if dt_string.nil?

		begin
			d = Date.strptime dt_string, "%Y-%m-%d" 
		rescue 
			begin
				d = Date.strptime dt_string, "%Y-%m"
			rescue				
				begin 
					d = Date.strptime dt_string, "%d-%m-%Y"
				rescue 
					begin
						d = Date.strptime dt_string, "%m-%Y"
					rescue
						d = nil
					end
				end
			end
		end
		return d
	end

	def get_langtrends
		puts parse_date_string(params["starts"])
		starts = parse_date_string(params["starts"])
		ends = parse_date_string(params["ends"])
		stats = Product.get_language_trend starts, ends
		respond_to do |format|
			format.json {
				render :json => stats
			}
		end
	end 
end