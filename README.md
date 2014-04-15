# Qu::Cmdwrapper

qu-cmdwrapper: A wrapper for command-line tools, mostly are bioinformatics related tools

## Installation

Add this line to your application's Gemfile:

    gem 'qu-cmdwrapper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qu-cmdwrapper

## Usage

```
# retrieve sequence from two bit formated database with twoBitToFa command
amp_seq_list = Cmdwrapper::twoBitToFa(fh.path, db + Qu::Mfeindex::DB_2BIT)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
