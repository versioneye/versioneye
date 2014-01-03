class ProductResourceFactory

  def self.create_new(extra_data = nil, save_db = true)
    test_url = "http://www.versioneye.com/test/#{Random.rand(1..10000)}"
    resource_type = ["maven", "github"].sample(1).first

    resource_data = {
      :url => test_url,
      :resource_type => resource_type
    }

    resource_data.merge!(extra_data) unless extra_data.nil?
    new_resource = ProductResource.new(resource_data)

    new_resource.save if save_db
    return new_resource
  end

  def self.init_db
    self.store_resource('php/php-src')
    self.store_resource('jquery/jquery')
    self.store_resource('jquery/jquery-mobile')
    self.store_resource('tonytomov/jqGrid')
    self.store_resource('sstephenson/prototype')
    self.store_resource('phonegap/phonegap')
    self.store_resource('documentcloud/underscore')
    self.store_resource('madrobby/scriptaculous')
    self.store_resource('mootools/mootools-core')
    self.store_resource('DmitryBaranovskiy/raphael')
    self.store_resource('sorccu/cufon')
    self.store_resource('ztellman/aleph')
    self.store_resource('ztellman/lamina')
    self.store_resource('ztellman/gloss')
    self.store_resource('chaos/slurm')
    self.store_resource('chaos/lustre')
    self.store_resource('chaos/zfs')
    self.store_resource('chaos/diod')
  end

  def self.store_resource(name)
    github_api = 'https://api.github.com/repos/'
    resource_01_url = "#{github_api}#{name}"
    resource_01 = ProductResource.new({
      :url => resource_01_url,
      :name => name,
      :resource_type => Project::A_TYPE_GITHUB
      })
    resource_01.save
  end

end

