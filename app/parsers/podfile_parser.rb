require 'cocoapods-core'

# This parser parses the podfile for any CocoaPods project
# and creates and stores a Project model in VersionEye
#
# TODO doc url

module Pod
  class Podfile
    # Configures a new Podfile from the given ruby string.
    #
    # @param  [String] string
    #         The ruby string which will configure the podfile with the DSL.
    #
    # @param  [Pathname] path
    #         The path from which the Podfile is loaded.
    #
    # @return [Podfile] the new Podfile
    #
    def self.from_url(url)
      podfile = nil
      open(url) do |io|
        begin
          podfile = Podfile.new do
            # rubocop:disable Eval
            eval(io.string, nil, url)
            # rubocop:enable Eval
          end
        rescue Exception => e
          puts e
          message = "Invalid url `#{url}`: #{e.message}"
          raise DSLError.new(message, url, e.backtrace)
        end
      end

      podfile

    end
  end
end


class PodfileParser < CommonParser

  @@project_type = Project::A_TYPE_COCOAPODS
  @@language     = Product::A_LANGUAGE_OBJECTIVEC
  @url          = ""

  attr_accessor :pod_hash, :prod_key

  def initialize
    # TODO not sure what to put here
  end

  def parse url
    @url = url
    return nil if url.to_s.empty?
    podfile = fetch_response_body( url )
    return nil if podfile.nil?

    @pod_file = Pod::Podfile.from_url url

    create_project
  end

  def parse_file filename
    @pod_filename = filename
    @pod_file = Pod::Podfile.from_file @pod_filename
    create_project
  end

  def create_project
    @pod_hash = @pod_file.to_hash
    @project  = init_project
    create_dependencies
    @project
  end

  # TODO: are there projects that gets updated?
  def init_project
    Project.new \
      project_type: @@project_type,
      language: @@language,
      url: @url
  end


  def create_dependencies
    # TODO this are differen compile targets
    target_def = @pod_hash["target_definitions"]

    puts "dependencies: #{@pod_file.dependencies}"
    puts "target_def: #{target_def}"

    if target_def.empty?
      Rails.logger.warn "no target definitions found for target definition" # TODO
    else

      if 1 < target_def.size
        Rails.logger.warn "found more than one target definition for target definition"
        puts target_def.to_yaml
      end

      # TODO make scopes out of the target definitions
      # target_def.each do |target|
      #   target.
      # end
      dependencies = target_def.first["dependencies"]
      veye_dep_array = dependencies.map do |dep|
        veye_dependency = create_dependency dep
        puts "this dependency #{veye_dependency}"
      end

      puts "all dependencies: #{veye_dep_array}"

      @project.projectdependencies.concat veye_dep_array
    end
  end

  def create_dependency dep
    # TODO load product.
    # TODO If there is no product in DB, than just set coperator & version.
    # It will marked as unknown.
    if dep.is_a? String
      dependency = latest_version_of_dependency dep

    elsif dep.is_a? Hash
      name = dep.keys.first
      reqs = dep[name]

      product = product(name)

      requirement = reqs.each do |req_version|
        v_hash = version_hash(req_version, name, product)
        puts "VERSION HASH IS #{v_hash}"
        return v_hash
      end

      puts "create_dependency '#{name}' -- #{requirement}"

      dependency = Projectdependency.new \
        :language => @@language,
        :prod_key => name.downcase,
        :name     => name,
        :version_requested  => requirement.first[:version_requested],
        :comperator         => requirement.first[:comperator]

    end

    dependency.outdated?
    dependency
  end

  VERSION_REGEXP = /^(=|!=|>=|>|<=|<|~>)\s*(\d(\.\d(\.\d)?)?)/
  def parse_version string
    string.match VERSION_REGEXP
    comperator, version = $1, $2
    return {:comperator => comperator, :version_requested => version}
  end

  def version_hash req_version, prod_name, prod
    if :head == req_version
      puts "WARNING dependency '#{prod_name}' requires HEAD" # TODO
      return {:version_requested => "HEAD", :version_label => "HEAD"}

    elsif :git == req_version
      puts "WARNING dependency '#{prod_name}' requires GIT" # TODO
      return {:version_requested => "GIT", :version_label => "GIT"}

    elsif :path == req_version
      puts "WARNING dependency '#{prod_name}' requires PATH" # TODO
      return {:version_requested => "PATH", :version_label => "PATH"}

    else
      requested_version = parse_version req_version
      # TODO copy composer for version ranges

      comperator   = requested_version[:comperator]
      req_ver      = requested_version[:version_requested]

      if prod
        all_versions = prod.versions
        best_version = best_version(all_versions, comperator, req_ver)
        requested_version[:version_requested] = best_version
      end

      puts "VERSION is #{requested_version}"
      return requested_version
    end
  end

  def best_version(versions, comperator, v)
    case comperator
    when ">"
      VersionService.greater_than(versions, v)
    when ">="
      VersionService.greater_than_or_equal(versions, v)
    when "<"
      VersionService.smaller_than(versions, v)
    when "<="
      VersionService.smaller_than_or_equal(versions, v)
    when "~>"
      starter         = VersionService.version_approximately_greater_than_starter( v )
      possible_vers   = VersionService.versions_start_with( versions, starter )
      highest_version = VersionService.newest_version_from( possible_vers )
      if highest_version
        return highest_version.version
      else
        return v
      end
    else
      v
    end
  end

  def product name
    prod_key = name.downcase
    products = Product.where({:language => @@language, :prod_key => prod_key, })
    Rails.logger.warn "more than one Product found for (#{@@language}, #{prod_key})"
    products.first
  end

  def latest_version_of_dependency name
    puts "create_dependency '#{name}' (name only => latest stable version)"

    prod_key = name.downcase
    product = product(prod_key)
    version = nil
    version = product.version if product

    Projectdependency.new \
      :language => @@language,
      :prod_key => prod_key,
      :name     => name,
      :version_requested => version
  end

end
