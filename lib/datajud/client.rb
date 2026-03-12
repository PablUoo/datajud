# frozen_string_literal: true

module Datajud
  class Client
    # Retorna uma instância de Datajud::Processo ou nil
    def self.find(numero, tribunal: nil)
      raw = Datajud.processo(numero, tribunal: tribunal)
      return nil unless raw && raw[:processo] || raw && raw['processo']

      Datajud::Processo.new(raw)
    end
  end
end
