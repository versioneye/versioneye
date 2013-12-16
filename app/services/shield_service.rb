require "bunny"

class ShieldService
  def self.package_version_shield(prod_key, prod_name, prod_version)
    channel_name = "versioneye.shields"
    routing_key = "package_version"

    msg = {
      prod_key: prod_key,
      name: prod_name,
      version: prod_version,
      content_type: "application/json"
    }.to_json

    #TODO: refactor out as BunnyDirectPublisher(channel_name, routing_key)
    conn = Bunny.new
    conn.start
    channel = conn.create_channel
    exchange = channel.direct(channel_name, durable: true)

    exchange.publish(msg, :routing_key => routing_key,
                          :persistent  => true,
                          :content_type => "application/json")
    #exchange.delete
    conn.close
  end
  def self.all_package_version_shield
    products = Product.by_language("Java").limit(10)
    10.times do |i|
      puts "Iteration: #{i}"
      prod = products.shift
      package_version_shield(prod[:prod_key], prod[:prod_name], prod[:version])
    end
  end
end
