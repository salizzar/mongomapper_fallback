# MongomapperFallback

At this time, MongoMapper not have any mechanism to properly handle Replicaset connection failures (commonly master falls and arbiter was not selected any server yet).

MongomapperFallback is a alternative to handle these failures with a simple retry mechanism.

## Installation

Add this line to your application's Gemfile:

    gem 'mongomapper_fallback'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongomapper_fallback

## Usage

    # example.rb
    class Example
      include MongomapperFallback

      def execute
        logger = Logger.new('your_logger_or_slogger_here.rb')

        # available options:
        # - retry_limit: limit of retries that will be executed
        # - sig_quit: sends a QUIT to current process before retry failed code again

        replicaset_safe_run!(logger, retry_limit: 10, sig_quit: true) do
          # perform any operation
        end
      end
    end


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
