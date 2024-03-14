# WriteOnce

WriteOnce is a gem meant to mirror the behaviour of `attr_readonly`, which can be used on active record models to gate their write behaviour.

The difference is that while `attr_readonly` only allows writes during model creation, write once as the name infers, only allows attributes to be written to when they have no data present yet.

This can be useful for model attributes that you do not want set during creation, but do want to enforce preventing overwrites for.

## Installation

https://rubygems.org/gems/write_once

Install the gem and add to the application's Gemfile by executing:

    $ bundle add write_once

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install write_once

## Usage

Let's say you have a timestamp column `first_enrolled_at` on an `Account` model. When you first create an account, the user has not enrolled yet and so the values should be nil. Later on though, when a user chooses to enroll, you want to set this to a timestamp.

By setting `attr_writeonce` on your model:
```
  class Account < ApplicationRecord
    attr_writeonce :first_enrolled_at
  end
```

Setting this on your model will mean that accounts that already have a value present for `first_enrolled_at` will not allow new values to be assigned to that attribute. This includes both in memory assignment as well as storage backed persistence.

Other use cases include:
    * attributes that are computed and set at a later time
    * attributes that require an async external service call to set
    * attributes set via cron or backfill
    * any attribute really that you care about only being set once that you can't set at creation time

## Configuration

WriteOnce accepts two configuration values, both optional.

To configure WriteOnce, create a file under `initializers/write_once.rb` as follows:

```
# frozen_string_literal: true

WriteOnce.configure do |config|
  
  # enforce_errors has two possible values:
  #   true - any time an invalid write is detected, a `WriteOnceAttributeError` will be raised.
  #   false  - any time an invalid write is detected, a warn level message will be logged.
  config.enforce_errors = false

  # If you set enforce_errors above to false, you can configure a logger of your choice.
  config.logger = Rails.logger.new
end

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/1debit/write_once. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/1debit/write_once/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WriteOnce project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/1debit/write_once/blob/main/CODE_OF_CONDUCT.md).
