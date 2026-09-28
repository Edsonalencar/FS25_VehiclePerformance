# ADR-0002: Arquitetura hexagonal (core / app / adapters)

## Status
Aceito

## Contexto
As fórmulas de desempenho (F1-F12, `docs/FORMULAS.md`) precisam ser
testáveis fora do jogo, com fixtures determinísticos, para que erros de
cálculo sejam pegos em CI local (`make ci`) em vez de só em jogo. Ao mesmo
tempo, a única fonte de dados confiável é o veículo de preview da loja
(`ShopConfigScreen`, com `setForceServer(true)`), que só existe dentro do
jogo. Misturar as duas coisas — como fazem as referências de infraestrutura
estudadas (EnhancedVehicle, AVI) — tornaria o núcleo de cálculo impossível de
testar sem o jogo rodando e frágil a qualquer mudança de patch na GUI. É a
mesma decisão já tomada no `SmartShopSearch` (ADR-0002 de lá), aqui reaplicada
ao domínio de análise de desempenho.

## Decisão
`src/core/` é Lua 5.1 puro, determinístico e sem nenhum global do jogo:
implementa as fórmulas F1-F12 sobre um `Snapshot` (tabela pura e serializável)
e produz uma `PerformanceData`. `src/adapters/` é a única camada que toca
APIs do FS25: lê o veículo de preview e monta o `Snapshot`
(`RuntimeVehicleReader`), grava/lê dumps XML (`SnapshotXmlWriter`/parser
offline), instala hooks na loja (`ShopConfigAdapter` via `HookRegistry`) e
detecta o AVI (`AdditionalVehicleInfoAdapter`). `src/app/` orquestra
`core/` via portas injetadas (cache, formatação de linhas, API pública,
ciclo de vida), sem conhecer o jogo diretamente. A regra de dependência é
verificada automaticamente por `tools/check_deps.py`: `core/` não pode usar
`g_*`/`Utils.`/`XMLFile`/`io.`/`os.`; `app/` não pode usar `g_*`/`XMLFile`/
`adapters`.

## Consequências
- As 12 fórmulas e os analisadores de motor/transmissão/diferenciais/rodas
  são testáveis 100% em CI local, sem o jogo, usando os fixtures manuais e
  (quando existirem) os dumps reais.
- Mudanças de patch do FS25 na GUI ou na API do veículo afetam só
  `adapters/`; o núcleo de cálculo não muda.
- A API pública (`app/PublicApi.lua`) fica isolada de globais do jogo: um
  mod de terceiros que a chama nunca aciona código que toca `g_*`
  diretamente, só as portas injetadas.
- Exige disciplina de não vazar globais do jogo para `core/`/`app/`, imposta
  por lint automatizado (`tools/check_deps.py`, parte de `make ci`).
