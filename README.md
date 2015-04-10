# Cassandra::Orm

A simple Cassandra ORM library, which can provide with a CRUD model to operate Cassandra. Based on [cassandra-driver](https://github.com/datastax/ruby-driver.git).

[![Build Status](https://travis-ci.org/bachue/cassandra-orm.png?branch=master)](https://travis-ci.org/bachue/cassandra-orm)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cassandra-orm'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cassandra-orm

## Usage

```ruby
require 'cassandra-orm'
require 'logger'

CassandraORM.configure keyspace: 'test', logger: Logger.new(STDERR)
CassandraORM.connect

class User
  set_primary_key :email
  attributes :name, :age
end

user = User.new email: 'bachue.shu@gmail.com', name: 'Bachue Zhou', age: 25
user.save exclusive: true # save it only when there's no user whose email is 'bachue.shu@gmail.com'

user.age = 26
user.save if: {age: 25} # update it only when his age is still 25

user.destroy # returns true, delete the record
````

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/cassandra-orm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
