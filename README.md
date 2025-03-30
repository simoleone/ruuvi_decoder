# RuuviDecoder
Decode data from Ruuvi sensors. 

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add ruuvi_decoder
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install ruuvi_decoder
```

## Usage

The easiest way to use this library is to call `RuuviDecoder.decode` with an array of bytes or
a binary-encoded string (from a bluetooth advertisement's vendor data). It will automatically detect the data 
format and return an appropriate instance of a decoder class. If you know the data format
in advance you can also directly instantiate a decoder class such as `RuuviDecoder::V5Data`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ruuvi_decoder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/ruuvi_decoder/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).