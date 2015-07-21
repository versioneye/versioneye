class AuthorsController < ApplicationController


  def index
    @authors = Author.desc(:products_count).paginate(:page => params[:page], :per_page => 100)
  end


  def show 
    name_id = params[:id]
    @author = Author.find_by :name_id => name_id
    @products = Product.where(:id.in => @author.product_ids).desc(:used_by_count)
    @keywords = fill_keywords @products
  end


  private 


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
      end


end
