module VersionEye
  module ProductHelpers
    def parse_query(query)
        query = query.to_s
        query = query.strip().downcase 
        query.gsub!(/\%/, "")
        query
    end

    def get_language_param(lang)
      lang = lang.to_s
      lang = "," if lang.empty?
      lang
    end

    def get_language_array(lang)
      languages = []
      special_languages = {
        "php" => "PHP",
        "node.js" =>  "Node.JS",
        "nodejs" => "Node.JS"
      }

      langs = lang.split(",")
      langs.each do |language|
        language = language.to_s.strip.downcase
        unless language.empty?
          if special_languages.has_key? language
            languages << special_languages[language]
          else
            languages << language.capitalize
          end
        end
        
        languages
      end
    end

    def get_product_key(prod_key)
      prod_key.to_s.gsub("--", "/").gsub("~", ".")
    end

  end
end
