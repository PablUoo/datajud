# frozen_string_literal: true

require 'ostruct'

module Datajud
  # Representa um processo retornado pela API DataJud.
  # Fornece acesso simples a campos comuns via métodos.
  class Processo
                def self.deep_struct(obj)
                  case obj
                  when Hash
                    OpenStruct.new(obj.transform_values { |v| deep_struct(v) })
                  when Array
                    obj.map { |v| deep_struct(v) }
                  else
                    obj
                  end
                end
            def municipio_ibge
              orgao = instance_variable_get(:@orgao_julgador) || instance_variable_get(:@orgao_julgador) || self.respond_to?(:orgao_julgador) ? self.orgao_julgador : nil
              return nil unless orgao && orgao.is_a?(Hash)
              orgao['codigoMunicipioIBGE'] || orgao[:codigoMunicipioIBGE]
            end
        def comarca_ibge_codigo
          v = instance_variable_get(:@vara)
          return nil unless v && v.is_a?(Hash)
          comarca = v['comarca'] || v[:comarca]
          return nil unless comarca && comarca.is_a?(Hash)
          comarca['codigoIbge'] || comarca[:codigoIbge] || comarca['ibge'] || comarca[:ibge]
        end
    attr_reader :tribunal

    def initialize(raw)
      processo_hash = raw[:processo] || raw['processo'] || raw
      @tribunal = self.class.deep_struct(raw[:tribunal] || raw['tribunal'])
      processo_hash.each do |k, v|
        ivar = "@#{k.to_s.gsub(/([A-Z])/, '_\\1').downcase}"
        instance_variable_set(ivar, self.class.deep_struct(v))
        self.class.send(:attr_reader, k.to_s.gsub(/([A-Z])/, '_\\1').downcase)
      end
      if processo_hash['orgaoJulgador'] || processo_hash[:orgaoJulgador]
        orgao = processo_hash['orgaoJulgador'] || processo_hash[:orgaoJulgador]
        instance_variable_set(:@orgao_julgador, self.class.deep_struct(orgao))
        self.class.send(:attr_reader, :orgao_julgador)
        if orgao['codigoMunicipioIBGE'] || orgao[:codigoMunicipioIBGE]
          vara = instance_variable_get(:@vara)
          if vara && vara.respond_to?(:comarca)
            comarca = vara.comarca
            if comarca && comarca.is_a?(OpenStruct)
              ibge = orgao['codigoMunicipioIBGE'] || orgao[:codigoMunicipioIBGE]
              comarca.codigoIbge = ibge if comarca.respond_to?(:codigoIbge=)
            end
          end
        end
      end

    end

    def codigo_municipio_ibge
      if respond_to?(:orgao_julgador) && orgao_julgador.is_a?(Hash)
        orgao_julgador['codigoMunicipioIBGE'] || orgao_julgador[:codigoMunicipioIBGE]
      else
        nil
      end
    end
    # Only tribunal is explicit; all other fields are dynamic.
  end
end
