class UserlinkcollectionMigration

  def self.migrate_to_abs_links 
    links = Userlinkcollection.all 
    links.each do |link|
      link.convert_to_abs
    end
  end

end