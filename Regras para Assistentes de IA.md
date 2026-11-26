# Prompt Mestre - Aplicativo 3D Calc & Management ERP (Flutter Multiplataforma)

> **Instruções de Uso:** Copie este arquivo ou utilize-o como prompt principal na sua ferramenta de IA (Copilot, Antigravity, Cursor, etc.) para inicializar ou expandir a estrutura do aplicativo.

## 1. Visão Geral do Produto

Aplicativo multiplataforma (Desktop Windows/macOS/Linux, Android e iOS) para gestão completa, precificação blindada contra prejuízos, controle de estoque (filamentos e insumos com baixa automática), fila de produção e controle financeiro (caixa, saldo devedor e payback/ROI) para estúdios e operações de impressão 3D.

## 2. Stack Tecnológica e Arquitetura

* **Framework:** Flutter (Layout responsivo com `NavigationRail` para Desktop e `NavigationBar` para Mobile).

* **Arquitetura:** Clean Architecture / Feature-First com gerenciamento de estado via Riverpod (ou Bloc).

* **Banco de Dados Local (Offline-First):** `Drift` com `drift_flutter` (SQLite).

* **Integração Barcode (pub.dev):** `mobile_scanner` para leitura de código de barras/QR via câmera e `barcode_widget` para geração de etiquetas.

* **Leitor 3D:** Parser nativo usando o pacote `archive` para arquivos `.3mf` (Bambu Studio / OrcaSlicer / PrusaSlicer) e Regex para `.gcode`.

* **Nuvem & Sincronização (Futuro):** Preparado para `Supabase` (Auth Google/Apple, PostgreSQL e Storage).

## 3. Modelagem Completa das 14 Tabelas (Drift / Database)

### 1. `ConfiguracoesGerais`

* `id`: Text (UUID v4)

* `valorKwh`: Real (Custo por kWh da conta de luz)

* `valorHoraMaoDeObra`: Real (Valor da hora de trabalho manual)

* `taxaFalhaPadraoPercentual`: Real (Margem de segurança para falhas, ex: 10%)

* `margemLucroPadraoPercentual`: Real (Margem padrão desejada)

* `taxaImpostoPercentual`: Real (Imposto do negócio / MEI / Simples)

### 2. `Impressoras`

* `id`: Text (UUID v4)

* `nome`: Text (ex: "Bambu Lab A1 Combo")

* `potenciaWatts`: Int (Consumo médio em Watts, ex: 150)

* `valorAquisicao`: Real (Preço pago pela máquina)

* `vidaUtilHoras`: Int (Horas de vida útil estimadas)

* `custoManutencaoHora`: Real (Custo reserva por hora de uso)

* `fornecedorOndeComprou`: Text (Opcional)

* `linkCompra`: Text (Opcional)

* `observacoes`: Text (Opcional)

### 3. `Filamentos`

* `id`: Text (UUID v4)

* `marca`: Text (ex: Bambu Lab, Elegoo, Polymaker)

* `material`: Text (PLA, PETG, TPU, ABS, etc.)

* `corNome`: Text

* `corHex`: Text (ex: "#7D78A3")

* `pesoInicialGramas`: Real (ex: 1000)

* `pesoAtualGramas`: Real (Saldo em estoque - baixa automática)

* `precoPago`: Real (Valor total pago no carretel)

* `codigoBarrasEan`: Text (Opcional - para binar com `mobile_scanner`)

* `alertaEstoqueMinimoGramas`: Real (ex: 150)

* `fornecedorOndeComprou`: Text

* `linkCompra`: Text

* `observacoes`: Text

* **Campo Calculado:** `custoPorGrama = precoPago / pesoInicialGramas`

### 4. `Insumos` (Acessórios e Embalagens)

* `id`: Text (UUID v4)

* `nome`: Text (ex: "Argola chaveiro", "Ímã 8x2mm", "Caixa P")

* `categoria`: Enum/Text (`ACESSORIO`, `EMBALAGEM`)

* `quantidadeComprada`: Int

* `quantidadeAtual`: Int (Saldo em estoque - baixa automática)

* `precoPacotePago`: Real

* `codigoBarrasEan`: Text (Opcional)

* `fornecedorOndeComprou`: Text

* `linkCompra`: Text

* `observacoes`: Text

* **Campo Calculado:** `custoUnitario = precoPacotePago / quantidadeComprada`

### 5. `CanaisVenda` (Marketplaces)

* `id`: Text (UUID v4)

* `nome`: Text (ex: "Venda Direta / Pix", "Shopee", "Mercado Livre")

* `comissaoPercentual`: Real (ex: 14%)

* `taxaFixaPorVenda`: Real (ex: R\$ 4,00)

* `taxaAntecipacaoPercentual`: Real

### 6. `FormasPagamento`

* `id`: Text (UUID v4)

* `nome`: Text (ex: "Pix", "Cartão de Crédito 1x", "Dinheiro")

* `taxaPercentual`: Real

* `diasParaCair`: Int

### 7. `Clientes`

* `id`: Text (UUID v4)

* `nome`: Text

* `telefoneWhatsapp`: Text

* `email`: Text

* `cpfCnpj`: Text

* `cep`, `endereco`, `numero`, `complemento`, `bairro`, `cidade`, `estado`: Text

* `observacoes`: Text

### 8. `Produtos` (Catálogo / Receita)

