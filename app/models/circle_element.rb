class CircleElement

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String
  field :prod_version, type: String   # TODO set this values in code
  field :prod_scope, type: String     # TODO set this values in code
  field :dep_prod_key, type: String
  field :version, type: String
  field :text, type: String
  field :connections_string, type: String
  field :dependencies_string, type: String
  field :level, type: Integer

  attr_accessor :connections, :dependencies

  def self.fetch_circle(prod_key, version, scope)
    CircleElement.where(prod_key: prod_key, prod_version: version, prod_scope: scope)
  end

  def init
    self.connections = Array.new
    self.dependencies = Array.new 
    self.text = ""
    self.dep_prod_key = ""
    self.level = 1
  end

  def self.store_circle(circle, prod_key, version, scope)
    circle.each do |key, element| 
      element.prod_key = prod_key
      element.prod_version = version
      element.prod_scope = scope
      element.connections_string = element.connections_as_string
      element.dependencies_string = element.dependencies_as_string
      element.save
    end
  end

  def connections_as_string
    response = ""
    connections.each do |conn|
      response += "\"#{conn}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end

  def dependencies_as_string
    response = ""
    dependencies.each do |dep|
      response += "\"#{dep}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end

  def as_json(options = {})
    {
      :text => self.text,
      :id => self.dep_prod_key,
      :connections => self.connections 
    }
  end
 
end