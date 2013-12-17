class S3

  def self.url_for filename
    return nil if filename.to_s.empty?
    encoded_name = URI.encode( filename )
    url = AWS.s3.buckets[Settings.s3_projects_bucket].objects[encoded_name].url_for( :read, :secure => true )
    url.to_s
  end

  def self.infographic_url_for filename
    return nil if filename.to_s.empty?
    encoded_name = URI.encode( filename )
    url = AWS.s3.buckets[Settings.s3_infographics_bucket].objects[encoded_name].url_for( :read, :secure => true )
    url.to_s
  end

  def self.delete filename
    return nil if filename.nil? || filename.empty?
    AWS.s3.buckets[Settings.s3_projects_bucket].objects[filename].delete
  end

  def self.upload_fileupload file_up
    orig_filename = file_up['datafile'].original_filename
    fname         = self.sanitize_filename(orig_filename)
    random        = Project.create_random_value
    filename      = "#{random}_#{fname}"
    self.store_in_project_bucket filename, file_up['datafile'].read
    filename
  rescue => e
    Rails.logger.error "Exception in S3.upload_fileupload(file_up) - #{e.message}"
    Rails.logger.error e.backtrace.join "\n"
    nil
  end


  def self.upload_github_file file, filename
    return nil if file.nil? || filename.to_s.empty?
    file_bin     = file['content']
    random_value = Project.create_random_value
    new_filename = "#{random_value}_#{filename}"
    self.store_in_project_bucket new_filename, Base64.decode64(file_bin)
    url                = S3.url_for( new_filename )
    result             = Hash.new
    result['filename'] = new_filename
    result['s3_url']   = url
    result
  end

  def self.upload_file_content( content, filename)
    return nil if content.nil? || filename.to_s.empty?
    file_bin = content
    random_value = Project.create_random_value
    new_filename = "#{random_value}_#{filename}"
    self.store_in_project_bucket new_filename, file_bin #Base64.decode64(file_bin)
    url                = S3.url_for( new_filename )
    result             = Hash.new
    result['filename'] = new_filename
    result['s3_url']   = url
    result
  end

  def self.store_in_project_bucket filename, bin
    bucket = AWS.s3.buckets[Settings.s3_projects_bucket]
    obj    = bucket.objects[ filename ]
    obj.write bin
  rescue => e
    Rails.logger.error "Error in store_in_project_bucket: #{e.message}"
    Rails.logger.error e.backtrace.message
  end

  private

    def self.sanitize_filename file_name
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

end
