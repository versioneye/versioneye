require 'cocoapods-core'

# This parser parses Cocoapods Podfile.lock file
#
#
# TODO: test PodfilelockParser#parse( url )
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
    @lockfile = Pod::Lockfile.from_url url

    create_project
  end

  def parse_file filename
    return nil unless filename
    @lockfile_name = filename

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

    # lockfile.dependencies.each do |d|
    #   create_dependency d.name => d.requirement.as_list
    # end

    @lockfile.pod_names.each do |pod_name|
      version = lockfile.version(pod_name)
      create_dependency( pod_name, version.version )
    end

    @project.dep_number = @project.projectdependencies.count
    Rails.logger.info "Project has #{@project.projectdependencies.count} dependencies"
  end

  def create_dependency dep_name, dep_version

    unless dep_name
      Rails.logger.debug "Problem: try to create_dependency(nil)"
      return nil
    end

    dep_spec_name, subspec = CocoapodsPackageManager.spec_subspec( dep_name )

    Rails.logger.debug "create_dependency '#{dep_spec_name}' -- #{dep_version}"
    Rails.logger.debug "ignoring subspec #{subspec} of #{dep_name}" if subspec

    product  = load_product( dep_spec_name )
    prod_key = nil
    prod_key ||= product.prod_key if product

    dependency = Projectdependency.new({
      :language => language,
      :prod_key => prod_key,
      :name     => dep_spec_name,

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