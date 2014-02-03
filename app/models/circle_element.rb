class CircleElement

  include Mongoid::Document
  include Mongoid::Timestamps

  # This attributes describe to which product
  # this circle_element belongs to. Parent!
  # This fields are only important if you wanan store the
  # instance to DB. Otherwise they can be empty!
  field :language           , type: String
  field :prod_key           , type: String
  field :prod_version       , type: String
  field :prod_scope         , type: String

  # This attributes describe the circle_element itself!
  field :dep_prod_key       , type: String, :default => ''
  field :version            , type: String, :default => ''
  field :text               , type: String, :default => ''
  field :connections_string , type: String
  field :dependencies_string, type: String
  field :level              , type: Integer, :default => 1

  attr_accessor :connections, :dependencies

  def self.fetch_circle(language, prod_key, version, scope)
    CircleElement.where(language: language, prod_key: prod_key, prod_version: version, prod_scope: scope)
  end

  def init_arrays
    self.connections  = Array.new
    self.dependencies = Array.new
  end

  def self.store_circle(circle, lang, prod_key, version, scope)
    circle.each do |key, element|
      element.language            = lang
      element.prod_key            = prod_key
      element.prod_version        = version
      element.prod_scope          = scope
      element.connections_string  = element.connections_as_string
      element.dependencies_string = element.dependencies_as_string
      element.save
    end
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  # TODO move this to service layer
  def self.dependency_circle(lang, prod_key, version, scope)
    if scope == nil
      scope = Dependency.main_scope( lang )
    end
    hash = Hash.new
    dependencies = Array.new
    if scope.eql?('all')
      dependencies = Dependency.find_by_lang_key_and_version( lang, prod_key, version )
    else
      dependencies = Dependency.find_by_lang_key_version_scope( lang, prod_key, version, scope )
    end
    dependencies.each do |dep|
      next if dep.name.nil? || dep.name.empty?
      DependencyService.update_parsed_version( dep ) if dep.parsed_version.nil?
      element = CircleElement.new
      element.init_arrays
      element.dep_prod_key = dep.dep_prod_key
      element.version      = dep.parsed_version
      element.level        = 0
      self.attach_label_to_element(element, dep)
      hash[dep.dep_prod_key] = element
    end
    return self.fetch_deps(1, hash, Hash.new, lang)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end

  def self.fetch_deps(deep, hash, parent_hash, lang)
    return hash if hash.empty?
    new_hash = Hash.new
    hash.each do |prod_key, element|
      product = Product.find_by_lang_key( lang, prod_key )
      if product.nil?
        next
      end
      valid_version = ( element.version && !element.version.eql?("") && !element.version.eql?("0") && product.version_by_number( element.version ) )
      product.version = element.version if valid_version
      dependencies = product.dependencies(nil)
      dependencies.each do |dep|
        if dep.name.nil? || dep.name.empty?
          next
        end
        DependencyService.update_parsed_version( dep ) if dep.parsed_version.nil?
        key = dep.dep_prod_key
        ele = self.get_element_from_hash(new_hash, hash, parent_hash, key)
        if ele
          ele.connections << "#{element.dep_prod_key}"
        else
          new_element = CircleElement.new
          new_element.init_arrays
          new_element.dep_prod_key   = dep.dep_prod_key
          new_element.level          = deep
          attach_label_to_element(new_element, dep)
          new_element.connections    << "#{element.dep_prod_key}"
          new_element.version        = dep.parsed_version
          new_hash[dep.dep_prod_key] = new_element
        end
        element.connections  << "#{key}"
        element.dependencies << "#{key}"
      end
    end
    parent_merged = hash.merge(parent_hash)
    deep += 1
    rec_hash = self.fetch_deps(deep, new_hash, parent_merged, lang)
    merged_hash = parent_merged.merge(rec_hash)
    return merged_hash
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end


  def connections_as_string
    response = ""
    return response if connections.nil? or connections.empty?
    connections.each do |conn|
      response += "\"#{conn}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end

  def dependencies_as_string
    response = ""
    return response if dependencies.nil? or dependencies.empty?
    dependencies.each do |dep|
      response += "\"#{dep}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end

  def as_json(options = {})
    {
      :text        => self.text,
      :id          => self.dep_prod_key,
      :connections => self.connections
    }
  end

  def self.generate_json_for_circle_from_hash(circle)
    resp = ""
    circle.each do |key, dep|
      resp += "{"
      resp += "\"connections\": [#{dep.connections_as_string}],"
      resp += "\"dependencies\": [#{dep.dependencies_as_string}],"
      resp += "\"text\": \"#{dep.text}\","
      resp += "\"id\": \"#{dep.dep_prod_key}\","
      resp += "\"version\": \"#{dep.version}\""
      resp += "},"
    end
    end_point = resp.length - 2
    resp = resp[0..end_point]
    resp
  end

  def self.generate_json_for_circle_from_array(circle)
    resp = ""
    circle.each do |element|
      resp += "{"
      resp += "\"connections\": [#{element.connections_string}],"
      resp += "\"dependencies\": [#{element.dependencies_string}],"
      resp += "\"text\": \"#{element.text}\","
      resp += "\"id\": \"#{element.dep_prod_key}\","
      resp += "\"version\": \"#{element.version}\""
      resp += "},"
    end
    end_point = resp.length - 2
    resp = resp[0..end_point]
    resp
  end

  private

    def self.attach_label_to_element(element, dep)
      return nil if !element or !dep
      element.text = "#{dep.name}:#{dep.version}"
    end

    def self.get_element_from_hash(new_hash, hash, parent_hash, key)
      element = new_hash[key]
      return element if !element.nil?
      element = hash[key]
      return element if !element.nil?
      element = parent_hash[key]
      return element
    end

end
