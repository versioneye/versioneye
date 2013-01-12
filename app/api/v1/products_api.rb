require 'grape'
require_relative 'helpers/product_helpers.rb'
require_relative 'entities/product_entity.rb'

module VersionEye
  class  ProductsApi < Grape::API
    helpers ProductHelpers

    resource :products do

      desc "get detailed informations for specific package"
      params do
        requires :prod_key, :type => String, :desc => "Product key"
      end
      get '/:prod_key' do
        prod_key = get_product_key(params[:prod_key])
        product = Product.find_by_key prod_key
        if product.nil?
          error_msg = "No such package with product key: `#{prod_key}`."
          error! error_msg, 404
        end
        
        present product, with: Entities::ProductEntityDetailed
      end


      desc "search products from VersionEye"
      params do
        requires :q, :type => String, :desc => "Search query"
        optional :lang, :type => String, :desc => "Filter results by programming languages"
        optional :g, :type => String, :desc => "Specify group-id for Java projects"
        optional :page, :type => Integer, :desc => "Current page", :regexp => /^[\d]+$/
      end
      get '/search/:q' do
        query = parse_query(params[:q])
        group_id = params[:g]
        lang = get_language_param(params[:lang])
        page_nr = params[:page]
        if query.length < 2
          error! "Search term was too short.", 400
        end

        start_time = Time.now
        languages = get_language_array(lang)
        products = ProductService.search(query, group_id, languages, page_nr)
        #save_search_log(query, products, start_time)

        present products, with: Entities::ProductEntity
      end

    end
  end
end
