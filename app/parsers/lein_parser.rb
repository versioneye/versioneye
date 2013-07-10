class LeinParser < CommonParser

  def parse(url)
    return nil if url.nil?
    content = self.fetch_response(url).body
    return nil if content.nil?

    #transform to xml
    content = content.gsub /[\;]+.*/, '' #remove clojure comments
    content = content.gsub /[\s]+/, ' ' #replace reduntant whitespaces
    content = content.gsub /\[/, '<div>'
    content = content.gsub /\]/, '</div>'
    content = content.gsub /\{/, '<block>'
    content = content.gsub /\}/, '</block>'
    #add attributes to tags
    while true
      match = content.match(/\:(\S+)[\s]+\<(\w+)\>/)
      break if match.nil?
      content = "#{match.pre_match} <#{match.to_a[2]} attr=\"#{match.to_a[1]}\"> #{match.post_match}"
    end
    content = '<project>' + content + '</project>'

    doc = Nokogiri::XML content
    deps = self.build_dependencies doc.xpath('/project/div[@attr="dependencies"]').children
    project              = Project.new deps
    project.project_type = Project::A_TYPE_LEIN
    project.language     = Product::A_LANGUAGE_CLOJURE
    project.url          = url
    project.dep_number   = project.dependencies.size
    project
  end

  def build_dependencies(matches)
    data = []
    unknowns, out_number = 0, 0
    matches.each do |item|
      next if item.text.length < 2  #if dependency element is empty
      _, group_id, name, version =  item.text.scan(/((\S+)\/)?(\S+)\s+\"(\S+)\"/)[0]
      group_id = name if group_id.nil?
      scope, _ = item.text.scan(/:scope\s+\"(\S+)\"/)[0]
      dependency = Projectdependency.new({
        :scope => scope,
        :group_id => group_id,
        :artifact_id => name,
        :name => name,
        :version_requested => version,
        :comperator => "=",
        :language => Product::A_LANGUAGE_CLOJURE
      })
      product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
      if product
        dependency.prod_key = product.prod_key
      else
        unknowns += 1
      end
      if dependency.outdated?
        out_number += 1
      end
      data << dependency
    end

    return {:unknown_number => unknowns, :out_number => out_number, :projectdependencies => data}
  end

  # TODO use this method in this class to parse version strings
  def parse_requested_version(version, dependency, product)
    if (version.nil? || version.empty?)
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", "")

    if product.nil?
      dependency.version_requested = version
      dependency.version_label = version

    # TODO implement more cases

    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version

    end
  end

end
