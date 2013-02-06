xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#Notification feed for #{@user.fullname}'s favorite packages "
    xml.description "Here will be latest notifications for signup user"
    xml.link "#{url_for favoritepackages_user_url}.rss"
    
    @my_updated_products ||= []
    @my_updated_products.each do |package|

      safe_prod_key = Product.encode_prod_key package.prod_key 
      package_url = url_for products_url(safe_prod_key)
      xml.item do
        xml.title "#{package.name}".capitalize
        xml.description package.description
        xml.pubDate package.updated_at.to_s(:rfc822)
        xml.link package_url
        xml.guid package.prod_key
      end
    end
  end
end
