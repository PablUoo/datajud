# frozen_string_literal: true

module Datajud
  # Configurações da gem.
  class Configuration
  attr_accessor :base_endpoint, :tribunais, :api_key, :open_timeout, :read_timeout,
          :retries, :retry_wait, :fallback_all_on_miss, :lookup_ibge, :ibge_base_url

    def initialize
      @base_endpoint = "https://api-publica.datajud.cnj.jus.br"
      @tribunais = []
      @api_key = nil
      @open_timeout = 5
      @read_timeout = 15
      @retries = 1
      @retry_wait = 0.3
      @fallback_all_on_miss = true
      @lookup_ibge = true
      @ibge_base_url = "https://servicodados.ibge.gov.br/api/v1/localidades/municipios"
    end
  end
end
