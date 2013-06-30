require 'grape'

require_relative 'helpers/session_helpers.rb'
require_relative 'helpers/product_helpers.rb'
require_relative 'helpers/paging_helpers.rb'

require_relative 'entities/product_entity.rb'
require_relative 'entities/product_search_entity.rb'

module V2
  #module VersionEye
    class  ProductsApi < Grape::API

      # Log Exceptions
      # rescue_from :all do |e|
      #   p e
      # end

      helpers ProductHelpers
      helpers SessionHelpers
      helpers PagingHelpers

      resource :products do

        before do
          track_apikey
        end

        desc "detailed information for specific package", {
            notes: %q[
                      NB! If there are some special characters in `prod_key`,
                      you must replace it to make it URL safe!
                      It means you must replace all slashes `/` in product key
                      with colon `:` and due to routing limitations of grape framework it's also required to replace all points `.` with tilde `~`. 
                      \\
                      For example Clojure package `yummy.json/json` has to be transformed to  `yummy~json:json`.
                      \\
                      It will respond with 404, when given product with given product doesnt exists and it will respond with 302, when you didnt encode product-key correctly.
                  ]
          }

        params do
          requires :lang, :type => String, :desc => %Q["Name of programming language"]
          requires :prod_key, :type => String,
                              :regexp => /[\w|:|~|-|\.]+/,
                              :desc => %Q["Encoded product key, replace all `.` & `/`-s"]
        end
        get '/:lang/:prod_key' do
          product = fetch_product(params[:lang], params[:prod_key])

          if product.nil?
            error_msg = "No such package for #{params[:lang]} with product key: `#{params[:prod_key]}`."
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
          optional :lang, :type => String,
                          :desc => %q[Filter results by programming languages;
                                  It have to be commaseparated list.
                                  For example, if you want to search Java: then just
                                  java or if you want to search Java, Ruby and NodeJS
                                  packages, then use java,ruby,nodejs
                                ]
          optional :g, :type => String, :desc => "Specify group-id for Java projects"
          optional :page, :type => Integer, :desc => "argument for paging", :regexp => /^[\d]+$/
        end
        get '/search/:q' do
          query    = parse_query(params[:q])
          group_id = params[:g]
          lang     = get_language_param(params[:lang])
          page_nr  = params[:page]
          page_nr  = nil if page_nr.to_i < 1 #will_paginate cant handle 0
          if query.length < 2
            error! "Search term was too short.", 400
          end

          languages = get_language_array(lang)

          start_time     = Time.now
          search_results = ProductService.search(query, group_id, languages, page_nr)

          save_search_log(query, search_results, start_time)
          query_data     = Api.new query: query, group_id: group_id, languages: languages
          paging         = make_paging_object(search_results)
          search_results = Api.new query: query_data, paging: paging, entries: search_results.entries

          present search_results, with: Entities::ProductSearchEntity
        end

        desc "check your following status", {
            notes: %q[
                      NB! If there are some special characters in `prod_key`,
                      you must replace it to make it URL safe!

                      Special character such as `/` should
                      be replaced with colon `:` .

                      For example `junit/junit` has to be transformed to  `junit:junit`.
                      \\
                      It will respond with 404, when given product with given product doesnt exists.
                  ]
          }

        params do
          requires :lang, :type => String, :desc => %Q["Name of programming language"]
          requires :prod_key, :type => String, :desc => "Package specifier"
        end
        get '/:lang/:prod_key/follow' do
          authorized?
          @current_product = fetch_product(params[:lang], params[:prod_key])
          if @current_product.nil?
            error! "Wrong product_key", 400
          end

          user_follow = UserFollow.new
          user_follow.username = @current_user.username
          user_follow.prod_key = @current_product.prod_key
          user_follow.follows  = @current_user.products.include? @current_product

          present user_follow, with: Entities::UserFollowEntity
        end

        desc "follow your favorite software package", {
            notes: %q[
                      NB! If there are some special characters in `prod_key`,
                      you must replace it to make it URL safe!

                      Special characters such as `/` and `.` should
                      be replaced with characters `:` for slash and
                      `~` for points".

                      For example `junit/junit` has to be transormed to  `junit--junit`.
                  ]
          }
        params do
          requires :lang, :type => String, :desc => %Q[Programming language]
          requires :prod_key, :type => String,
                              :desc => %Q{ Package product key. }
        end
        post '/:lang/:prod_key/follow' do
          authorized?
          @current_product = fetch_product(params[:lang], params[:prod_key])
          if @current_product.nil?
            error! "Wrong product_key", 400
          end

          if !@current_product.users.include? @current_user
            @current_product.users.push @current_user
            @current_product.followers += 1
            @current_product.save
          end

          user_follow = UserFollow.new
          user_follow.username = @current_user.username
          user_follow.prod_key = @current_product.prod_key
          user_follow.follows  = @current_product.users.include? @current_user

          present user_follow, with: Entities::UserFollowEntity
        end

        desc "unfollow given software package"
        params do
          requires :lang, :type => String, :desc => %Q{Programming language}
          requires :prod_key, :type => String, :desc => "Package specifier"
        end
        delete '/:lang/:prod_key/follow' do
          authorized?
          @current_user = current_user
          @current_product = fetch_product(params[:lang], params[:prod_key])
          error!("Wrong product key", 400) if @current_product.nil?

          if @current_product.users.include? @current_user
            @current_product.users.delete @current_user
            @current_product.followers -= 1
            @current_product.save
          end

          user_follow = UserFollow.new
          user_follow.username = @current_user.username
          user_follow.prod_key = @current_product.prod_key
          user_follow.follows  = @current_user.products.include? @current_product

          present user_follow, with: Entities::UserFollowEntity
        end
      end
    #end
  end
end
