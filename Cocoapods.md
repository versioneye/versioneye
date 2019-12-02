Cocoapods
=========


1. setup
`git clone https://github.com/CocoaPods/Specs.git ~/versioneye/cocoapods-spec`

2. get updates
`git pull`

3. traverse all dirs, parse Specs, update database

### Podspec files naming scheme:

<product>/<version>/<product>.podspec

Q: are there more than on podspec file per dir?

### Podspec example

```ruby

Pod::Spec.new do |s|
  name    = "twitter-text-objc"
  url     = "https://github.com/twitter/#{name}"
  git_url = "#{url}.git"

	s.name     = name
	s.version  = "1.6.1"
	s.license  = { :type => 'Apache License, Version 2.0' }
	s.summary  = "Objective-C port of the twitter-text handling libraries."
	s.homepage = url
	s.source   = { :git => 'https://github.com/twitter/twitter-text-objc.git',
								 :tag => "v#{s.version}"
							 }

	s.source_files 	 = "lib/**/*.{h,m}"
	s.author         = { "Twitter, Inc." => "opensource@twitter.com" }

	s.ios.deployment_target = '4.0'
	s.osx.deployment_target = '10.7'

end
```


```ruby
require 'cocoapods-core'
podspec = Pod::Spec.from_file('/Users/anjaresmer/Code/cocoapods-specs/twitter-text-objc/1.6.1/twitter-text-objc.podspec')
```
