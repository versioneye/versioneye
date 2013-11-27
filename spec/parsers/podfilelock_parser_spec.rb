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
      version_model = Version.new({:version => a_version})
      new_product.versions.push(version_model)
    end
    new_product.save
    # puts "created new #{new_product}"
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
    # puts "dependency #{dep.name} version #{dep.version_current}"
    dep.should be_true
    dep.version_current.should eq(version_latest)
    dep.version_requested.should eq(version_requested)
    dep.outdated.should eq(outdated)
  end


  describe '#parse' do

    it "should HTTP-get a lockfile and return a project with dependencies" do
      # project =
    end

    it "should drop subspecs and just use the main spec" do

      # TODO add this before so the subspecs are actually known
      # 'https://raw.github.com/CocoaPods/Specs/master/ShareKit/2.4.6/ShareKit.podspec'
      # 'https://raw.github.com/CocoaPods/Specs/master/xmlrpc/2.3.3/xmlrpc.podspec'

      lockfile_url = 'https://raw.github.com/DenisDbv/OpenAuth/master/Podfile.lock'
      project = parser.parse( lockfile_url )
      deps = project.dependencies

      deps.size.should eq(6)

      deps.each do |dep|
        %w{
          Facebook-iOS-SDK JSONKit NSData+Base64
          ShareKit xmlrpc SSKeychain}.should be_member(dep.name)
      end
    end


  end

  describe '#parse_file' do


    it "should read a lockfile from disk and return a project with dependencies" do

      # setup
      cocoa_product("Masonry", "0.3.0",  "0.2.4",  "0.2.3")
      cocoa_product("RestKit", "0.22.0", "0.20.3", "0.10.3")
      cocoa_product("UIColor-Utilities", "1.0.1",  "1.0")
      cocoa_product("CupertinoYankee",   "1.0.0",  "0.1.1", "0.1")
      cocoa_product("MSCollectionViewCalendarLayout", "1.0")

      # run
      project = parse_and_check 'spec/fixtures/files/podfilelock/example1/Podfile.lock'

      # compare
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

    it "should parse another Podfile.lock and return project with dependencies" do
      # setup
      cocoa_product("JRSwizzle", "1.0")

      # TODO: make something about these subspecs

      cocoa_product("libextobjc", "0.3", '0.2.5', '0.2.0', '0.1.0')
      cocoa_product("libextobjc/EXTConcreteProtocol", "0.3", '0.2.5', '0.2.0', '0.1.0')
      cocoa_product("libextobjc/EXTKeyPathCoding"   , "0.3", '0.2.5', '0.2.0', '0.1.0')
      cocoa_product("libextobjc/EXTScope"           , "0.3", '0.2.5', '0.2.0', '0.1.0')
      cocoa_product("libextobjc/RuntimeExtensions"  , "0.3", '0.2.5', '0.2.0', '0.1.0')

      cocoa_product("ReactiveCocoa"                 , '2.1.7', '2.1', '2.0.0', '1.9.7')
      cocoa_product("ReactiveCocoa/Core"            , '2.1.7', '2.1', '2.0.0', '1.9.7')
      cocoa_product("ReactiveCocoa/RACExtensions"   , '2.1.7', '2.1', '2.0.0', '1.9.7')

      # run
      project = parse_and_check 'spec/fixtures/files/podfilelock/example2/Podfile.lock'

      # compare
      project.should be_true

      dep = get_dependency(project, "JRSwizzle")
      test_dependency(dep, "1.0",  "1.0", false)

      dep = get_dependency(project, 'libextobjc')
      test_dependency(dep, "0.3", "0.2.5", true)

      dep = get_dependency(project, 'ReactiveCocoa')
      test_dependency(dep, "2.1.7", "1.8.0", true)

    end

  end

end
