class LeinParser < CommonParser
	def self.parse(url)
		#get content
		return nil if url.nil? 
		#content = self.fetch_response(url).body
		#return nil if content.nil?

		content = url
		#parse dependencies
		re = %r{
			  (?<re>
			    \[]
			      (?:
			        (?> [^()]+ )
			        |
			        \g<re>
			      )*
			    \]
			  )
			}x

		content.scan(re)



	end

	def self.build_dependencies()

	end
end