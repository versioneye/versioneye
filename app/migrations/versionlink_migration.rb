class VersionlinkMigration

  def self.rename_version_id
    links = Versionlink.all
    total = links.count
    links.each_with_index do |link, i|
      p "#{i}/#{total}" if (i % 1000) == 0
      if not link.has_attribute?(:version) or link[:version].nil?
        link.update_attributes({version: link[:version_id]})
      end
    end
  end

end
