# Changelog

Todas as mudanças notáveis deste projeto são documentadas neste arquivo.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/);
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## 1.0.0 — não lançado

### Adicionado
- Infraestrutura do repositório, toolchain e ciclo de vida do mod: namespace
  único `VehiclePerformance`, manifest de carga, `GameLogger`,
  `SettingsStore`, `HookRegistry`, `SafeCall`/`StateMachine` e
  `GameBootstrap` (Fase 1).
- Núcleo de análise de desempenho em Lua 5.1 puro (`src/core/`): fórmulas
  F1-F12 (potência declarada e de pico, torque de pico e reserva, relação
  peso/potência, trem de força/diferenciais, relação de transmissão, força
  motriz, força de aderência estimada, força de tração e limite, velocidade
  sob carga estimada e índice de puxada heurístico), com marcação
  `declared`/`calculated`/`estimated`/`heuristic` e degradação para
  `unknown` sem erro (Fase 2).
- Leitor de veículo em runtime a partir do preview da loja
  (`setForceServer(true)`), gravação/leitura de dumps XML para fixtures
  offline e comandos de console de diagnóstico (`vpDump`, `vpAnalyze`,
  `vpStatus`) (Fase 3).
- Integração com a tela de configuração da loja
  (`ShopConfigScreen:registerCustomSpecValues`, via `HookRegistry`),
  formatação das linhas (ícone + texto, com "desconhecido" ou omissão para
  métricas sem dado) e cache por veículo/configuração (Fase 4).
- Detecção de coexistência com o *Additional Vehicle Info* (sem hooks, sem
  tocar a loja), API pública estável
  (`VehiclePerformance.api.getPerformance/getMetric/getCurrentConfiguration`,
  também exposta a outros mods como `g_vehiclePerformanceApi`) e
  documentação de arquitetura, fórmulas e rastreabilidade (Fase 5).

### Pendente (ambiente sem FS25 instalado)
Este mod foi desenvolvido num ambiente sem o Farming Simulator 25 instalado,
sem o mod `FS25_additionalVehicleInfo` real e sem o GIANTS TestRunner. Os
itens abaixo são pendências reais, não verificadas, e precisam ser refeitas
por alguém com o jogo disponível antes do release (ver também
`docs/release-checklist.md` e `docs/compatibility-matrix.md`):

- Dumps reais de veículos em jogo (`vpDump`) — os testes usam só fixtures
  calculados manualmente a partir dos XMLs (Ford 8030, Volvo FH, Valtra
  BH180), não dumps do jogo rodando.
- Calibração de `F_ref` (`metrics#pullingRefKN`, F12) a partir da mediana de
  `tractionForceKn` de uma amostra real de veículos — o valor em produção é
  o default original do spec (50 kN), não recalibrado (`docs/FORMULAS.md`).
- Execução do GIANTS TestRunner sobre o ZIP publicado.
- Verificação de compatibilidade com o `FS25_additionalVehicleInfo` real
  instalado (loja + HUD in-world simultâneos, sem erro de nenhum dos dois).
- Todos os itens de verificação manual dos specs das 5 fases: linhas reais
  na tela de configuração para cada veículo de teste (§20/§21), troca
  rápida de veículo/configuração, abertura/fechamento repetido da loja,
  `debug#simulateFailure` com o hook real da loja, dedicated server real,
  sessão MP host/cliente, um mod de teste consumindo
  `g_vehiclePerformanceApi`, ícone `.dds` validado no menu de mods do jogo,
  e log limpo em nível `info` observado numa sessão real.
