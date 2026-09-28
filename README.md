# FS25 Vehicle Performance

Mostra dados de desempenho técnico — tração, potência e torque de pico
calculados, relação peso/potência, força de tração estimada e velocidade sob
carga — na tela de configuração da loja do Farming Simulator 25. Lê os dados
do próprio jogo; não altera física, preço nem configuração.

## Arquitetura

O mod segue uma arquitetura hexagonal (ver `specs/research/`,
`specs/plans/` e `docs/adr/`):

- `src/core/` — análise de desempenho em Lua 5.1 puro, testável fora do jogo
  (motor, transmissão, diferenciais, rodas, tração).
- `src/app/` — orquestração (ciclo de vida, cache, formatação de linhas,
  API pública) injetada por portas.
- `src/adapters/` — única camada que toca APIs do FS25 (loja, veículo,
  idioma, logging, settings).

## Build e desenvolvimento

Pré-requisitos: Lua 5.1, LuaRocks, busted, luacheck, StyLua, Python 3.11+.

```bash
make setup        # instala toolchain Lua local (hererocks) e busted/luacheck
make ci           # fmt-check + lint + deps + test + verify
make build        # gera dist/FS25_VehiclePerformance-<versão>.zip
```

Ver `tools/dev_link.sh` para linkar `src/` na pasta de mods do jogo durante o
desenvolvimento.

## Testes

```bash
make unit         # tests/unit (busted)
make golden       # tests/golden (regressão contra dumps reais do jogo)
```

## Console (em jogo)

- `vpStatus` — estado do mod, hooks, cache e detecção do Additional Vehicle Info.
- `vpDump` — grava um snapshot XML por veículo de preview aberto na loja.
- `vpAnalyze` — imprime todas as métricas calculadas do preview atual.
- `vpSet <showIndex|logLevel|pullingRef> <valor>` — grava em
  `modSettings/FS25_VehiclePerformance/settings.xml`.

## API pública

O mod expõe uma API estável e somente leitura para outros mods, instalada
por `src/app/PublicApi.lua` (`VehiclePerformance.api`) e também publicada
como o global `g_vehiclePerformanceApi`, no mesmo padrão de outros mods FS25
que expõem API própria:

```lua
-- de dentro de outro mod:
local perf = g_vehiclePerformanceApi.getPerformance(vehicle)     -- PerformanceData ou nil
local drivetrain = g_vehiclePerformanceApi.getMetric(vehicle, "drivetrain") -- Value da métrica, ou nil
local config = g_vehiclePerformanceApi.getCurrentConfiguration(vehicle)     -- cópia; mutar não afeta o veículo
```

- `getPerformance(vehicle)` nunca lança erro: devolve `nil` se `vehicle` for
  `nil`, se não houver `storeItem` correspondente, ou se qualquer etapa da
  leitura/análise falhar.
- `getMetric(vehicle, metricId)` devolve o `Value` de uma métrica específica
  (ver `docs/FORMULAS.md` para os ids F1-F12), ou `nil`.
- `getCurrentConfiguration(vehicle)` devolve sempre uma **cópia rasa** de
  `vehicle.configurations` — alterar o resultado nunca afeta o veículo. Os
  diferenciais (e, por consequência, a métrica `drivetrain`) só existem com
  dados de servidor; num cliente MP puro, fora da loja, essa métrica pode
  sair `"unknown"`.

Detalhes de cada métrica, unidades e regras de "desconhecido" estão em
`docs/FORMULAS.md`.

## Licença

Código sob MIT (`LICENSE`). Ícone e arte com todos os direitos reservados
(`LICENSE-ART.md`).
