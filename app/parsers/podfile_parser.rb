require 'cocoapods-core'

# This parser parses the podfile for any CocoaPods project
# and creates and stores a Project model in VersionEye
#
# TODO doc url

class PodFileParser < CommonParser

  #Pod::Podfile
  #Pod::Lockfile

  @@project_type = Project::A_TYPE_COCOAPODS
  @@language     = Product::A_LANGUAGE_OBJECTIVEC

  def initialize
    # TODO not sure what to put here
  end

  def parse_file file
    @podfile = load_podfile file
    @project = get_project
    @project
  end

  def load_podfile file
    Pod::Podfile.new file
  end

  def get_project
    project = Project.new project_type: @@project_type, language:@@language

    project.save
    project
  end


end