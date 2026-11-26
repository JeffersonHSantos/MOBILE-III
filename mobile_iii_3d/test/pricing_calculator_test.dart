import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_iii_3d/services/pricing_calculator_service.dart';

void main() {
  test('PricingCalculatorService calculates monocolor print without purge correctly', () {
    final result = PricingCalculatorService.calculate(
      filamentos: [
        FilamentCostItem(
          nomeCor: 'Preto',
          material: 'PLA',
          precoPorQuilo: 100.0, // R$ 0,10/g
          pesoGramas: 50.0,     // R$ 5,00
          slotAms: 1,
        ),
      ],
      pesoPurgaSuporteGramas: 0.0,
      quantidadeTrocasFilamento: 0,
      insumos: [
        InsumoCostItem(
          nome: 'Argola Chaveiro',
          custoUnitario: 0.25,
          quantidade: 1, // R$ 0,25
        ),
      ],
      tempoImpressaoFatiadorMinutos: 60, // 1h
      potenciaWatts: 150,                // 0.15 kW
      valorKwh: 1.0,                     // R$ 0,15 energia
      valorAquisicaoImpressora: 2000.0,  // vida util 2000h = R$ 1,00/h
      vidaUtilHoras: 2000,
      custoManutencaoHora: 0.50,         // R$ 1,50 total maquina
      tempoMaoDeObraMinutos: 12,         // 0.2h
      valorHoraMaoDeObra: 25.0,          // R$ 5,00
      taxaFalhaPercentual: 10.0,
      margemLucroPercentual: 100.0,
    );

    // Custo base: 5.00 + 0.25 + 0.15 + 1.50 + 5.00 = 11.90
    expect(result.custoBaseTotal, closeTo(11.90, 0.01));

    // Custo com falha (+10%): 11.90 * 1.10 = 13.09
    expect(result.custoComMargemFalha, closeTo(13.09, 0.01));

    // Venda Direta (+100% margem): 13.09 * 2 = 26.18
    expect(result.precoVendaDiretaSugerido, closeTo(26.18, 0.01));
    expect(result.tempoTotalEfetivoMinutos, 60);
  });

  test('PricingCalculatorService calculates multicolor AMS print with swaps and purge tower', () {
    final result = PricingCalculatorService.calculate(
      filamentos: [
        FilamentCostItem(
          nomeCor: 'Preto',
          material: 'PLA',
          precoPorQuilo: 120.0, // R$ 0,12/g
          pesoGramas: 40.0,     // R$ 4,80
          slotAms: 1,
        ),
        FilamentCostItem(
          nomeCor: 'Vermelho',
          material: 'PLA',
          precoPorQuilo: 120.0, // R$ 0,12/g
          pesoGramas: 20.0,     // R$ 2,40
          slotAms: 2,
        ),
      ],
      pesoPurgaSuporteGramas: 30.0, // 30g de torre de purga
      quantidadeTrocasFilamento: 40, // 40 trocas de filamento
      segundosPorTroca: 75,         // 40 * 75s = 3000s = 50 min adicionais
      insumos: [],
      tempoImpressaoFatiadorMinutos: 120, // 2h base
      potenciaWatts: 150,
      valorKwh: 0.95,
      valorAquisicaoImpressora: 3800.0,
      vidaUtilHoras: 4000,
      custoManutencaoHora: 0.85,
      tempoMaoDeObraMinutos: 15,
      valorHoraMaoDeObra: 25.0,
      taxaFalhaPercentual: 10.0,
      margemLucroPercentual: 100.0,
    );

    // Tempo adicional: 50 min. Tempo total efetivo: 170 min
    expect(result.tempoAdicionalTrocasMinutos, 50);
    expect(result.tempoTotalEfetivoMinutos, 170);

    // Custo de filamentos da peça: 4.80 + 2.40 = 7.20
    expect(result.custoFilamentosImpressos, closeTo(7.20, 0.01));

    // Custo da torre de purga: 30g * 0.12 = 3.60
    expect(result.custoPurgaSuporte, closeTo(3.60, 0.01));
    expect(result.custoTotalFilamentos, closeTo(10.80, 0.01));
  });
}
