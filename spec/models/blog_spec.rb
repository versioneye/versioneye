require 'spec_helper'

describe Blog do
  
  before(:each) do
    @blog = Blog.new
    @bl = Blog.new
  end
  
  after(:each) do
    @blog.remove
    @bl.remove
  end
  
  describe "save" do
    
    it "it saves!" do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = nil
      @blog.save.should be_true
    end
    
    it "it does not save! Because there is no user." do
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save.should be_false
    end
    
    it "it does not save! Because subject is missing ." do
      @blog.user_id = 1
      @blog.subject = nil
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save.should be_false
    end
    
    it "it does not save! Because post is missing ." do
      @blog.user_id = 1
      @blog.subject = "subject"
      @blog.post = nil
      @blog.approved = false
      @blog.save.should be_false
    end
  
  end
  
  describe "find_approved_posts" do
    
    it "it is empty!" do
      blogs = Blog.find_approved_posts
      blogs.size.should eql(0)
    end
    
    it "it is empty! Because the one post is not approved!" do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save
      blogs = Blog.find_approved_posts
      blogs.size.should eql(0)
    end
    
    it "it returns 1 result! " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = true
      @blog.save
      blogs = Blog.find_approved_posts
      blogs.size.should eql(1)
    end
    
    it "it returns 2 result! " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = true
      @blog.save
      
      sleep 1
      
      @bl.user_id = 1
      @bl.subject = "Second post"
      @bl.post = "This is my second post"
      @bl.approved = true
      @bl.save
      
      blogs = Blog.find_approved_posts
      blogs.size.should eql(2)
      
      blogs.first.subject.should eql("Second post")
    end
    
  end
  
  describe "find_unapproved_posts" do
    
    it "it is empty!" do
      blogs = Blog.find_unapproved_posts
      blogs.size.should eql(0)
    end
    
    it "it returns 1 blog! Because the one post is not approved!" do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = nil
      @blog.save
      blogs = Blog.find_unapproved_posts
      blogs.size.should eql(1)
    end
    
    it "it returns 0 result! Because the one is approved " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = true
      @blog.save
      blogs = Blog.find_unapproved_posts
      blogs.size.should eql(0)
    end
    
    it "it returns 0 result! Because the one is declined " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save
      blogs = Blog.find_unapproved_posts
      blogs.size.should eql(0)
    end
    
    it "it returns 2 result! " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = nil
      @blog.save
      
      sleep 1
      
      @bl.user_id = 1
      @bl.subject = "Second post"
      @bl.post = "This is my second post"
      @bl.approved = nil
      @bl.save
      
      blogs = Blog.find_unapproved_posts
      blogs.size.should eql(2)
      
      blogs.first.subject.should eql("Second post")
    end
    
  end
  
  describe "find_user_posts" do
    
    it "it returns en empty array" do
      blogs = Blog.find_user_posts 4555242522
      blogs.size.should eql(0)
    end
    
    it "it returns 1 blog! Because the one post is not approved!" do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save
      blogs = Blog.find_user_posts 666
      blogs.size.should eql(0)
      blogs = Blog.find_user_posts 1
      blogs.size.should eql(1)
    end
    
    it "it returns 2 result! " do
      @blog.user_id = 1
      @blog.subject = "First post"
      @blog.post = "This is my first post"
      @blog.approved = false
      @blog.save
      
      sleep 1
      
      @bl.user_id = 1
      @bl.subject = "Second post"
      @bl.post = "This is my second post"
      @bl.approved = false
      @bl.save
      
      blogs = Blog.find_user_posts 1
      blogs.size.should eql(2)
      
      blogs.first.subject.should eql("Second post")
    end
    
  end
  
  describe "post_html" do
    
    it "it returns the simple post" do
      @blog.post = "test"
      @blog.post_html.should eql("test")
    end
    
    it "it returns the post with some breaks" do
      @blog.post = "test \n test"
      @blog.post_html.should eql("test <br/> test")
    end
    
    it "it returns an empty string" do
      @blog.post = nil
      @blog.post_html.should eql("")
    end
    
  end
  
end