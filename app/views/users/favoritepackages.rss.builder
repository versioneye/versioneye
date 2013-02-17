xml.rss :version => "2.0" do
  xml.channel do
    xml.language "en"
    xml.category "Tech. News"
    xml.ttl "60"
    xml.title "VersionEye Notifications for #{@user.fullname}"
    xml.description "Latest VersionEye notifications."
    xml.link "#{url_for favoritepackages_user_url}.rss"
    xml.image do |img|
      img.url "http://www.versioneye.com/assets/icon_114.png"
      img.title "VersionEye : Continuous Updating"
      img.link "http://www.versioneye.com"
    end
    
    @notifications ||= []
    @notifications.each do |notification|

      package = @products[notification.product_id]
      safe_prod_key = Product.encode_prod_key package.prod_key 
      version_id = notification.version_id
      safe_version_key = Product.encode_prod_key version_id
      package_url = url_for package_version_url( safe_prod_key, safe_version_key )
      notification_message = %Q[
        VersionEye detected version (#{version_id}) of #{package.name} (#{package.language} Library). 
        #{package.description_summary}
      ]
      xml.item do
        xml.title "#{package.name} : #{version_id}".capitalize
        xml.link package_url
        xml.author "VersionEye"
        xml.category package.language
        xml.description notification_message
        xml.pubDate notification.created_at.to_s(:rfc822)
        xml.guid package_url
      end
    end
  end
end
