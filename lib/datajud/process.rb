# frozen_string_literal: true

require 'ostruct'

module Datajud
  # Representa um processo retornado pela API DataJud.
  # Fornece acesso simples a campos comuns via métodos.
  class Processo
    attr_reader :tribunal, :data

    def initialize(raw)
      # raw expected: { tribunal: 'TJSP', processo: { ... } } or string-keyed
      @tribunal = raw[:tribunal] || raw['tribunal']
      @data = raw[:processo] || raw['processo'] || {}
    end

    def numero
      @data['numero'] || @data[:numero]
    end

    def classe
      @data['classe'] || @data[:classe]
    end

    def partes
      partes = @data['partes'] || @data[:partes] || []
      partes.map do |p|
        OpenStruct.new(
          nome: p['nome'] || p[:nome],
          tipo: p['tipo'] || p['tipoParte'] || p[:tipo],
          documento: p['documento'] || p[:documento]
        )
      end
    end

    def movimentacoes
      mov = @data['andamentos'] || @data[:andamentos] || @data['movimentacoes'] || @data[:movimentacoes]
      (mov || []).map do |m|
        OpenStruct.new(
          descricao: m['descricao'] || m[:descricao],
          data: m['data'] || m['dataHora'] || m[:data],
          tipo: m['tipo'] || m['codigoTipoMovimento'] || m[:tipo]
        )
      end
    end

    def to_h
      { tribunal: tribunal, processo: data }
    end
  end
end
