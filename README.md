[![Dependency Status](https://www.versioneye.com/user/projects/54985cc0818b9377d2000002/badge.svg?style=flat)](https://www.versioneye.com/user/projects/54985cc0818b9377d2000002)

# VersionEye

This is the source code for the web application <http://www.versioneye.com>.

## Git Flow

We are using the git workflow which is described here <http://nvie.com/posts/a-successful-git-branching-model/>!
That means the master branch is always deployable. For every feature we open a new brach. The naming pattern for branches is like this:

```
TICKET-ID_MEANINGFULL-SHORT-DESCRIPTION
```

for example

```
313_github_singlepage_app
```

Every branch has to be merged in to the `develop` branch as soon it is done.
Merges from develop to master are like tags and deployments. The master branch must always be stable and deployable!


## Tech Stack

This is the stack in this project:

 * Ruby on Rails
 * MongoDB
 * Memcache
 * ElasticSearch
 * Amazon S3 / SES

To start the application you need Ruby 1.9.3 and a running MongoDB instance.

### MongoDB

You will find downloads and tutorials to MongoDB here: <http://www.mongodb.org/>. To acess MongoDB from Ruby we are using mongoid: <http://mongoid.org>. The configuration to the MongoDB is placed at "config/mongoid.yml". You should create "veye_dev" database in your MongoDB instance, in that way you don't have to customize the mongoid.yml file.

### ElasticSearch

We are using ElasticSearch for better search results. You can find downloads and tutorials to ElasticSearch here: <http://www.elasticsearch.org/>. The connection to the ElasticSearch Server is configured in `config/settings.yml`. If you start the rails console you can re-index the whole MongoDB with:

```
EsProduct.reset
EsProduct.index_all
```

You can also use the application without ElasticSearch, if that is to much trouble for you. In `ProductService.search` you just have to comment out everything but the last line. That will use MongoDB for search results.

### Amazon S3

For uploading files a connection to Amazon S3 is mandatory. You can find the configuration for Amazon S3 in "config/config.yml". Please add here your "aws_s3_access_key_id" and your "aws_s3_secret_access_key" and don't commit it back! With that all file uploads will work fine.

You can use the fake-s3 GEM to simulate S3 offline: <https://github.com/jubos/fake-s3>.
You can start the fake-s3 service like this:

```
fakes3 -r /tmp -p 4567
```


### Memcache

For memcache we are using the dalli GEM. It requires at least memcache 1.4. For a little performance boost
we are using kgio. You can find a quick tutorial to Rails an Memcache on Heroku: <https://devcenter.heroku.com/articles/building-a-rails-3-application-with-the-memcache-addon>.


## React.JS

for autocompiling the JSX files in ReactJS use the `jsx` node package.

```
jsx --watch src/ build/
```

`jsx` can be installed via NPM with this command: 

```
sudo npm install -g react-tools
sudo npm install -g jsx
```


## Configuration

VersionEye is using many 3rd part services in the Internet. Services like GitHub, Bitbucket, Amazon and so on. All Access Tokens and Access Keys are centralized in `config/settings.yml`. If some keys are missing just add your own and don't commit it back. Inside the application you can access all values over the "Settings" class like this:

```
Settings.instance.github_client_id
```

## Tests

For tests we are using

* RSpec: <http://rspec.info/>
* Capybara: <https://github.com/jnicklas/capybara>
* Selenium-Webdriver: <http://www.versioneye.com/package/selenium-webdriver>

We are using RSpec for all kind of tests! Even for acceptance Tests. In the past we used RSpec togehter with webrat. But because webrat is not maintained anymore we moved to capybara. All new acceptance tests have to be written in capybara and placed in `spec/features`. If JavaScript is required for the test we use selenium as webdriver for capybara.

You can run all tests with the "rspec" command. Before you run the tests you should switch to test environment! You can do that by exporting the RAISL_ENV like this: `export RAILS_ENV=test`.

## Rake

Our rake tasks are organized in `lib/tasks/versioneye.rake`. In this file we have 2 important tasks.

```
rake versioneye:daily_jobs
```

This will execute all jobs we have to run daily. For example sending out the daily new version notification emails and so on.

```
rake versioneye:weekly_jobs
```

This task will execute all jobs we have to run once a week. For example sending out the weekly project notifications.


## Deployment

The deployment works with [Capistrano](https://www.versioneye.com/ruby/capistrano/3.2.0).
The main deployment script is placed in:

```
config/deploy.rb
```

Specific configurations for the environments are placed in:

```
config/environments/*
```

the deployment scripts work with domain names. They assume that you have configured the IP address to the
domain `veye_www` locally, for example in `/etc/hosts`. And Capistrano assumes that you can access the
`veye_www` server without entering a password. You can achieve that by copying your public key to the `veye_www` server.

This command will deploy the HEAD from the master branch to production.

```
cap production deploy
```

If something goes wrong you can rollback to the previous deployment like this:

```
cap production deploy:revert_release
```

Keep in mind that Capistrano deploys the `master` branch, not the default `development` branch!
