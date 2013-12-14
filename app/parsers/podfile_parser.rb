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


class PodfileParser < CommonParser

  attr_reader :language, :project_type

  attr_accessor :pod_file, :url
  attr_accessor :project

  def initialize
    @language     = Product::A_LANGUAGE_OBJECTIVEC
    @project_type = Project::A_TYPE_COCOAPODS
  end

  def parse_file filename
    @pod_filename = filename
    @pod_file = Pod::Podfile.from_file( @pod_filename )
    create_project
  end

  def parse url
    @url = url
    return nil if url.to_s.empty?

    begin
    @pod_file = Pod::Podfile.from_url( url )
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    create_project
  end

  def create_project
    @project  = init_project
    create_dependencies
    @project
  end

  # TODO: are there projects that gets updated?
  def init_project
    Project.new \
      project_type: project_type,
      language: language,
      url: url
  end


  def create_dependencies
    # TODO make scopes out of the target definitions
    # target_def = @pod_hash["target_definitions"]

    deps = pod_file.dependencies

    hash_array = deps.map do |dep|
      hash = {name: dep.name, version: dep.requirement.as_list}
      hash[:spec], hash[:subspec] = CocoapodsPackageManager.spec_subspec( dep.name )
      hash
    end

    specs = ( hash_array.map { |hash| hash[:spec] } ).uniq
    specs_and_versions = hash_array.inject({}) do |result,hash|
      spec = hash[:spec]
      if specs.member? spec
        result[spec] = hash[:version]
        specs.delete spec
      end
      result
    end

    specs_and_versions.each_pair do |spec, version|
      create_dependency(spec, version)
    end

    @project.dep_number = @project.projectdependencies.count
    Rails.logger.info "Project has #{@project.projectdependencies.count} dependencies"
  end

  def create_dependency dep_name, requirements
    if dep_name.nil?
      Rails.logger.debug "Problem: don't know how to handle #{dep_name}"
      return nil
    end

    product = load_product( dep_name )

    # prod_key should be nil if there is no such product
    prod_key = nil
    prod_key ||= product.prod_key if product

    requirement = requirements.map do |req_version|
      v_hash = version_hash(req_version, dep_name, product)
      Rails.logger.debug "VERSION HASH IS #{v_hash}"
      v_hash
    end

    Rails.logger.debug "create_dependency '#{dep_name}' -- #{requirement}"

    dependency = Projectdependency.new({
      :language => language,
      :prod_key => prod_key,
      :name     => dep_name,

      :version_requested  => requirement.first[:version_requested],
      :comperator         => requirement.first[:comperator],
      :version_label      => requirement.first[:version_label]
      })


    @project.out_number     += 1 if dependency.outdated?
    @project.unknown_number += 1 if dependency.prod_key.nil?
    @project.projectdependencies.push dependency
    dependency.save
    dependency
  end

  def version_hash version_from_file, prod_name, product
    if [:git, :head].member? version_from_file
      Rails.logger.debug "WARNING dependency '#{prod_name}' requires GIT" # TODO
      {:version_requested => "GIT", :version_label => "GIT", :comperator => "="}

    elsif :path == version_from_file
      Rails.logger.debug "WARNING dependency '#{prod_name}' requires PATH" # TODO
      {:version_requested => "PATH", :version_label => "PATH", :comperator => "="}

    else
      comperator_version = CocoapodsPackageManager.parse_version_constraint( version_from_file )

      # TODO copy composer for version ranges

      comperator = comperator_version[:comperator]
      version    = comperator_version[:version_requested]

      if product
        version_requested = CocoapodsPackageManager.choose_version(comperator, version, product.versions)
        return {:version_requested => version_requested, :version_label => version_from_file, :comperator => comperator}
      end

      {:version_requested => version, :version_label => version_from_file, :comperator => comperator}
    end
  end

  # It is important that this method is not writing into the database!
  #
  def parse_requested_version(version_number, dependency, product)
    CocoapodsPackageManager.parse_requested_version( version_number, dependency, product )
  end


  def load_product name
    prod_key = name.downcase
    products = Product.where({:language => language, :prod_key => prod_key, })
    return nil if products.nil? || products.empty?
    if products.count > 1
      Rails.logger.error "more than one Product found for (#{language}, #{prod_key})"
    end
    products.first
  end

end
