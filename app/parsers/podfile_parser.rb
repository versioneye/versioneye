require 'cocoapods-core'

# This parser parses the podfile for any CocoaPods project
# and creates and stores a Project model in VersionEye
#
# use like this:
#
#    PodfileParser.new.parse 'https://raw.github.com/CocoaPods/CocoaPods/master/spec/fixtures/Podfile'
#
# or parse a single Podfile on the filesystem
#
#    PodfileParser.new.parse_file '/path/to/the/Podfile'
#

module Pod
  class Podfile
    # Configures a new Podfile from the given url.
    #
    # @param  [String] url
    #         The url which will configure the podfile with the DSL.
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
          Rails.logger.error e
          message = "Invalid url `#{url}`: #{e.message}"
          raise DSLError.new(message, url, e.backtrace)
        end
      end

      podfile

    end
  end

end


class PodfileParser < CommonParser

  @@language     = Product::A_LANGUAGE_OBJECTIVEC

  attr_accessor :pod_file, :pod_hash
  @url = ""

  def parse_file filename
    @pod_filename = filename
    @pod_file = Pod::Podfile.from_file @pod_filename
    create_project
  end

  def parse url
    @url = url
    return nil if url.to_s.empty?
    podfile = fetch_response_body( url )
    return nil if podfile.nil?

    @pod_file = Pod::Podfile.from_url url

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
      project_type: Project::A_TYPE_COCOAPODS,
      language: @@language,
      url: @url
  end


  def create_dependencies
    # TODO make scopes out of the target definitions
    # target_def = @pod_hash["target_definitions"]

    # I had problems getting correct dependencies from
    # the hash for some targets, so I now get all
    # all dependencies and forget about the target's first
    @pod_file.dependencies.each do |d|
      create_dependency d.name => d.requirement.as_list
    end

    @project.dep_number = @project.projectdependencies.count
    Rails.logger.info "Project has #{@project.projectdependencies.count} dependencies"
  end

  def create_dependency dep
    if dep.nil?
      Rails.logger.debug "Problem: don't know how to handle #{dep}"
      return nil
    end

    dependency = create_dependency_from_hash( dep )
    @project.out_number     += 1 if dependency.outdated?
    @project.unknown_number += 1 if dependency.prod_key.nil?
    @project.projectdependencies.push dependency
    dependency.save
    dependency
  end

  def create_dependency_from_hash dep_hash
    name = dep_hash.keys.first
    reqs = dep_hash[name]

    prod_key = nil
    product = load_product( name )
    prod_key = product.prod_key if product

    requirement = reqs.map do |req_version|
      v_hash = version_hash(req_version, name, product)
      Rails.logger.debug "VERSION HASH IS #{v_hash}"
      v_hash
    end

    Rails.logger.debug "create_dependency '#{name}' -- #{requirement}"

    dependency = Projectdependency.new({
      :language => @@language,
      :prod_key => prod_key,
      :name     => name,
      :version_requested  => requirement.first[:version_requested],
      :comperator         => requirement.first[:comperator],
      :version_label      => requirement.first[:version_label]
      })

    dependency
  end

  VERSION_REGEXP = /^(=|!=|>=|>|<=|<|~>)\s*(\d(\.\d(\.\d)?)?)/
  def parse_version string
    string.match VERSION_REGEXP
    comperator, version = $1, $2
    return {:comperator => comperator, :version_requested => version}
  end

  def version_hash version_from_file, prod_name, product
    if [:git, :head].member? version_from_file
      Rails.logger.debug "WARNING dependency '#{prod_name}' requires GIT" # TODO
      return {:version_requested => "GIT", :version_label => "GIT", :comperator => "="}

    elsif :path == version_from_file
      Rails.logger.debug "WARNING dependency '#{prod_name}' requires PATH" # TODO
      return {:version_requested => "PATH", :version_label => "PATH", :comperator => "="}

    else
      comperator_version = parse_version version_from_file
      # TODO copy composer for version ranges

      comperator = comperator_version[:comperator]
      version    = comperator_version[:version_requested]

      if product
        version_requested = best_version(comperator, version, product.versions)
        return {:version_requested => version_requested, :version_label => version_from_file, :comperator => comperator}
      end

      return {:version_requested => version, :version_label => version_from_file, :comperator => comperator}
    end
  end

  # It is important that this method is not writing into the database!
  #
  def parse_requested_version(version_number, dependency, product)
    # This method has to be on every parser.
  end

  def best_version(comperator, version, versions)
    case comperator
    when ">"
      VersionService.greater_than(versions, version).version
    when ">="
      VersionService.greater_than_or_equal(versions, version).version
    when "<"
      VersionService.smaller_than(versions, version).version
    when "<="
      VersionService.smaller_than_or_equal(versions, version).version
    when "~>"
      starter         = VersionService.version_approximately_greater_than_starter( version )
      possible_vers   = VersionService.versions_start_with( versions, starter )
      highest_version = VersionService.newest_version_from( possible_vers )
      return highest_version.to_s if highest_version
      return version
    else
      version
    end
  rescue => e
    Rails.logger.error e.message
    version
  end

  def load_product name
    prod_key = name.downcase
    products = Product.where({:language => @@language, :prod_key => prod_key, })
    return nil if products.nil? || products.empty?
    if products.count > 1
      Rails.logger.error "more than one Product found for (#{@@language}, #{prod_key})"
    end
    products.first
  end

end
