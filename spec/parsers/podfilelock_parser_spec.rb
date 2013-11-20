require 'spec_helper'
# require 'cocoapods_spec_helper'

describe PodfilelockParser do

  def parser
    PodfilelockParser.new
  end

  # set up products in different versions
  def cocoa_product(product_name, latest_version, *other_versions)
    new_product = ProductFactory.create_for_cocoapods(product_name, latest_version)
    other_versions.each do |a_version|
      new_product.versions.push(Version.new({:version => a_version}))
    end
    new_product.save
    new_product
  end

  # parse and check for the right language and project type
  def parse_and_check filepath
    project = parser.parse_file filepath
    project.should be_true
    project.language.should eq Product::A_LANGUAGE_OBJECTIVEC
    project.project_type.should eq Project::A_TYPE_COCOAPODS
    project
  end

  # get a certain dependency from the project
  def get_dependency project, name
    project.dependencies.each do |dep|
      return dep if dep.name.eql?( name )
    end
    return nil
  end

  # test the versions and if the requested version is outdated
  def test_dependency dep, version_latest, version_requested, outdated
    puts "dependency #{dep.name} version #{dep.version_current}"
    dep.version_current.should eq(version_latest)
    dep.version_requested.should eq(version_requested)
    dep.outdated.should eq(outdated)
  end


  describe '#parse' do

    it "should HTTP-get a lockfile and return a project with dependencies" do
      # project =
    end

  end

  describe '#parse_file' do

    def create_products
      cocoa_product("Masonry", "0.3.0",  "0.2.4",  "0.2.3")
      cocoa_product("RestKit", "0.22.0", "0.20.3", "0.10.3")
      cocoa_product("UIColor-Utilities", "1.0.1",  "1.0")
      cocoa_product("CupertinoYankee",   "1.0.0",  "0.1.1", "0.1")
      cocoa_product("MSCollectionViewCalendarLayout", "1.0")
    end

    it "should read a lockfile from disk and return a project with dependencies" do
      project = parse_and_check 'spec/fixtures/files/podfilelock/example1/Podfile.lock'

      puts project
      puts project.projectdependencies

      dep = get_dependency(project, "Masonry")
      test_dependency(dep, "0.3.0",  "0.2.4", true)

      dep = get_dependency(project, "RestKit")
      test_dependency(dep, "0.22.0", "0.20.3", true)

      dep = get_dependency(project, "UIColor-Utilities")
      test_dependency(dep, "1.0.1", "1.0.1", false)

      dep = get_dependency(project, "CupertinoYankee")
      test_dependency(dep, "1.0.0", "0.1.1", true)

      dep = get_dependency(project, "MSCollectionViewCalendarLayout")
      test_dependency(dep,  "1.0", "0.1.2", true)
    end

  end

end
