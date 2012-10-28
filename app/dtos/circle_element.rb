class CircleElement

  attr_accessor :id, :version, :text, :connections, :dependencies

  def initialize
    self.connections = Array.new
    self.dependencies = Array.new  # array of prod_key of dependencies
    self.text = ""
    self.id = ""
  end

  def connections_as_string
    response = ""
    connections.each do |conn|
      response += "\"#{conn}\","
    end
    end_pos = response.size - 2
    response[0..end_pos]
  end

  def as_json(options = {})
    {
      :text => self.text,
      :id => self.id,
      :connections => self.connections 
    }
  end
 
end