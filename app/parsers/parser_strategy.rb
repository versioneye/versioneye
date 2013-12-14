class ParserStrategy

  def self.parser_for( project_type, url )
    case project_type
      when Project::A_TYPE_MAVEN2
        if url.match(/pom.json/)
          return PomJsonParser.new
        else
          return PomParser.new
        end

      when Project::A_TYPE_PIP
        if url.match(/requirements.txt/) || url.match(/pip.log/)
          return RequirementsParser.new
        else
          return PythonSetupParser.new
        end

      when Project::A_TYPE_COCOAPODS
        if url.match(/Podfile.lock/)
          return PodfilelockParser.new
        else
          return PodfileParser.new
        end

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

      when Project::A_TYPE_COCOAPODS
        if url.match(/\.podspec/i)
          return CocoapodsPodspecParser.new
        else
          return PodFileParser.new
        end
      else
        return nil
    end
  end

end
