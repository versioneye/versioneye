require 'grape'

module V2
  module Entities
    class PagingEntity < Grape::Entity
        expose :current_page
        expose :per_page
        expose :total_pages
        expose :total_entries
    end
  end
end
