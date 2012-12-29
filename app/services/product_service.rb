class ProductService

  # languages have to be an array of strings. 
  def self.search(q, group_id = nil, languages = nil, page_count = 1)
    ProductElastic.search(q, group_id, languages, page_count)
  rescue => e 
    p "ERROR in search - #{e}"
    p "Dam. We don't give up. Not yet! Start alternative search on awesome MongoDB."
    Product.find_by(q, "", group_id, languages, 300).paginate(:page => page_count)
  end

  def self.create_follower(prod_key, user)
    product = Product.find_by_key prod_key
    return "error" if product.nil? || user.nil?
    follower = Follower.find_by_user_id_and_product user._id.to_s, product._id.to_s
    return "success" if follower
    follower = Follower.new
    follower.user_id = user._id.to_s
    follower.product_id = product._id.to_s
    if follower.save
      product.followers += 1
      product.save
      return "success"
    else 
      return "error"
    end
  end
  
  def self.destroy_follower(prod_key, user)
    product = Product.find_by_key prod_key
    return "error" if product.nil? || user.nil?
    follower = Follower.find_by_user_id_and_product user._id.to_s, product._id.to_s
    if follower
      resp = follower.remove
      product.followers -= 1
      product.save
    end
    return "success"
  end

end
