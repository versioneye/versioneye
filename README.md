[![Dependency Status](https://www.versioneye.com/user/projects/52878714632bac28c200006d/badge.png)](https://www.versioneye.com/user/projects/52878714632bac28c200006d)

![Tests](https://www.codeship.io/projects/de2efdb0-1d42-0131-839e-26fabeabc570/status)

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

Every branch have to be merged in to the `develop` branch as soon it is done.
Merges from develop to master are like tags and deployments. The master branch must always be stable and deployable!


## VersionEye Stack

This is the stack in this project:

 * Ruby on Rails
 * MongoDB
 * Memcache
 * ElasticSearch
 * Amazon S3
 * Postmarkapp (Email)

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

### Postmarkapp

For sending out emails we use <https://postmarkapp.com/>. Here we use the postmark-rails GEM : <http://www.versioneye.com/package/postmark-rails> to interact with the postmark API.


## Configuration

VersionEye is using many 3rd part services in the Internet. Services like GitHub, Twitter, Facebook, Amazon, Postmark and so on. All Access Tokens and Access Keys are centralized in `config/settings.yml`. If some keys are missing just add your own and don't commit it back. Inside the application you can access all values over the "Settings" class like this:

```
Settings.github_client_id
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

This will execute all jobs we have to run daily. For example sending out the daily new verison notification emails and so on.

```
rake versioneye:weekly_jobs
```

This task will execute all jobs we have to run once a week. For example sending out the weekly project notifications.


## Model

VersionEye's model currently looks like this (2013-10-23):

![VersionEye Model](https://github.com/versioneye/versioneye/raw/master/doc/versioneye-model.png)
