class FilamentCostItem {
  final String? filamentoId;
  final String nomeCor;
  final String material;
  final double precoPorQuilo;
  final double pesoGramas;
  final int slotAms;

  FilamentCostItem({
    this.filamentoId,
    required this.nomeCor,
    required this.material,
    required this.precoPorQuilo,
    required this.pesoGramas,
    this.slotAms = 1,
  });

  double get custoPorGrama => precoPorQuilo / 1000.0;
  double get custoTotal => pesoGramas * custoPorGrama;
}

class InsumoCostItem {
  final String? insumoId;
  final String nome;
  final double custoUnitario;
  final int quantidade;

  InsumoCostItem({
    this.insumoId,
    required this.nome,
    required this.custoUnitario,
    required this.quantidade,
  });

  double get custoTotal => custoUnitario * quantidade;
}

class PricingCalculationResult {
  final double custoFilamentosImpressos;
  final double custoPurgaSuporte;
  final double custoTotalFilamentos;
  final double custoInsumos;
  final double custoEnergia;
  final double custoDepreciacaoManutencao;
  final double custoMaoDeObra;
  final double custoBaseTotal;
  final double custoComMargemFalha;
  final double precoVendaDiretaSugerido;
  final double precoMarketplaceSugerido;
  final double lucroLiquidoEstimado;
  final int tempoTotalEfetivoMinutos;
  final int tempoAdicionalTrocasMinutos;

  PricingCalculationResult({
    required this.custoFilamentosImpressos,
    required this.custoPurgaSuporte,
    required this.custoTotalFilamentos,
    required this.custoInsumos,
    required this.custoEnergia,
    required this.custoDepreciacaoManutencao,
    required this.custoMaoDeObra,
    required this.custoBaseTotal,
    required this.custoComMargemFalha,
    required this.precoVendaDiretaSugerido,
    required this.precoMarketplaceSugerido,
    required this.lucroLiquidoEstimado,
    required this.tempoTotalEfetivoMinutos,
    required this.tempoAdicionalTrocasMinutos,
  });
}

class PricingCalculatorService {
  /// Calcula a precificação completa blindada contra prejuízos
  static PricingCalculationResult calculate({
    // Filamentos e Multicor / AMS
    required List<FilamentCostItem> filamentos,
    required double pesoPurgaSuporteGramas,
    required int quantidadeTrocasFilamento,
    int segundosPorTroca = 75, // Média do AMS Bambu Lab / CFS

    // Insumos
    required List<InsumoCostItem> insumos,

    // Impressora e Energia
    required int tempoImpressaoFatiadorMinutos,
    required int potenciaWatts,
    required double valorKwh,
    required double valorAquisicaoImpressora,
    required int vidaUtilHoras,
    required double custoManutencaoHora,

    // Mão de Obra
    required int tempoMaoDeObraMinutos,
    required double valorHoraMaoDeObra,

    // Margens e Taxas
    required double taxaFalhaPercentual,
    required double margemLucroPercentual,
    double comissaoMarketplacePercentual = 0.0,
    double taxaFixaMarketplace = 0.0,
    double taxaPagamentoPercentual = 0.0,
    double taxaImpostoPercentual = 0.0,
  }) {
    // 1. Tempo adicional de trocas no AMS
    final tempoAdicionalTrocasMinutos = ((quantidadeTrocasFilamento * segundosPorTroca) / 60.0).round();
    final tempoTotalEfetivoMinutos = tempoImpressaoFatiadorMinutos + tempoAdicionalTrocasMinutos;

    // 2. Custo dos filamentos na peça
    double custoFilamentosImpressos = 0.0;
    double somaCustoPorGrama = 0.0;
    for (final f in filamentos) {
      custoFilamentosImpressos += f.custoTotal;
      somaCustoPorGrama += f.custoPorGrama;
    }

    final custoMedioPorGrama = filamentos.isNotEmpty ? (somaCustoPorGrama / filamentos.length) : 0.12;
    final custoPurgaSuporte = pesoPurgaSuporteGramas * custoMedioPorGrama;
    final custoTotalFilamentos = custoFilamentosImpressos + custoPurgaSuporte;

    // 3. Custo de insumos
    double custoInsumos = 0.0;
    for (final ins in insumos) {
      custoInsumos += ins.custoTotal;
    }

    // 4. Custo de energia elétrica
    final horasEfetivas = tempoTotalEfetivoMinutos / 60.0;
    final custoEnergia = (potenciaWatts / 1000.0) * horasEfetivas * valorKwh;

    // 5. Custo de máquina (amortização + manutenção)
    final amortizacaoHora = vidaUtilHoras > 0 ? (valorAquisicaoImpressora / vidaUtilHoras) : 0.0;
    final custoDepreciacaoManutencao = (amortizacaoHora + custoManutencaoHora) * horasEfetivas;

    // 6. Custo de mão de obra
    final custoMaoDeObra = (tempoMaoDeObraMinutos / 60.0) * valorHoraMaoDeObra;

    // 7. Custo Base Total
    final custoBaseTotal = custoTotalFilamentos +
        custoInsumos +
        custoEnergia +
        custoDepreciacaoManutencao +
        custoMaoDeObra;

    // 8. Custo com Margem de Segurança / Falha
    final custoComMargemFalha = custoBaseTotal * (1.0 + (taxaFalhaPercentual / 100.0));

    // 9. Preço de Venda Direta (Pix / Balcão)
    final precoVendaDiretaSugerido = custoComMargemFalha * (1.0 + (margemLucroPercentual / 100.0));

    // 10. Preço com Margem de Marketplace
    final totalDeducoesTaxas = (comissaoMarketplacePercentual + taxaPagamentoPercentual + taxaImpostoPercentual) / 100.0;
    double precoMarketplaceSugerido = precoVendaDiretaSugerido;
    if (totalDeducoesTaxas < 1.0) {
      precoMarketplaceSugerido = (precoVendaDiretaSugerido + taxaFixaMarketplace) / (1.0 - totalDeducoesTaxas);
    }

    final lucroLiquidoEstimado = precoVendaDiretaSugerido - custoComMargemFalha;

    return PricingCalculationResult(
      custoFilamentosImpressos: custoFilamentosImpressos,
      custoPurgaSuporte: custoPurgaSuporte,
      custoTotalFilamentos: custoTotalFilamentos,
      custoInsumos: custoInsumos,
      custoEnergia: custoEnergia,
      custoDepreciacaoManutencao: custoDepreciacaoManutencao,
      custoMaoDeObra: custoMaoDeObra,
      custoBaseTotal: custoBaseTotal,
      custoComMargemFalha: custoComMargemFalha,
      precoVendaDiretaSugerido: precoVendaDiretaSugerido,
      precoMarketplaceSugerido: precoMarketplaceSugerido,
      lucroLiquidoEstimado: lucroLiquidoEstimado,
      tempoTotalEfetivoMinutos: tempoTotalEfetivoMinutos,
      tempoAdicionalTrocasMinutos: tempoAdicionalTrocasMinutos,
    );
  }
}
