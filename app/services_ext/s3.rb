class S3

  def self.url_for filename
    return nil if filename.nil? || filename.empty?
    AWS::S3::S3Object.url_for(filename, Settings.s3_projects_bucket, :authenticated => true)
  end

  def self.infographic_url_for filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_infographics_bucket, :authenticated => false)
  end

  def self.delete filename
    return nil if filename.nil? || filename.empty?
    AWS::S3::S3Object.delete filename, Settings.s3_projects_bucket
  end

  def self.upload_fileupload fileUp
    orig_filename =  fileUp['datafile'].original_filename
    fname = self.sanitize_filename(orig_filename)
    random = Project.create_random_value
    filename = "#{random}_#{fname}"

    self.store_in_project_bucket filename, fileUp['datafile'].read

    filename
  rescue => e
    Rails.logger.error "Exception in S3.upload_fileupload(fileUp) - #{e.message}"
    Rails.logger.error e.backtrace.join "\n"
    nil
  end

  def self.upload_github_file file, filename
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

  def self.connect
    # AWS::S3::Base.establish_connection!(
    #   :access_key_id     => Settings.aws_s3_access_key_id,
    #   :secret_access_key => Settings.aws_s3_secret_access_key )
    AWS::S3::Base.establish_connection!(
      :access_key_id     => Settings.aws_s3_access_key_id,
      :secret_access_key => Settings.aws_s3_secret_access_key,
      :server => "localhost",
      :port => "4567"
    )
  rescue => e
    p "error in s3.connect: #{e.message}"
    p e.backtrace.message
  end

  def self.store_in_project_bucket filename, bin
    self.connect
    AWS::S3::S3Object.store( filename, bin, Settings.s3_projects_bucket, :access => "private")
  rescue => e
    p "Error in store_in_project_bucket: #{e.message}"
    p e.backtrace.message

    # AWS::S3::S3Object.store( filename, bin, Settings.s3_projects_bucket, :access => "private")
  end

  private

    def self.sanitize_filename(file_name)
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

end
