require 'grape'

require_relative 'helpers/session_helpers.rb'
require_relative 'helpers/product_helpers.rb'
require_relative 'entities/product_entity.rb'
require_relative 'entities/product_search_entity.rb'

module VersionEye
  class  ProductsApi < Grape::API
    helpers ProductHelpers
    helpers SessionHelpers
    
    resource :products do

      desc "detailed information for specific package", {
          notes: %q[
                    NB! If there are some special characters in `prod_key`, 
                    you must replace it to make it URL safe! 
                    
                    Special characters such as `/` and `.` should
                    be replaced with tokens `--` for back-slash and 
                    `~` for points. 

                    For example `junit/junit` has to be transormed to  `junit--junit`.
                    \\
                    It will respond with 404, when given product with given product doesnt exists.
                ]
        }

      params do
        requires :prod_key, :type => String, 
                            :desc => %Q[ Product specific key. 
                                         NB! check implementation notes. ]
      end
      get '/:prod_key' do

        prod_key = parse_product_key(params[:prod_key])
        product = Product.find_by_key prod_key
        if product.nil?
          error_msg = "No such package with product key: `#{prod_key}`."
          error! error_msg, 404
        end
        
        present product, with: Entities::ProductEntityDetailed
      end


      desc "search packages", {
        notes: %q[
                The result is the same as in the web application. But you get it as JSON objects. The result is an array of product objects.
                \\
                The search term must contain at least 2 characters. 
                Otherwise service will respond with status 404. 
                If there are no results, you'll get an empty array [ ] back.
              ]
      }
      params do
        requires :q, :type => String, :desc => "Query string"
        optional :lang, :type => String, :desc => "Filter results by programming languages"
        optional :g, :type => String, :desc => "Specify group-id for Java projects"
        optional :page, :type => Integer, :desc => "argument for paging", :regexp => /^[\d]+$/
      end
      get '/search/:q' do
        query = parse_query(params[:q])
        group_id = params[:g]
        lang = get_language_param(params[:lang])
        page_nr = params[:page]
        page_nr = nil if page_nr.to_i < 1 #will_paginate cant handle 0
        if query.length < 2
          error! "Search term was too short.", 400
        end

        start_time = Time.now
        languages = get_language_array(lang)
        search_results= ProductService.search(query, group_id, languages, page_nr)
        #save_search_log(query, products, start_time)
        query_data = Api.new query: query,
                                  group_id: group_id,
                                  languages: languages
        paging = Api.new current_page: search_results.current_page,
                             per_page: search_results.per_page,
                             total_entries: search_results.total_entries,
                             total_pages: search_results.total_pages
                                            
        search_results = Api.new query: query_data,
                                     paging: paging,
                                     entries: search_results.entries

        present search_results, with: Entities::ProductSearchEntity
      end

      desc "check your following status", {
          notes: %q[
                    NB! If there are some special characters in `prod_key`, 
                    you must replace it to make it URL safe! 
                    
                    Special characters such as `/` and `.` should
                    be replaced with tokens `--` for back-slash and 
                    `~` for points. 

                    For example `junit/junit` has to be transormed to  `junit--junit`.
                    \\
                    It will respond with 404, when given product with given product doesnt exists.
                ]
        }

     params do 
        requires :prod_key, :type => String, :desc => "Package specifier"
        optional :api_key, :type => String, :desc => "Your api token, to create active session by run."
      end
      get '/:prod_key/follow' do
        authorized?
        @current_product = fetch_product(params[:prod_key])
        follow_status = false

        user_follow = Follower.where(user_id: @current_user.id, prod_id: @current_product.id).shift
        follow_status = true unless user_follow.nil?
        user_follow = Follower.new if user_follow.nil?

        user_follow[:username] = @current_user.username
        user_follow[:prod_key] = @current_product.prod_key 
        user_follow[:follows]  = follow_status

        present user_follow, with: Entities::UserFollowEntity
      end

      desc "follow your favorite software package", {
          notes: %q[
                    NB! If there are some special characters in `prod_key`, 
                    you must replace it to make it URL safe! 
                    
                    Special characters such as `/` and `.` should
                    be replaced with tokens `--` for back-slash and 
                    `~` for points". 

                    For example `junit/junit` has to be transormed to  `junit--junit`.
                ]
        }
      params do
        requires :prod_key, :type => String, 
                            :desc => %Q{ Package product key. }
      end
      post '/:prod_key/follow' do
        authorized?
        @current_user = current_user
        @current_product = fetch_product(params[:prod_key])
        user_follow = Follower.new user_id: @current_user.id,
                                   product_id: @current_product.id
        if user_follow.save
          user_follow[:username] = @current_user.username
          user_follow[:prod_key] = @current_product.prod_key
          user_follow[:follows]   = true

          present user_follow, with: Entities::UserFollowEntity
        else
          error! message: {
                            :success => false, 
                            :msg => user_follow.errors.full_messages.to_sentence
                          },
                 status: 500
        end
      end

      desc "unfollow given software package"
      params do
        requires :prod_key, :type => String, :desc => "Package specifier"
      end
      delete '/:prod_key/follow' do
        authorized?
        @current_user = current_user
        @current_product = fetch_product(params[:prod_key])
        user_follow = Follower.where(user_id: @current_user.id, 
                                     product_id: @current_product.id).shift
        unless user_follow.nil?
          user_follow.delete
        else
          user_follow = Follower.new
        end
        
        user_follow[:username] = @current_user.username
        user_follow[:prod_key] = @current_product.prod_key
        user_follow[:follows]  = false

        present user_follow, with: Entities::UserFollowEntity
      end
    end
  end
end
