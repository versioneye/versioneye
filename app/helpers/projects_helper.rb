module ProjectsHelper

  def outdated_color project
    return 'red' if project.out_number_sum.to_i > 0
    'green'
  end

  def unknown_color project
    return 'orange' if project.unknown_number_sum.to_i > 0
    'green'
  end

  def licenses_red_color project
    return 'red' if project.licenses_red_sum.to_i > 0
    'green'
  end

  def licenses_unknown_color project
    return 'orange' if project.licenses_unknown_sum.to_i > 0
    'green'
  end

  def subproject_label_color selected_id, sub_id 
    return "success" if selected_id.eql?(sub_id)
    "warn"
  end

  def subproject_name( project )
    name = project.filename 
    if name.to_s.empty? 
      name = project.name 
    end 
    name 
  end

  def path_to_stash_file project
    repo = project.scm_fullname.gsub("/", "/repos/")
    branch = URI.encode("refs/heads/#{project.scm_branch}")
    "#{Settings.instance.stash_base_url}/projects/#{repo}/browse/#{project.filename}?at=#{branch}"
  end

  def path_to_bitbucket_branch project
    "https://bitbucket.org/#{project.scm_fullname}/branch/#{project.scm_branch}"
  end

  def path_to_bitbucket_file project
    "https://api.bitbucket.org/1.0/repositories/#{project.scm_fullname}/raw/#{project.scm_revision}/#{project.filename}"
  end

  def path_to_github_branch project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/tree/#{project.scm_branch}"
  end

  def path_to_github_file project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/blob/#{project.scm_branch}/#{project.filename}"
  end

  def add_dependency_classes project
    return nil if project.nil?

    deps = project.dependencies
    return project if deps.nil? or deps.empty?

    out_number = 0
    unknown_number = 0

    deps.each do |dep|
      if dep.unknown?
        dep[:status_class] = 'info'
        dep[:status_rank] = 4
        unknown_number += 1
      elsif dep.outdated and dep.release? == false
        dep[:status_class] = 'warn'
        dep[:status_rank] = 2
        out_number += 1
      elsif dep.outdated and dep.release? == true
        dep[:status_class] = 'error'
        dep[:status_rank] = 1
        out_number += 1
      else
        dep[:status_class] = 'success'
        dep[:status_rank] = 3
      end
    end
    project.out_number = out_number
    project.unknown_number = unknown_number
    project.save
    project
  end

  def merge_to_projects project 
    projs = []
    parents = []
    singles = []
    current_user.projects.each do |pro|
      next if pro.id.to_s.eql?(project.id.to_s)
      next if pro.parent_id
      if pro.children.count > 0 
        pro.has_kids = 1
        parents << pro 
      else 
        pro.has_kids = 0
        singles << pro 
      end 
    end
    parents = parents.sort_by {|obj| obj.name}
    singles = singles.sort_by {|obj| obj.name}
    projs << parents
    projs << singles
    projs.flatten
  end

end