* `id`: Text (UUID v4)

* `nome`: Text (ex: "Chaveiro Gengar Articulado")

* `impressoraPadraoId`: Text (FK)

* `tempoImpressaoMinutos`: Int

* `tempoMaoDeObraMinutos`: Int

* `pesoPurgaSuporteGramas`: Real

* `estoqueProntoUnidades`: Int (Peças em prateleira)

* `precoVendaSugerido`: Real

* `codigoBarrasProduto`: Text (Para leitura no PDV/vendas)

* `linkModeloOriginal`: Text (ex: MakerWorld / Printables)

* `licencaComercial`: Text (ex: "Livre", "MakerWorld Exclusivo")

* `arquivoFatiadoNome`: Text

* `arquivoFatiadoPathLocal`: Text

* `arquivoFatiadoCloudUrl`: Text

* `thumbnailPath`: Text (Imagem do `.3mf` ou foto cadastrada)

### 9. `ProdutoFilamentos` (N:N)

* `id`: Text (UUID v4)

* `produtoId`: Text (FK)

* `filamentoId`: Text (FK)

* `pesoUtilizadoGramas`: Real

### 10. `ProdutoInsumos` (N:N)

* `id`: Text (UUID v4)

* `produtoId`: Text (FK)

* `insumoId`: Text (FK)

* `quantidadeUtilizada`: Int

### 11. `HistoricoProducao`

* `id`: Text (UUID v4)

* `produtoId`: Text (FK)

* `impressoraId`: Text (FK)

* `dataProducao`: DateTime

* `quantidadeProduzida`: Int

* `status`: Enum/Text (`SUCESSO`, `FALHA`)

* `custoTotalProducao`: Real

### 12. `Vendas`

* `id`: Text (UUID v4)

* `clienteId`: Text (FK - Nullable)

* `canalVendaId`: Text (FK)

* `formaPagamentoId`: Text (FK)

* `dataVenda`: DateTime

* `valorTotalVenda`: Real

* `valorFreteCobrado`: Real

* `custoFretePago`: Real

* `descontoAplicado`: Real

* `valorJaPago`: Real (Suporte a sinal/encomendas 50/50)

* `statusPagamento`: Enum/Text (`PAGO`, `PARCIAL`, `PENDENTE`)

* `statusProducao`: Enum/Text (`ORCAMENTO`, `AGUARDANDO_IMPRESSAO`, `IMPRIMINDO`, `PRONTO`, `ENTREGUE`)

### 13. `VendaItens` (N:N)

* `id`: Text (UUID v4)

* `vendaId`: Text (FK)

* `produtoId`: Text (FK)

* `quantidade`: Int

* `precoUnitarioPraticado`: Real

* `custoUnitarioNaEpoca`: Real

### 14. `MovimentacoesCaixa`

* `id`: Text (UUID v4)

* `tipo`: Enum/Text (`ENTRADA`, `SAIDA_INVESTIMENTO`, `SAIDA_ESTOQUE`, `SAIDA_DESPESA`)

* `categoria`: Enum/Text (`VENDA`, `IMPRESSORA`, `FILAMENTO`, `INSUMO`, `MANUTENCAO`, `OUTROS`)

* `referenciaId`: Text (ID da Venda, Impressora ou Filamento)

* `descricao`: Text

* `valor`: Real

* `dataMovimentacao`: DateTime

* `status`: Enum/Text (`PAGO`, `PENDENTE`)

## 4. Fórmulas de Precificação e Cálculos Financeiros

```
1. CustoFilamentos = ∑ (pesoUtilizadoGramas * custoPorGrama) + (pesoPurgaSuporteGramas * custoPorGramaMedio)
2. CustoInsumos = ∑ (quantidadeUtilizada * custoUnitario)
3. CustoEnergia = (potenciaWatts / 1000) * (tempoImpressaoMinutos / 60) * valorKwh
4. CustoMaquina = ((valorAquisicao / vidaUtilHoras) + custoManutencaoHora) * (tempoImpressaoMinutos / 60)
5. CustoMaoDeObra = (tempoMaoDeObraMinutos / 60) * valorHoraMaoDeObra
6. CustoBase = CustoFilamentos + CustoInsumos + CustoEnergia + CustoMaquina + CustoMaoDeObra
7. CustoComFalha = CustoBase * (1 + (taxaFalhaPadraoPercentual / 100))
8. PrecoVendaDireta = CustoComFalha * (1 + (margemLucroPadraoPercentual / 100))
9. PrecoMarketplace = (PrecoVendaDireta + taxaFixaPorVenda) / (1 - ((comissaoPercentual + taxaPagamentoPercentual + taxaImpostoPercentual) / 100))

```

## 5. Regras de Leitura de Código de Barras (`pub.dev`)

1. **Scanner de Câmera (`mobile_scanner`):**

   * No celular (Android/iOS) ou webcam (Desktop), abrir modal de scanner.

   * Ao bipar um código EAN/QR:

     * Se estiver na tela de **Vendas/PDV**: adicionar o produto correspondente ao carrinho.

     * Se estiver na tela de **Estoque**: buscar o carretel ou insumo cadastrado com aquele código.

2. **Gerador de Código de Barras (`barcode_widget`):**

   * Permitir gerar e imprimir etiquetas com código de barras para produtos impressos da prateleira.