require 'cocoapods-core'

# This parser parses the podfile for any CocoaPods project
# and creates and stores a Project model in VersionEye
#
# TODO doc url

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
    # TODO
  end

  def parse_file filename
    @pod_filename = filename
    @pod_file = Pod::Podfile.from_file @pod_filename
    @pod_hash = @pod_file.to_hash

    @project = get_project

    create_dependencies

    @project
  end

  # TODO: are there projects that gets updated
  def get_project
    project = Project.new \
      project_type: @@project_type,
      language: @@language,
      url: @url
    project
  end


  def create_dependencies
    # TODO this are differen compile targets
    target_def = @pod_hash["target_definitions"]

    puts "dependencies: #{@pod_file.dependencies}"
    puts "target_def: #{target_def}"

    if 1 < target_def.size # TODO make scopes out of the target definitions
      Rails.logger.warn "found more than one target definition for " # TODO

    elsif target_def.empty?
      Rails.logger.warn "no target definitions found for" # TODO

    else
      dependencies = target_def.first["dependencies"]
      dependencies.each do |dep|
        create_dependency dep
     end

    end
  end

  def create_dependency dep
    # TODO load product.
    # TODO If there is no product in DB, than just set coperator & version.
    # It will marked as unknown.
    if dep.is_a? String
      name = dep
      puts "create_dependency '#{name}' (name only)"

      dependency = Projectdependency.new \
        :language => @@language,
        :prod_key => name.downcase,
        :name     => name
        :version_requested => "" # TODO latest from DB.

    elsif dep.is_a? Hash
      name = dep.keys.first
      reqs = dep[name]

      requirements = reqs.map do |r|
        if :head == r
          puts "WARNING dependency '#{name}' requires HEAD (#{dep})" # TODO
          return {:version_requested => "HEAD", :version_label => "HEAD"}
        else
          # TODO parse version + comperator with VersionService.
          return parse_compare_version r
        end
      end

      puts "create_dependency '#{name}' -- #{requirements}"

      dependency = Projectdependency.new \
        :language => @@language,
        :prod_key => name.downcase,
        :name     => name,
        :version_requested  => requirements[:version_requested],
        :comperator         => requirements[:comperator]

    end

    dependency.save
    dependency.outdated?
  end

  VERSION_REGEXP = /^(=|!=|>=|>|<=|<|~>)\s*(\d(\.\d(\.\d)?)?)/
  def parse_compare_version string
    string.match VERSION_REGEXP
    comperator, version = $1, $2
    return {:comperator => comperator, :version_requested => version}
  end
end
