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

## Licença

Código sob MIT (`LICENSE`). Ícone e arte com todos os direitos reservados
(`LICENSE-ART.md`).
