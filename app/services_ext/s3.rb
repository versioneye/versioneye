class S3

  def self.url_for filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_projects_bucket, :authenticated => true)
  end

  def self.infographic_url_for filename
    AWS::S3::S3Object.url_for(filename, Settings.s3_infographics_bucket, :authenticated => false)
  end

  def self.delete filename
    AWS::S3::S3Object.delete filename, Settings.s3_projects_bucket
  end

  def self.upload_fileupload( fileUp )
    orig_filename =  fileUp['datafile'].original_filename
    fname = self.sanitize_filename(orig_filename)
    random = Project.create_random_value
    filename = "#{random}_#{fname}"
    AWS::S3::S3Object.store(filename,
      fileUp['datafile'].read,
      Settings.s3_projects_bucket,
      :access => "private")
    filename
  end

  def self.upload_github_file(file, filename)
    file_bin = file['content']
    random_value = Project.create_random_value
    new_filename = "#{random_value}_#{filename}"
    AWS::S3::S3Object.store(
      new_filename,
      Base64.decode64(file_bin),
      Settings.s3_projects_bucket,
      :access => "private")
    url = S3.url_for(new_filename)
    result = Hash.new
    result['filename'] = new_filename
    result['s3_url'] = url
    result
  end

  private

    def self.sanitize_filename(file_name)
      just_filename = File.basename(file_name)
      just_filename.sub(/[^\w\.\-]/,'_')
    end

end
