# frozen_string_literal: true

require 'socket'
require_relative "datajud/version"
require_relative "datajud/key_fetcher"
require_relative "datajud/configuration"
require_relative "datajud/api_client"
require_relative "datajud/client"
require_relative "datajud/process"
require 'net/http'
require 'json'

unless Socket.method(:tcp).parameters.any? { |param| param[1] == :open_timeout }
  class << Socket
    alias_method :tcp_without_open_timeout, :tcp

    def tcp(host, port, local_host = nil, local_port = nil, **kwargs)
      if kwargs.key?(:open_timeout) && !kwargs.key?(:connect_timeout)
        kwargs[:connect_timeout] = kwargs.delete(:open_timeout)
      end

      tcp_without_open_timeout(host, port, local_host, local_port, **kwargs)
    end
  end
end

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
    "trf1", "trf2", "trf3", "trf4", "trf5", "trf6"
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

  TJM_SIGLAS = [
    "tjmsp", "tjmrs", "tjmmg"
  ]

  SUPERIORES_NOMES = {
    "tst" => "Tribunal Superior do Trabalho",
    "tse" => "Tribunal Superior Eleitoral",
    "stj" => "Tribunal Superior de Justiça",
    "stm" => "Tribunal Superior Militar",
    "stf" => "Supremo Tribunal Federal"
  }.freeze

  TRIBUNAL_NOMES = SUPERIORES_NOMES.merge(
    "trf1" => "Tribunal Regional Federal da 1ª Região",
    "trf2" => "Tribunal Regional Federal da 2ª Região",
    "trf3" => "Tribunal Regional Federal da 3ª Região",
    "trf4" => "Tribunal Regional Federal da 4ª Região",
    "trf5" => "Tribunal Regional Federal da 5ª Região",
    "trf6" => "Tribunal Regional Federal da 6ª Região",
    "tjac" => "Tribunal de Justiça do Acre",
    "tjal" => "Tribunal de Justiça de Alagoas",
    "tjam" => "Tribunal de Justiça do Amazonas",
    "tjap" => "Tribunal de Justiça do Amapá",
    "tjba" => "Tribunal de Justiça da Bahia",
    "tjce" => "Tribunal de Justiça do Ceará",
    "tjdft" => "Tribunal de Justiça do Distrito Federal e Territórios",
    "tjdf" => "Tribunal de Justiça do Distrito Federal e Territórios",
    "tjes" => "Tribunal de Justiça do Espírito Santo",
    "tjgo" => "Tribunal de Justiça de Goiás",
    "tjma" => "Tribunal de Justiça do Maranhão",
    "tjmg" => "Tribunal de Justiça de Minas Gerais",
    "tjms" => "Tribunal de Justiça de Mato Grosso do Sul",
    "tjmt" => "Tribunal de Justiça do Mato Grosso",
    "tjpa" => "Tribunal de Justiça do Pará",
    "tjpb" => "Tribunal de Justiça da Paraíba",
    "tjpe" => "Tribunal de Justiça de Pernambuco",
    "tjpi" => "Tribunal de Justiça do Piauí",
    "tjpr" => "Tribunal de Justiça do Paraná",
    "tjrj" => "Tribunal de Justiça do Rio de Janeiro",
    "tjrn" => "Tribunal de Justiça do Rio Grande do Norte",
    "tjro" => "Tribunal de Justiça de Rondônia",
    "tjrr" => "Tribunal de Justiça de Roraima",
    "tjrs" => "Tribunal de Justiça do Rio Grande do Sul",
    "tjsc" => "Tribunal de Justiça de Santa Catarina",
    "tjse" => "Tribunal de Justiça de Sergipe",
    "tjsp" => "Tribunal de Justiça de São Paulo",
    "tjto" => "Tribunal de Justiça do Tocantins",
    "trt1" => "Tribunal Regional do Trabalho da 1ª Região",
    "trt2" => "Tribunal Regional do Trabalho da 2ª Região",
    "trt3" => "Tribunal Regional do Trabalho da 3ª Região",
    "trt4" => "Tribunal Regional do Trabalho da 4ª Região",
    "trt5" => "Tribunal Regional do Trabalho da 5ª Região",
    "trt6" => "Tribunal Regional do Trabalho da 6ª Região",
    "trt7" => "Tribunal Regional do Trabalho da 7ª Região",
    "trt8" => "Tribunal Regional do Trabalho da 8ª Região",
    "trt9" => "Tribunal Regional do Trabalho da 9ª Região",
    "trt10" => "Tribunal Regional do Trabalho da 10ª Região",
    "trt11" => "Tribunal Regional do Trabalho da 11ª Região",
    "trt12" => "Tribunal Regional do Trabalho da 12ª Região",
    "trt13" => "Tribunal Regional do Trabalho da 13ª Região",
    "trt14" => "Tribunal Regional do Trabalho da 14ª Região",
    "trt15" => "Tribunal Regional do Trabalho da 15ª Região",
    "trt16" => "Tribunal Regional do Trabalho da 16ª Região",
    "trt17" => "Tribunal Regional do Trabalho da 17ª Região",
    "trt18" => "Tribunal Regional do Trabalho da 18ª Região",
    "trt19" => "Tribunal Regional do Trabalho da 19ª Região",
    "trt20" => "Tribunal Regional do Trabalho da 20ª Região",
    "trt21" => "Tribunal Regional do Trabalho da 21ª Região",
    "trt22" => "Tribunal Regional do Trabalho da 22ª Região",
    "trt23" => "Tribunal Regional do Trabalho da 23ª Região",
    "trt24" => "Tribunal Regional do Trabalho da 24ª Região",
    "treac" => "Tribunal Regional Eleitoral do Acre",
    "treal" => "Tribunal Regional Eleitoral de Alagoas",
    "tream" => "Tribunal Regional Eleitoral do Amazonas",
    "treap" => "Tribunal Regional Eleitoral do Amapá",
    "treba" => "Tribunal Regional Eleitoral da Bahia",
    "trece" => "Tribunal Regional Eleitoral do Ceará",
    "tredf" => "Tribunal Regional Eleitoral do Distrito Federal",
    "trees" => "Tribunal Regional Eleitoral do Espírito Santo",
    "trego" => "Tribunal Regional Eleitoral de Goiás",
    "trema" => "Tribunal Regional Eleitoral do Maranhão",
    "tremg" => "Tribunal Regional Eleitoral de Minas Gerais",
    "trems" => "Tribunal Regional Eleitoral do Mato Grosso do Sul",
    "tremt" => "Tribunal Regional Eleitoral do Mato Grosso",
    "trepa" => "Tribunal Regional Eleitoral do Pará",
    "trepb" => "Tribunal Regional Eleitoral da Paraíba",
    "trepe" => "Tribunal Regional Eleitoral de Pernambuco",
    "trepi" => "Tribunal Regional Eleitoral do Piauí",
    "trepr" => "Tribunal Regional Eleitoral do Paraná",
    "trerj" => "Tribunal Regional Eleitoral do Rio de Janeiro",
    "trern" => "Tribunal Regional Eleitoral do Rio Grande do Norte",
    "trero" => "Tribunal Regional Eleitoral de Rondônia",
    "trerr" => "Tribunal Regional Eleitoral de Roraima",
    "trers" => "Tribunal Regional Eleitoral do Rio Grande do Sul",
    "tresc" => "Tribunal Regional Eleitoral de Santa Catarina",
    "trese" => "Tribunal Regional Eleitoral de Sergipe",
    "tresp" => "Tribunal Regional Eleitoral de São Paulo",
    "tretoc" => "Tribunal Regional Eleitoral do Tocantins",
    "tjmsp" => "Tribunal de Justiça Militar de São Paulo",
    "tjmrs" => "Tribunal de Justiça Militar do Rio Grande do Sul",
    "tjmmg" => "Tribunal de Justiça Militar de Minas Gerais"
  ).freeze

  # Para consultar em todos, você pode unificar todas as listas:
  TRIBUNAIS_SIGLAS = TJS_SIGLAS + TRFS_SIGLAS + TRTS_SIGLAS + TRES_SIGLAS + SUPERIORES_SIGLAS + TJM_SIGLAS

  TJ_BY_CODE = {
    "01" => "tjac",
    "02" => "tjal",
    "03" => "tjap",
    "04" => "tjam",
    "05" => "tjba",
    "06" => "tjce",
    "07" => "tjdf",
    "08" => "tjes",
    "09" => "tjgo",
    "10" => "tjma",
    "11" => "tjmt",
    "12" => "tjms",
    "13" => "tjmg",
    "14" => "tjpa",
    "15" => "tjpb",
    "16" => "tjpr",
    "17" => "tjpe",
    "18" => "tjpi",
    "19" => "tjrj",
    "20" => "tjrn",
    "21" => "tjrs",
    "22" => "tjro",
    "23" => "tjrr",
    "24" => "tjsc",
    "25" => "tjse",
    "26" => "tjsp",
    "27" => "to"
  }.freeze

  UF_BY_CODE = {
    "01" => "ac",
    "02" => "al",
    "03" => "ap",
    "04" => "am",
    "05" => "ba",
    "06" => "ce",
    "07" => "df",
    "08" => "es",
    "09" => "go",
    "10" => "ma",
    "11" => "mt",
    "12" => "ms",
    "13" => "mg",
    "14" => "pa",
    "15" => "pb",
    "16" => "pr",
    "17" => "pe",
    "18" => "pi",
    "19" => "rj",
    "20" => "rn",
    "21" => "rs",
    "22" => "ro",
    "23" => "rr",
    "24" => "sc",
    "25" => "se",
    "26" => "sp",
    "27" => "to"
  }.freeze

  IBGE_UF_SIGLAS = {
    "11" => "RO",
    "12" => "AC",
    "13" => "AM",
    "14" => "RR",
    "15" => "PA",
    "16" => "AP",
    "17" => "TO",
    "21" => "MA",
    "22" => "PI",
    "23" => "CE",
    "24" => "RN",
    "25" => "PB",
    "26" => "PE",
    "27" => "AL",
    "28" => "SE",
    "29" => "BA",
    "31" => "MG",
    "32" => "ES",
    "33" => "RJ",
    "35" => "SP",
    "41" => "PR",
    "42" => "SC",
    "43" => "RS",
    "50" => "MS",
    "51" => "MT",
    "52" => "GO",
    "53" => "DF"
  }.freeze

  ESFERA_BY_PREFIX = {
    "TRF" => "Federal",
    "TJ" => "Estadual",
    "TRT" => "Trabalhista",
    "TRE" => "Eleitoral",
    "STF" => "Superior",
    "STJ" => "Superior",
    "TST" => "Superior",
    "STM" => "Superior",
    "TSE" => "Superior"
  }.freeze

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  # Pega a API Key sempre atual (consulta ao site DataJud)
  def self.api_key
    return configuration.api_key if configuration.api_key

    env_key = ENV["DATAJUD_API_KEY"]
    return env_key if env_key && !env_key.strip.empty?

    @api_key ||= KeyFetcher.fetch_api_key
  end

  def self.reset_api_key
    KeyFetcher.clear_cache
    @api_key = nil
  end

  def self.siglas_por_cnj(cnj)
    digits = cnj.to_s.gsub(/\D/, "")
    return nil unless digits.length == 20

    j = digits[13]
    tr = digits[14, 2]

    case j
    when "1"
      tr_num = tr.to_i
      return ["trf#{tr_num}"] if tr_num.between?(1, 5)
    when "2"
      sigla = TJ_BY_CODE[tr]
      return [sigla] if sigla
    when "3"
      tr_num = tr.to_i
      return ["trt#{tr_num}"] if tr_num.between?(1, 24)
    when "4"
      uf = UF_BY_CODE[tr]
      return ["tre#{uf}"] if uf
    when "5"
      return ["stm"]
    end

    nil
  end

  # Retém compatibilidade com a implementação existente.
  # A implementação mais rica (retornando objetos) está em Datajud::Client

  # Retorna um objeto Datajud::Processo ou nil
  def self.find(numero, tribunal = nil, **kwargs)
    tribunal = kwargs[:tribunal] if tribunal.nil? && kwargs.key?(:tribunal)
    Datajud::Client.find(numero, tribunal: tribunal)
  end

  # Mantém método antigo para compatibilidade (retorna hash com dados brutos)
  def self.processo(numero, tribunal = nil, **kwargs)
    tribunal = kwargs[:tribunal] if tribunal.nil? && kwargs.key?(:tribunal)
    # A lógica original permanecida aqui para backward-compat
    siglas_consulta = if tribunal
                        Array(tribunal).flatten.map { |t| t.to_s.downcase }
                      elsif (siglas_cnj = siglas_por_cnj(numero))
                        if configuration.fallback_all_on_miss
                          siglas_cnj + (TRIBUNAIS_SIGLAS - siglas_cnj)
                        else
                          siglas_cnj
                        end
                      elsif configuration.tribunais.any?
                        configuration.tribunais.map { |t| t.to_s.downcase }
                      else
                        TRIBUNAIS_SIGLAS
                      end
    resultado = nil

    siglas_consulta.each do |sigla|
      resposta = ApiClient.buscar_processo(numero, sigla)
      next if resposta.is_a?(Hash) && resposta[:error]

      hits = resposta.is_a?(Hash) ? resposta.dig('hits', 'hits') : nil
      next if hits.nil? || hits.empty?

      proc = hits[0]['_source']

      resultado = {
        tribunal: tribunal_from(sigla, proc),
        processo: {
          numero: proc['numeroProcesso'],
          vara: proc['orgaoJulgador'] ? {
            nome: proc['orgaoJulgador']['nome'],
            codigo: proc['orgaoJulgador']['codigo'],
            comarca: comarca_from(proc['orgaoJulgador'], sigla)
          } : nil,
          situacao: proc['situacao'],
          origem: proc['origem'],
          instancia: proc['grau'],
          classe: proc['classeProcessual'] || proc['classe'],
          assunto: proc['assuntos'],
          partes: partes_from(proc),
          andamentos: (proc['movimentacoes'] || proc['movimentos'])&.map do |mv|
            {
              descricao: mv['descricao'] || mv['nome'] || mv.dig('tipoMovimento', 'nome') || mv.dig('tipo', 'nome'),
              data: mv['dataHora'] || mv['data'],
              tipo: mv['codigoTipoMovimento'] || mv['codigo'] || mv.dig('tipoMovimento', 'codigo') || mv.dig('tipo', 'codigo')
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
          end,
          sistema: proc['sistema'],
          formato: proc['formato'],
          dataHoraUltimaAtualizacao: proc['dataHoraUltimaAtualizacao'],
          dataAjuizamento: proc['dataAjuizamento'],
          nivelSigilo: proc['nivelSigilo'],
          id: proc['id'],
          timestamp: proc['@timestamp']
        }
      }
      break
    end
    resultado
  end

  def self.partes_from(proc)
    partes = proc['partes'] || proc['partesProcessuais']
    partes = Array(partes) if partes

    if partes.nil? || partes.empty?
      ativos = Array(proc['poloAtivo'] || proc['parteAtiva'] || proc['partesAtivas'])
      passivos = Array(proc['poloPassivo'] || proc['partePassiva'] || proc['partesPassivas'])
      partes = ativos.map { |p| p.merge('polo' => 'ATIVO') } + passivos.map { |p| p.merge('polo' => 'PASSIVO') }
    end

    return nil if partes.nil? || partes.empty?

    partes.map do |p|
      {
        nome: p['nome'] || p['nomeParte'] || p['parteNome'],
        tipo: p['tipoParte'] || p['tipo'] || p['polo'] || p['qualificacao'],
        documento: p['documento'] || p['cpfCnpj'] || p['numeroDocumento']
      }
    end
  end

  def self.tribunal_from(sigla, proc)
    sigla_up = sigla.to_s.upcase
    nome = TRIBUNAL_NOMES[sigla.to_s.downcase] || proc['tribunal'] || sigla_up
    esfera = esfera_from_sigla(sigla_up)

    { nome: nome, sigla: sigla_up, esfera: esfera }
  end

  def self.esfera_from_sigla(sigla)
    key = ESFERA_BY_PREFIX.keys.find { |prefix| sigla.start_with?(prefix) }
    ESFERA_BY_PREFIX[key] || "Desconhecida"
  end

  def self.endpoints_table(tribunais = SUPERIORES_NOMES.keys)
    rows = tribunais.map do |sigla|
      nome = TRIBUNAL_NOMES[sigla] || sigla.to_s.upcase
      endpoint_sigla = endpoint_alias(sigla)
      url = "#{configuration.base_endpoint}/api_publica_#{endpoint_sigla}/_search"
      "<tr><td>#{nome}</td><td><a href=\"#{url}\" target=\"_blank\" rel=\"noopener noreferrer\">#{url}</a></td></tr>"
    end

    "<table><tr><th>Tribunal</th><th>Url</th></tr>#{rows.join}</table>"
  end

  def self.endpoint_alias(sigla)
    sigla = sigla.to_s.downcase
    return sigla.gsub(/^tre/, 'tre-') if sigla.start_with?('tre') && !sigla.include?('-')

    sigla
  end

  def self.request_with_retry(http, req)
    attempts = 0
    begin
      attempts += 1
      http.request(req)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT
      raise if attempts > configuration.retries

      sleep(configuration.retry_wait) if configuration.retry_wait && configuration.retry_wait.positive?
      retry
    end
  end

  def self.comarca_from(orgao_julgador, sigla)
    return nil unless orgao_julgador

    comarca = orgao_julgador['comarca']

    if comarca.is_a?(Hash)
      nome = comarca['nome'] || comarca['descricao'] || comarca['nomeComarca']
      uf = comarca['uf'] || comarca['siglaUf'] || comarca['estado']
      hash = { nome: nome, uf: uf, tribunal: sigla.upcase }
      return hash
    end

    nome = comarca || orgao_julgador['nome']
    uf = nil
    if orgao_julgador['codigoMunicipioIBGE']
      uf = uf_from_ibge_code(orgao_julgador['codigoMunicipioIBGE'])
      if uf.nil? && configuration.lookup_ibge
        uf = ibge_uf_from(orgao_julgador['codigoMunicipioIBGE'])
      end
    end

    return nil unless nome

    hash = { nome: nome, uf: uf, tribunal: sigla.upcase }
    if orgao_julgador['codigoMunicipioIBGE']
      hash[:codigoIbge] = orgao_julgador['codigoMunicipioIBGE']
    end
    hash
  end

  def self.ibge_uf_from(codigo_municipio)
    @ibge_uf_cache ||= {}
    codigo = codigo_municipio.to_s.strip
    return @ibge_uf_cache[codigo] if @ibge_uf_cache.key?(codigo)

    begin
      uri = URI("#{configuration.ibge_base_url}/#{codigo}")
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      uf = data.dig('microrregiao', 'mesorregiao', 'UF', 'sigla') || data.dig('regiao-imediata', 'regiao-intermediaria', 'UF', 'sigla')
      @ibge_uf_cache[codigo] = uf
    rescue StandardError
      @ibge_uf_cache[codigo] = nil
    end

    @ibge_uf_cache[codigo]
  end

  def self.uf_from_ibge_code(codigo_municipio)
    codigo = codigo_municipio.to_s.strip
    return nil if codigo.length < 2

    IBGE_UF_SIGLAS[codigo[0, 2]]
  end
end