require 'open-uri'
require 'nokogiri'
require 'fileutils'

module Datajud
  module KeyFetcher
    ACCESS_URL = "https://datajud-wiki.cnj.jus.br/api-publica/acesso"
    CACHE_PATH = File.expand_path("~/.datajud_api_key")

    def self.fetch_api_key
      # Tenta carregar do cache
      if File.exist?(CACHE_PATH)
        key = File.read(CACHE_PATH).strip
        return key unless key.empty?
      end

      # Se não estiver em cache, busca online
      html = URI.open(ACCESS_URL).read
      doc = Nokogiri::HTML.parse(html)
      key = doc.text[/APIKey\s+([A-Za-z0-9+\/=]+)/, 1]
      raise "API Key not found on Datajud-Wiki page!" unless key

      # Salva em cache
      File.write(CACHE_PATH, key)
      key
    end

    def self.clear_cache
      FileUtils.rm_f(CACHE_PATH)
    end
  end
end