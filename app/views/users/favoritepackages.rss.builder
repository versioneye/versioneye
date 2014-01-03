xml.rss :version => '2.0' do
  xml.channel do
    xml.language 'en'
    xml.category 'Tech. News'
    xml.ttl '60'
    xml.title "VersionEye Notifications for #{@user.fullname}"
    xml.description 'Latest VersionEye notifications.'
    xml.link "#{url_for favoritepackages_user_url}.rss"
    xml.image do |img|
      img.url "http://www.versioneye.com/assets/icon_114.png"
      img.title "VersionEye : Continuous Updating"
      img.link "http://www.versioneye.com"
    end

    @notifications ||= []
    @notifications.each do |notification|
      product          = notification.product
      next if product.nil?
      safe_prod_key    = Product.encode_prod_key product.prod_key
      version       = notification.version
      safe_version_key = Product.encode_prod_key version
      product_url      = url_for package_version_url( product.language_esc, safe_prod_key, safe_version_key )
      notification_message = %Q[
        VersionEye detected version (#{version}) of #{product.name} (#{product.language} Library).
        #{product.description_summary}.
      ]
      xml.item do
        xml.title "#{product.name} : #{version}".capitalize
        xml.link product_url
        xml.author "VersionEye"
        xml.category product.language
        xml.description notification_message
        xml.pubDate notification.created_at.to_s(:rfc822)
        xml.guid product_url
      end
    end
  end
end
