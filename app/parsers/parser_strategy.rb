class ParserStrategy

  def self.parser_for( project_type, url )
    case project_type
      when Project::A_TYPE_MAVEN2
        return PomParser.new
      when Project::A_TYPE_PIP
        return RequirementsParser.new
      when Project::A_TYPE_NPM
        return PackageParser.new
      when Project::A_TYPE_GRADLE
        return GradleParser.new 
      when Project::A_TYPE_LEIN
        return LeinParser.new
      when Project::A_TYPE_RUBYGEMS
        if url.match(/Gemfile\.lock/)
          return GemfilelockParser.new
        else 
          return GemfileParser.new
        end
      when Project::A_TYPE_COMPOSER
        if url.match(/composer\.lock/i)
          return ComposerLockParser.new
        else
          return ComposerParser.new
        end  
    end
    nil
  end

end
