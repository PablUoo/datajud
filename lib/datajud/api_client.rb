# frozen_string_literal: true

require 'net/http'
require 'json'

module Datajud
  class ApiClient
    BASE_URL = "https://api-publica.datajud.cnj.jus.br"

    # Consulta genérica: tribunal e filtros customizados
    def self.buscar(tribunal, filtros = {})
      endpoint = "/api_publica_#{tribunal.downcase}/_search"
      url = URI("#{Datajud.configuration.base_endpoint}#{endpoint}")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == "https")
      http.open_timeout = Datajud.configuration.open_timeout
      http.read_timeout = Datajud.configuration.read_timeout

      request = Net::HTTP::Post.new(url)
      request['Authorization'] = "APIKey #{Datajud.api_key}"
      request['Content-Type'] = 'application/json'
      request.body = { query: filtros }.to_json

      begin
        response = Datajud.request_with_retry(http, request)
        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)
        else
          { error: response.message, status: response.code, body: response.body }
        end
      rescue SocketError => e
        { error: "Falha de conexão: #{e.message}" }
      rescue Errno::ECONNRESET => e
        { error: "Conexão resetada pelo servidor: #{e.message}" }
      rescue EOFError => e
        { error: "Resposta inesperada da API: #{e.message}" }
      rescue StandardError => e
        { error: "Erro desconhecido: #{e.message}" }
      end
    end

    # Busca por número de processo (atalho)
    def self.buscar_processo(numero_processo, tribunal)
      filtros = { match: { numeroProcesso: numero_processo } }
      buscar(tribunal, filtros)
    end
  end
end

# Alias para compatibilidade com código legado
module DataJud
  ApiClient = Datajud::ApiClient
end