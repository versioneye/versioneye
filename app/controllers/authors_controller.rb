class AuthorsController < ApplicationController


  def index
    @authors = Author.desc(:products_count).paginate(:page => params[:page], :per_page => 100)
  end


  def show
    name_id = params[:id]
    @author = Author.find_by :name_id => name_id
    if @author.nil?
      dev = Developer.find name_id
      if dev
        @author = AuthorService.dev_to_author dev
      end
    end
    if @author.nil?
      render :text => "This page doesn't exist", :status => 404
      return
    end
    @products = find_products @author
    @keywords = fill_keywords @products
  end


  private


      def find_products author
        Product.where( :id.in => author.product_ids ).desc( :used_by_count )
      rescue => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join('\n')
        nil
      end


      def fill_keywords products
        keywords = []
        return keywords if products.nil? || products.empty?

        products.each do |product|
          next if product.nil? || product.tags.to_a.empty?

          product.tags.each do |tag|
            keywords << tag if !keywords.include?(tag)
          end
        end
        keywords
      rescue => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join('\n')
        []
      end


end
