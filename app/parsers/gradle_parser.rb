class GradleParser < CommonParser

	# Parses gradle dependecies from given url
	def self.build_dependencies(matches)
		#build and initiliaze array of dependencies.
		#Arguments array of matches, should be [[scope, group_id, arti, version],...]
		#Returns map {:unknowns => 0 , dependencies => []}
		data = []
		unknowns, out_number = 0, 0	
		matches.each do |row|
			#pp row 
			p "-----------------"
			dependency = Projectdependency.new({
				:scope => row[0],
				:group_id => row[1],
				:artifact_id => row[2],
				:name => row[2],
				:version_requested => row[3]	
			})
			product = Product.find_by_group_and_artifact(row[1], row[2])
			#pp product					
			if product
        		dependency.prod_key = product.prod_key
        	else 
        		p "group_id: #{row[1]} artifact_id: #{row[2]}"
        		unknowns += 1
      		end
      		pp "dep prod_key - #{dependency.prod_key}"
      
			out_number += 1 if dependency.outdated?
			#p "#{dependency.prod_key} - version current - #{dependency.version_current}"
			data << dependency
		end

		return {:unknowns => unknowns, :out_number => out_number, :dependencies => data}
	end

	def self.parse(url)
		#load file
		return nil if url.nil?
		content = self.fetch_response(url).body
		return nil if content.nil?
		#parse 
		dependecies_matcher = /
			(\w+) #scope
			[\s|\(]?[\'|\"]+ #scope separator
				([\w|\d|\.|\-|\_]+) #group_id
				:([\w|\d|\.|\-|_]+) #artifact
				:([\w|\d|\.|\-|_]+) #version number
		/xi

		#build object
		deps = self.build_dependencies(content.scan dependecies_matcher)
		return Project.new deps
	end
end