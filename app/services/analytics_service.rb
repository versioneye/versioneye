class AnalyticsService

  # this class provides business analytics services to find out which products our users really need

  def self.most_followed_products
    Language.each do |lang|
      most_followed_prods lang
    end
  end

  def self.most_followed_prods lang
    puts "Language #{lang.name}"
    puts '--------'

    Product.where({ :language => lang.name }).desc(:followers).limit(10).each do |p|
      puts "#{p.name} has #{p.followers} Followers - https://www.versioneye.com/#{p.language_esc}/#{p.to_param}"
    end

    puts "\n\n"
  end

  def self.most_referenced_prods lang
    puts "Language #{lang.name}"
    puts '--------'

    Product.where({ :language => lang.name }).desc(:used_by_count).limit(10).each do |p|
      puts "#{p.name} has #{p.used_by_count} References - https://www.versioneye.com/#{p.language_esc}/#{p.to_param}"
    end

    puts "\n\n"
  end

  def self.most_used_dependencies_csv filename='most_used_dependencies.csv'
    # get all used dependencies and sort descending by count
    deps = used_dependencies.sort_by {|dep| -dep['value']['count']}

    # we map every record to csv format (csv is an array of records)
    csv = deps.map {|x| "#{x['_id']}; #{x['value']['count'].to_int}"}

    # open the file and write to it. (maybe don't join before writing but use csv.each or similar)
    File.open(filename, 'w') {|f| f.write(csv.join("\n"))}
  end

  def self.used_dependencies

    # we map all Projectdependencies to the language and prod_key the project depend upon
    # key: "<language>; <prod_key>" (this is already csv format, maybe improve and make array or hash)
    # val: count=1
    map = %Q{
      function() {
        emit(this.language + "; " + this.prod_key , { count: 1 });
      }
    }

    # and then reduce by adding up all the counts for each key
    # result: count = how often is on product used in projects
    reduce = %Q{
      function(key, values) {
        var result = { count: 0 };
        values.forEach(function(value) {
          result.count += value.count;
        });
        return result;
      }
    }

    Projectdependency.all.map_reduce(map, reduce).out(inline: true)

  end


end
