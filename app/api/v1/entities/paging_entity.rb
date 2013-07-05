require 'grape'

module EntitiesV1
	class PagingEntity < Grape::Entity
	    expose :current_page
	    expose :per_page
	    expose :total_pages
	    expose :total_entries
	end
end