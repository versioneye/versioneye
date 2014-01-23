class CommonParser

  def parse(url)
    raise NotImplementedError, 'Implement me!'
  end

  # It is important that this method is NOT writing into the database!
  #
  # Params:
  #   version           = the unparsed version string from the project file, e.g. '>= 2.0.1'
  #   projectdependency = This object can be empty/new. The results of the method are stored in this object
  #   product           = The corresponding product to the dependency. It can be nil if the dependency is unknown.
  #
  # Result: The method is parsing the version string and setting this values in projectdependency
  #   - projectdependency.version_label
  #   - projectdependency.version_requested
  #   - projectdependency.stability
  #   - projectdependency.comperator
  #
  def parse_requested_version(version, projectdependency, product)
    raise NotImplementedError, 'Implement me!'
  end

  def fetch_response url
    url  = self.do_replacements_for_github url
    uri  = URI.parse url
    http = Net::HTTP.new uri.host, uri.port
    if uri.port == 443
      curl_ca_bundle  = '/opt/local/share/curl/curl-ca-bundle.crt'
      ca_certificates = '/usr/lib/ssl/certs/ca-certificates.crt'
      http.use_ssl = true
      if File.exist?(curl_ca_bundle)
        http.ca_file = curl_ca_bundle
      elsif File.exist?(ca_certificates)
        http.ca_file = ca_certificates
      end
    end
    path  = uri.path
    query = uri.query
    http.get("#{path}?#{query}")
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def fetch_response_body( url )
    response = self.fetch_response( url )
    response.body
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def fetch_response_body_json( url )
    body = self.fetch_response_body( url )
    JSON.parse( body )
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def do_replacements_for_github(url)
    if url.match(/^https:\/\/github.com\//)
      url = url.gsub('https://github.com', 'https://raw.github.com')
      url = url.gsub('/blob/', '/')
    end
    url
  end

  def update_requested_with_current( dependency, product )
    if product && product.version
      dependency.version_requested = product.version
    else
      dependency.version_requested = 'UNKNOWN'
    end
    dependency
  end

end
