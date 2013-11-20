require 'cocoapods-core'

class PodLockFileParser < CommonParser

  #Pod::Lockfile
  
  def parse_file filename
    @lock_filename = filename
    pathname = Pathname.new @lock_filename
    @lock_file = Pod::Lockfile.from_file pathname
    create_project
  end

  def create_project
    @project = init_project
    create_dependencies
    @project
  end

  def init_project
    Project.new \
      project_type: Project::A_TYPE_COCOAPODS,
      language: Product::A_LANGUAGE_OBJECTIVEC,
      url: @url
  end

  def create_project
    @pod_file.dependencies.each do |d|
      create_dependency d.name => d.requirement.as_list
    end

    @project.dep_number = @project.projectdependencies.count
    Rails.logger.info "Project has #{@project.projectdependencies.count} dependencies"
  end

  def create_dependency dep
    if dep.nil?
      Rails.logger.debug "Problem: try to create_dependency(nil)"
      return nil
    end

    dependency = create_dependency_from_hash( dep )
    @project.out_number     += 1 if dependency.outdated?
    @project.unknown_number += 1 if dependency.prod_key.nil?
    @project.projectdependencies.push dependency
    dependency.save
    dependency
  end
end