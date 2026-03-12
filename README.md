# Datajud

SDK simples para consumir a API pública do DataJud (CNJ) em Ruby.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add datajud

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install datajud

## Usage

### Consultar processo com API orientada a objeto

```ruby
require 'datajud'

processo = Datajud.find("00008323520184013202")

# Com tribunal explícito
processo = Datajud.find("00008323520184013202", tribunal: "trf1")

processo.numero
processo.classe
processo.partes
processo.movimentacoes

# Tribunal como objeto
processo.tribunal
# => { nome: "TRF1", sigla: "TRF1", esfera: "Federal" }

# Tabela HTML de endpoints (todos os tribunais conhecidos)
Datajud.endpoints_table(Datajud::TRIBUNAIS_SIGLAS)
```

### Métodos de consulta disponíveis

```ruby
# API orientada a objeto
processo = Datajud.find("00008323520184013202", tribunal: "trf1")

# Retorno bruto (hash)
resultado = Datajud.processo("00008323520184013202", tribunal: "trf1")

# Consulta genérica com filtros (Elasticsearch)
resultado = Datajud::ApiClient.buscar("trf1", match: { numeroProcesso: "00008323520184013202" })

# Atalho para buscar processo (modo legado)
resultado = Datajud::ApiClient.buscar_processo("00008323520184013202", "trf1")
```

> Dica: quando quiser ver todas as chaves retornadas pela API, prefira `Datajud.processo`.

### Compatibilidade com ApiClient (modo legado)

```ruby
Datajud.configure do |config|
    config.api_key = "SUA_API_KEY"
end

resultado = DataJud::ApiClient.buscar_processo("00008323520184013202", "trf1")
puts resultado
```

### Auto-detectar tribunal pelo número CNJ

Se o número estiver no formato CNJ, a gem tenta derivar o tribunal automaticamente
para evitar varrer todas as bases.

```ruby
processo = Datajud.find("0000832-35.2018.8.26.0202")
puts processo.tribunal
```

> A UF da comarca é derivada localmente pelo código IBGE do município quando disponível.

### Configuração (API key, timeout e retries)

```ruby
Datajud.configure do |config|
    config.api_key = "SUA_API_KEY"
    config.open_timeout = 5
    config.read_timeout = 15
    config.retries = 2
    config.retry_wait = 0.5
    config.fallback_all_on_miss = true
    config.lookup_ibge = true
    config.ibge_base_url = "https://servicodados.ibge.gov.br/api/v1/localidades/municipios"
end
```

Ou via variável de ambiente:

```bash
export DATAJUD_API_KEY="SUA_API_KEY"
```

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
