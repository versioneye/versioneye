class LanguageDailyStatsMigraiton

  def self.make_dummy_data(ndays = 60, prod_per_day = 100)
    (ndays+1).times do |nday|
      prod_per_day.times do |nprod|
        prod = Product.random_product
        newest = Newest.new({
          name: prod[:name],
          language: prod[:language],
          version: self.inc_dummy_version(prod),
          prod_key: prod[:prod_key],
          prod_type: prod[:prod_type],
          product_id: prod[:_id].to_s,
          created_at: (ndays - nday).days.ago #start from oldest to keep version numbers incremental
        })
        begin
          newest.save
        rescue
          p "no dummy data for: #{prod[:prod_key]} - #{newest.errors.full_messages.to_sentence}"
        end
      end
    end
  end

  def self.inc_dummy_version(prod)
    latest_release = Newest.where(
      language: prod[:language],
      prod_key: prod[:prod_key]).desc(:created_at).first

    unless latest_release.nil?
      version_numbers = latest_release[:version].to_s.split(".")
    else
      version_numbers = prod[:version].to_s.split(".")
    end

    version_numbers = ["1"] if version_numbers.empty?

    updated_last_number = version_numbers.slice!(-1).to_i + 1
    version_numbers.push(updated_last_number)
    version_numbers = version_numbers.join('.')
    version_numbers += "-dummy" if version_numbers == prod[:version]
    version_numbers
  end

end
