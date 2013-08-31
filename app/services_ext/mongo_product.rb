class MongoProduct

  # This class handles the product search on MongoDB.

  # languages have to be an array of strings.
  def self.find_by(query, description = nil, group_id = nil, languages=nil, limit=300)
    searched_name = nil
    if query
      searched_name = String.new( query.gsub(" ", "-") )
    end
    result1 = find_all(searched_name, description, group_id, languages, limit, nil)

    if searched_name.nil? || searched_name.empty?
      return result1
    end

    prod_keys = Array.new
    if result1 && !result1.empty?
      prod_keys = result1.map{|w| "#{w.prod_key}"}
    end
    result2 = find_all(searched_name, description, group_id, languages, limit, prod_keys)
    result = result1 + result2
    return result
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  # languages have to be an array of strings.
  def self.find_all(searched_name, description, group_id, languages=nil, limit=300, exclude_keys)
    query = Mongoid::Criteria.new(Product)
    if searched_name && !searched_name.empty?
      if exclude_keys
        query = find_by_name_exclude(searched_name, exclude_keys)
      else
        query = find_by_name(searched_name)
      end
    elsif description && !description.empty?
      query = find_by_description(description)
    elsif group_id && !group_id.empty?
      return Product.where(group_id: /^#{group_id}/).desc(:followers).asc(:name).limit(limit)
    else
      return Mongoid::Criteria.new(Product, {_id: -1})
    end
    query = add_to_query(query, group_id, languages)
    query = query.desc(:followers).asc(:name).limit(limit)
    return query
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name(searched_name)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    Product.where(name_downcase: /^#{searched_name}/)
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  def self.find_by_name_exclude(searched_name, prod_keys)
    if (searched_name.nil? || searched_name.strip == "")
      return nil
    end
    Product.all(conditions: { name_downcase: /#{searched_name}/, :prod_key.nin => prod_keys})
  end

  def self.find_by_description(description)
    if (description.nil? || description.strip == "")
      return Mongoid::Criteria.new(Product, {_id: -1})
    end
    query = Product.all(conditions: {"$or" => [ {"description" => /#{description}/i}, {"description_manual" => /#{description}/i} ] })
    query
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.first
    Mongoid::Criteria.new(Product, {_id: -1})
  end

  private

    def self.add_to_query(query, group_id, languages)
      if (group_id && !group_id.empty?)
        query = query.where(group_id: /^#{group_id}/i)
      end
      if languages && !languages.empty?
        query = query.in(language: languages)
      end
      query
    end

    def self.add_description_to_query(query, description)
      if (description && !description.empty?)
        query = query.where("$or" => [ {"description" => /#{description}/i}, {"description_manual" => /#{description}/i} ] )
      end
      query
    end

end
