require 'spec_helper'

describe Userlinkcollection do

  let(:link) { Userlinkcollection.new }

  describe 'empty?' do

    it 'it is empty ' do
      link.empty?().should be_true
    end

    it 'it is not empty ' do
      link.github = "https://github.com/reiz"
      link.empty?().should be_false
    end

  end

  describe 'github_empty?' do

    it 'github is empty ' do
      link.github_empty?().should be_true
    end

    it 'github is empty ' do
      link.github = ""
      link.github_empty?().should be_true
    end

    it 'github is empty ' do
      link.github = nil
      link.github_empty?().should be_true
    end

    it 'github is not empty ' do
      link.github = "https://github.com/reiz"
      link.github_empty?().should be_false
    end

  end

end
