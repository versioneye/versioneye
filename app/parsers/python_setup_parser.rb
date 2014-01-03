class PythonSetupParser < RequirementsParser

  def parse( url )
    response = fetch_response( url )
    doc      = response.body
    return nil if doc.nil? or doc.empty?
    requirements = parse_requirements( doc )
    # extras       = parse_extras( doc )
    project      = init_project( url )
    requirements.each do |requirement|
      parse_line requirement, project
    end
    project.dep_number = project.dependencies.size
    project
  end


  def parse_line requirement, project
    requirement = requirement.strip
    return false if requirement.nil? or requirement.empty?

    comparator = extract_comparator requirement
    package, version = requirement.split comparator

    product = Product.fetch_product Product::A_LANGUAGE_PYTHON, package

    if version.nil? && !product.nil?
      version = product.version
    end

    dependency = Projectdependency.new name: package.strip,
                                       version_label: "#{version}".strip,
                                       comperator: comparator,
                                       language: Product::A_LANGUAGE_PYTHON,
                                       scope: Dependency::A_SCOPE_COMPILE

    if product.nil?
      project.unknown_number + 1
    else
      dependency.prod_key = product.prod_key
    end

    parse_requested_version("#{comparator}#{version}", dependency, product)

    if dependency.outdated?
      project.out_number = project.out_number + 1
    end

    project.projectdependencies.push dependency
  end


  def from_file
    doc_file = File.new 'test/files/setup.py'
    doc_file.read
  end


  def parse_requirements(doc)
    return nil if doc.nil? or doc.empty?
    req_text = slice_content doc, 'install_requires', '[', ']', false
    req_text.split(/\'/).keep_if {|item| item.strip.length > 1}
  end


  def parse_extras(doc)
    return nil if doc.nil? or doc.empty?
    slice_content doc, 'extras_require', '{', '}', true
  end


  def slice_content(doc, keyword, start_matcher, end_matcher, include_matchers = false)
    return nil if doc.nil? or doc.empty?

    content_pos = doc.index keyword
    return nil if content_pos.nil?

    start_pos = doc.index start_matcher, content_pos
    end_pos   =  doc.index end_matcher, content_pos

    block_length = (end_pos - start_pos) + 1
    if include_matchers
      req_txt = doc.slice start_pos, block_length
    else
      req_txt = doc.slice(start_pos + 1, block_length - 2)
    end

    #clean up
    req_txt.gsub! /\#.*[^\n]$/, " " #remove python inline commens
    req_txt.gsub! /\s+       /, " " #remove redutant spacer

    req_txt
  end

end
