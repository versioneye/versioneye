require 'cocoapods-core'
require 'cocoapods_package_manager'

# This parser parses Cocoapods Podfile.lock file
#
#
# TODO: implement Subspecs

class PodfilelockParser < CommonParser

  # these are the same for all projects parsed with this parser
  attr_reader :language, :project_type

  # these are the inputs
  attr_accessor :lockfile_name, :url

  # these are the (intermediate) outputs
  attr_accessor :project, :lockfile


  def initialize
    @project_type = Project::A_TYPE_COCOAPODS
    @language     = Product::A_LANGUAGE_OBJECTIVEC
  end

  def parse url
    return nil unless url
    @url = url
    @lockfile = Pod::Lockfile.from_url url # from_url is monkey patched. You find it in cocoapods_package_manager.rb

    create_project
  end

  def parse_file filename
    return nil unless filename
    @lockfile_name  = filename

    pathname = Pathname.new filename
    @lockfile = Pod::Lockfile.from_file pathname

    create_project
  end

  def create_project
    @project = init_project
    Rails.logger.info "created project #{@project}"
    create_dependencies
    @project
  end

  def init_project
    Project.new \
      project_type: project_type,
      language: language,
      url: url
  end

  def create_dependencies
    pod_names = lockfile.pod_names

    hash_array = pod_names.map do |name|
      hash = {name: name, version: lockfile.version(name)}
      hash[:spec], hash[:subspec] = CocoapodsPackageManager.spec_subspec( name )
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
      create_dependency spec, version
    end

    @project.dep_number = @project.projectdependencies.count
    Rails.logger.info "Project has #{@project.projectdependencies.count} dependencies"
  end

  # spec should now be the spec without subspec
  def create_dependency spec, dep_version

    unless spec
      Rails.logger.debug "Problem: try to create_dependency(nil)"
      return nil
    end

    Rails.logger.debug "create_dependency '#{spec}' -- #{dep_version}"

    product  = load_product( spec )
    prod_key = nil
    prod_key ||= product.prod_key if product

    dependency = Projectdependency.new({
      :language => language,
      :prod_key => prod_key,
      :name     => spec,

      :version_requested  => dep_version,
      :comperator         => '=',
      :version_label      => dep_version
      })

    project.out_number     += 1 if dependency.outdated?
    project.unknown_number += 1 if dependency.prod_key.nil?
    project.projectdependencies.push dependency
    dependency.save
    dependency
  end

  def load_product name
    prod_key = name.downcase
    products = Product.where({:language => language, :prod_key => prod_key })
    if products.nil? || products.empty?
      Rails.logger.warn "no product found for language #{language} prod_key #{prod_key}"
      return nil
    elsif products.count > 1
      Rails.logger.error "more than one Product found for (#{language}, #{prod_key})"
    end

    products.first
  end
end
