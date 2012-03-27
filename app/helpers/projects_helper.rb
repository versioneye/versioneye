module ProjectsHelper
  
  def version_color(version, current_version)
    if (version.eql? current_version)
      return "green"
    else
      return "red"
    end
  end
  
end