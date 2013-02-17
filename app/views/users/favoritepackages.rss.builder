xml.rss :version => "2.0" do
  xml.channel do
    xml.title "VersionEye Notifications for #{@user.fullname}"
    xml.description "Latest VersionEye notifications."
    xml.link "#{url_for favoritepackages_user_url}.rss"
    
    @my_updated_products ||= []
    @my_updated_products.each do |package|

      safe_prod_key = Product.encode_prod_key package.prod_key 
      package_url = url_for products_url(safe_prod_key)
      notification_message = %Q[
        VersionEye detected version (#{package.version}) of #{package.name}. 
        #{package.description_summary}
      ]
      xml.item do
        xml.title "#{package.name} : #{package.version}".capitalize
        xml.author "VersionEye"
        xml.icon ""
        xml.description notification_message
        xml.category package.prod_type
        xml.pubDate package.updated_at.to_s(:rfc822)
        xml.link package_url
        xml.guid package.prod_key
      end
    end
  end
end
