
module PagingHelpersV1
	def make_paging_object(query_results)
	  Api.new current_page: query_results.current_page,
	                   per_page: query_results.per_page,
	                   total_entries: query_results.total_entries,
	                   total_pages: query_results.total_pages

	end
end

