namespace :versioneye do

  # ***** XML Sitemap Tasks *****

  desc "create XML site map"
  task :xml_sitemap => :environment do
    puts "START to export xml site map"
    ProductMigration.xml_site_map
    puts "---"
  end

  # ***** Admin tasks *****

  desc "create default admin"
  task :init_enterprise => :environment do
    puts "START to create default admin"
    AdminService.create_default_admin
    Plan.create_defaults
    EsProduct.reset
    EsUser.reset
    puts "---"
  end

end
