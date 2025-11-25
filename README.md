# Datajud

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/datajud`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add datajud

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install datajud

## Usage

### Consultar processo sem passar tribunal

```ruby
require 'datajud'

resultado = Datajud.processo("00008323520184013202")
puts resultado
```

### Consultar processo passando 1 tribunal

```ruby
require 'datajud'

resultado = Datajud.processo("00008323520184013202", tribunal: "trf1")
puts resultado
```

### Consultar processo passando vários tribunais

```ruby
require 'datajud'

resultado = Datajud.processo("00008323520184013202", tribunal: ["trf1", "tjmg"])
puts resultado
```

### Listas de tribunais disponíveis

Você pode acessar as listas de siglas dos tribunais diretamente pelas constantes do módulo:

```ruby
require 'datajud'

# Todos os tribunais
Datajud::TRIBUNAIS_SIGLAS

# Apenas TJs
Datajud::TJS_SIGLAS

# Apenas TRFs
Datajud::TRFS_SIGLAS

# Apenas TRTs
Datajud::TRTS_SIGLAS

# Apenas TREs
Datajud::TRES_SIGLAS

# Apenas Superiores
Datajud::SUPERIORES_SIGLAS
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PablUoo/datajud. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/PablUoo/datajud/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Datajud project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/PablUoo/datajud/blob/master/CODE_OF_CONDUCT.md).
