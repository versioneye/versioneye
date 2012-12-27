class ProductlikesController < ApplicationController

  def like_overall
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)
    if @productlike.overall == 0 
      @productlike.overall = 1
      @productlike.save 
      @product.like_overall = @product.like_overall + 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  def dislike_overall
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)    
    if @productlike.overall == 1
      @productlike.overall = 0
      @productlike.save 
      @product.like_overall = @product.like_overall - 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  def like_docu
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)
    if @productlike.documentation == 0 
      @productlike.documentation = 1
      @productlike.save 
      @product.like_docu = @product.like_docu + 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  def dislike_docu
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)
    if @productlike.documentation == 1 
      @productlike.documentation = 0
      @productlike.save 
      @product.like_docu = @product.like_docu - 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  def like_support
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)
    if @productlike.support == 0 
      @productlike.support = 1
      @productlike.save 
      @product.like_support = @product.like_support + 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  def dislike_support
    product_key = url_param_to_origin params[:product_key]
    @product = fetch_product(product_key)
    @productlike = fetch_productlike(current_user, @product)
    if @productlike.support == 1 
      @productlike.support = 0
      @productlike.save 
      @product.like_support = @product.like_support - 1
      @product.save
    end
    respond_to do |format|
      format.js   {  }
      format.html { redirect_to product_version_path(@product) }
    end
  end

  private 

    def fetch_productlike(user, product)
      productlike = Productlike.find_by_user_id_and_product(user.id, product.prod_key)
      if productlike.nil?
        productlike = Productlike.new
        productlike.user_id = user.id.to_s 
        productlike.prod_key = product.prod_key
        productlike.save
      end
      productlike
    end

end