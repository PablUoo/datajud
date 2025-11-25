# frozen_string_literal: true

require_relative "datajud/version"
require_relative "datajud/key_fetcher"
require 'net/http'
require 'json'

module Datajud
  BASE_ENDPT = "https://api-publica.datajud.cnj.jus.br"
  # Tribunais de Justiça Estaduais (TJs)
  TJS_SIGLAS = [
    "tjac", "tjal", "tjap", "tjba", "tjce", "tjdf", "tjes", "tjgo", "tjma",
    "tjmg", "tjms", "tjmt", "tjpa", "tjpb", "tjpe", "tjpi", "tjpr", "tjrj",
    "tjrn", "tjro", "tjrr", "tjrs", "tjsc", "tjse", "tjsp", "to"
  ]

  # Tribunais Regionais Federais (TRFs)
  TRFS_SIGLAS = [
    "trf1", "trf2", "trf3", "trf4", "trf5"
  ]

  # Tribunais Regionais do Trabalho (TRTs)
  TRTS_SIGLAS = [
    "trt1", "trt2", "trt3", "trt4", "trt5", "trt6", "trt7", "trt8", "trt9",
    "trt10", "trt11", "trt12", "trt13", "trt14", "trt15", "trt16", "trt17",
    "trt18", "trt19", "trt20", "trt21", "trt22", "trt23", "trt24"
  ]

  # Tribunais Regionais Eleitorais (TREs)
  TRES_SIGLAS = [
    "treac", "treal", "tream", "treap", "treba", "trece", "tredf", "tresp",
    "trego", "trema", "tremg", "trems", "tremt", "trepa", "trepb", "trepe",
    "trepi", "trepr", "trerj", "trern", "trero", "trerr", "trers", "tresc",
    "trese", "tretoc"
  ]

  # Tribunais Superiores
  SUPERIORES_SIGLAS = [
    "tse", "stf", "stj", "stm", "tst"
  ]

  # Para consultar em todos, você pode unificar todas as listas:
  TRIBUNAIS_SIGLAS = TJS_SIGLAS + TRFS_SIGLAS + TRTS_SIGLAS + TRES_SIGLAS + SUPERIORES_SIGLAS

  # Pega a API Key sempre atual (consulta ao site DataJud)
  def self.api_key
    @api_key ||= KeyFetcher.fetch_api_key
  end

  def self.reset_api_key
    KeyFetcher.clear_cache
    @api_key = nil
  end

  def self.processo(numero, tribunal: nil)
    siglas_consulta = tribunal ? [tribunal.downcase] : TRIBUNAIS_SIGLAS
    resultado = nil

    siglas_consulta.each do |sigla|
      endpoint = "#{BASE_ENDPT}/api_publica_#{sigla}/_search"
      payload = {
        "query": {
          "bool": {
            "must": [
              { "match": { "numeroProcesso": numero } }
            ]
          }
        }
      }

      uri = URI(endpoint)
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = payload.to_json
      req['Authorization'] = "APIKey #{api_key}"

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      resp = http.request(req)

      # Se falhar por chave expirada:
      if [401, 403].include?(resp.code.to_i)
        reset_api_key
        req['Authorization'] = "APIKey #{api_key}"
        resp = http.request(req)
      end

      next unless resp.code.to_i == 200

      processos = JSON.parse(resp.body)
      if processos['hits'] && !processos['hits']['hits'].empty?
        proc = processos['hits']['hits'][0]['_source']

        resultado = {
          tribunal: sigla.upcase,
          processo: {
            numero: proc['numeroProcesso'],
            vara: proc['orgaoJulgador'] ? {
                nome: proc['orgaoJulgador']['nome'],
                codigo: proc['orgaoJulgador']['codigo'],
                comarca: proc['orgaoJulgador']['comarca'],
                tribunal: sigla.upcase
            } : nil,
            situacao: proc['situacao'],
            origem: proc['origem'],
            instancia: proc['grau'],
            classe: proc['classeProcessual'],
            assunto: proc['assuntos'],
            partes: proc['partes']&.map do |p|
              {
                nome: p['nome'],
                tipo: p['tipoParte'],
                documento: p['documento']
              }
            end,
            andamentos: proc['movimentacoes']&.map do |mv|
              {
                descricao: mv['descricao'],
                data: mv['dataHora'],
                tipo: mv['codigoTipoMovimento']
              }
            end,
            documentos: proc['documentos']&.map do |doc|
              {
                titulo: doc['nomeDocumento'],
                tipo: doc['tipoDocumento'],
                data: doc['dataJuntada'],
                assinatura_digital: doc['assinaturaDigital']
              }
            end,
            audiencias: proc['audiencias']&.map do |aud|
              {
                data_hora: aud['dataHora'],
                tipo: aud['tipo'],
                status: aud['statusAudiencia'],
                observacao: aud['observacao']
              }
            end
          }
        }
        break
      end
    end
    resultado
  end
end