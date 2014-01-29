require 'spec_helper'
require 'vcr'
require 'webmock'

require 'capybara/rails'
require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end


describe BitbucketService do
  include Capybara::DSL

  let(:user){create(:bitbucket_user, 
                    :bitbucket_token => 'YsR6vM5qxmfZtkYt9G',
                    :bitbucket_secret => 'raEFhqE2YuBZtwqswGXFRZEzLnnLD8Lu',
                    :bitbucket_login => Settings.bitbucket_username )}

  context "as authorized user" do
    before :each do
      user.save
      user[:bitbucket_token].should_not be_nil
      user[:bitbucket_secret].should_not be_nil
    end

    it "caches all bitbucket repositories user owns" do
      VCR.use_cassette('bitbucket_service_cache_user_repos', allow_playback_repeats: true) do
        BitbucketService.cache_repos(user, user[:bitbucket_id])
        user.reload
        user.bitbucket_repos.count.should eq(3)
        repo_names = Set.new user.bitbucket_repos.map(&:fullname)
        repo_names.include?("versioneye_test/emptyrepo").should be_true
        repo_names.include?("versioneye_test/fantom_hydra").should be_true
        repo_names.include?("versioneye_test/fantom_hydra_private").should be_true
      end
    end

    it "caches all bitbucket repositories user got invitations" do
      VCR.use_cassette('bitbucket_service_cache_user_invited_repos', allow_playback_repeats: true) do
        BitbucketService.cache_repos(user, user[:bitbucket_id])
        BitbucketService.cache_invited_repos(user)
        
        user.reload
        user.bitbucket_repos.count.should eq(4)
        repo_names = Set.new user.bitbucket_repos.map(&:fullname)
        repo_names.include?("timgluz/clj-sparse").should be_true
      end
    end
  end
end
