# frozen_string_literal: true

require_relative "../lib/datajud"

Datajud.configure do |config|
  config.open_timeout = 3
  config.read_timeout = 5
end

begin
  processo = Datajud.find("0000832-35.2018.8.26.0202")

  if processo
    puts "Tribunal: #{processo.tribunal}"
    puts "Número: #{processo.numero}"
    puts "Classe: #{processo.classe}"
    puts "Partes: #{processo.partes.map(&:nome).join(', ')}"
    puts "Movimentações: #{processo.movimentacoes.size}"
  else
    puts "Processo não encontrado."
  end
rescue StandardError => e
  warn "Erro ao consultar DataJud: #{e.class} - #{e.message}"
end
