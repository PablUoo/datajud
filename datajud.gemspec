# frozen_string_literal: true

require_relative "lib/datajud/version"

Gem::Specification.new do |spec|
  spec.name = "datajud"
  spec.version = Datajud::VERSION
  spec.authors = ["PablUoo"]
  spec.email = ["pabloaurelio1163@gmail.com"]

  spec.summary = "Gem para consultar a API DataJUD por número de processo"
  spec.description = "Gem Ruby que permite busca e extração detalhada de processos judiciais diretamente da API pública DataJUD do CNJ, preenchendo estruturas de processos brasileiros."
  spec.homepage = "https://github.com/PablUoo/datajud"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/PablUoo/datajud"
  spec.metadata["changelog_uri"] = "https://github.com/PablUoo/datajud/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f =~ /\.gem$/ || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "nokogiri", "~> 1.14"
  spec.add_runtime_dependency "json", "~> 2.0"
  spec.add_runtime_dependency "net-http", "~> 0.3"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
