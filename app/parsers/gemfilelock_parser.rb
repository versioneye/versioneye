class GemfilelockParser < CommonParser
  
  # Parser for Gemfile.lock. For Ruby. 
  # http://gembundler.com/man/gemfile.5.html
  # http://docs.rubygems.org/read/chapter/16#page74
  #
  # TODO Write Tests
  # 
  def parse(url)
    return nil if url.nil?
    content = self.fetch_response(url).body
    return nil if content.nil?
    
    dependecies_matcher = /([\w|\d|\.|\-|\_]+) (\(.*\))/

    matches = content.scan( dependecies_matcher )
    deps = self.build_dependencies(matches)
    project = Project.new deps
    project.dep_number = project.dependencies.count
    project.project_type = Project::A_TYPE_RUBYGEMS
    project.url = url
    project
  end

  def build_dependencies(matches)
    unknowns, out_number = 0, 0 
    deps = Hash.new

    matches.each do |row|
      name = row[0]
      version_match = row[1]
      version = version_match.gsub("(", "").gsub(")", "")
      dependency = Projectdependency.new

      product = Product.find_by_key(name)
      if product
        dependency.prod_key = product.prod_key
      else
        unknowns += 1
      end
      dependency.name = name
      GemfileParser.parse_requested_version(version, dependency, product)

      dep = deps[name]
      if dep.nil? or !dep.comperator.eql?("=")
        deps[name] = dependency  
      end
    end

    data = Array.new
    deps.each do |k, v|
      if v.outdated?
        out_number += 1
      end
      data.push v
    end 
    
    return {:unknown_number => unknowns, :out_number => out_number, :dependencies => data}
  end
  
end
