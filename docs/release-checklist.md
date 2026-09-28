# Checklist de release

Este checklist cobre a Fase 5 do plano
(`specs/plans/2026-09-27-fs25-vehicle-performance-1.0.md`, §Success Criteria).
Os itens automatizados foram executados neste ambiente de desenvolvimento
(sem o FS25 instalado). Os itens marcados `[PENDENTE]` exigem o jogo, o
GIANTS TestRunner ou o mod `FS25_additionalVehicleInfo` real rodando, e por
isso **não puderam ser verificados aqui** — nada abaixo foi marcado como
feito sem ter sido de fato executado.

## Automatizado (verificado neste ambiente)

- [x] `python3 tools/check_deps.py` — sem violação de pureza de camadas.
- [x] `luacheck src tests` — 0 avisos / 0 erros.
- [x] `stylua --check src tests` — formatação já conforme.
- [x] `busted tests/unit` — todos os specs unitários passam, incluindo os
      desta fase (`resilience_spec.lua`, `avi_spec.lua`, `api_spec.lua`).
- [ ] `make ci` completo (fmt-check + lint + deps + **test** [unit+golden] +
      **verify**) — os passos `golden`, `build` e `verify` dependem de
      `tests/golden/`, `tools/build.py` e fixtures/dumps de outras fases
      (2/3/4) que podem não existir neste worktree; não executado nesta
      fase. `[PENDENTE — depende das Fases 2-4 estarem mescladas]`

## Pendente — requer o jogo, o TestRunner ou o AVI real

- [ ] **GIANTS TestRunner** sobre o ZIP publicado, sem erros.
      `[PENDENTE — TestRunner não está disponível neste ambiente]`
- [ ] **ZIP `FS25_VehiclePerformance-<versão>.zip`** sem a versão no nome do
      mod interno (`modDesc.xml` — `name`/`version` corretos, sem sufixo de
      versão duplicado no `modName`). A geração do ZIP é feita por
      `tools/build.py` (`make build`); a inspeção do conteúdo do ZIP gerado
      fica `[PENDENTE — depende de make build com todas as fases mescladas]`.
- [ ] **Ícone DDS válido** — gerado via `tools/make_icon.sh` a partir de
      `art/`. O script já roda neste ambiente (não depende do jogo), mas a
      validação final de tamanho/compressão do `.dds` resultante (256x256,
      DXT1/DXT5 conforme o padrão do ModHub) precisa ser conferida
      visualmente **dentro do jogo** (o menu de mods do FS25 é o validador
      de fato para esse formato). `[PENDENTE verificação em jogo]`
- [ ] **Log limpo em nível `info`** — nenhuma linha de `error`/`warning`
      inesperada durante uma sessão normal (loja, troca de veículo/config,
      abertura/fechamento repetido). Só pode ser observado com o jogo
      rodando. `[PENDENTE — precisa do jogo]`
- [ ] **Idiomas `en` e `br`** — `[x]` feito: `src/translations/translation_en.xml`
      e `translation_br.xml` existem com o prefixo `vp_` (Fase 1). A
      exibição correta das strings **dentro da loja**, nos dois idiomas,
      ainda é `[PENDENTE verificação em jogo]`.
- [ ] **Sem o AVI**: `vpStatus` mostra `avi=ausente`, loja igual à da Fase 4.
      `[PENDENTE verificação em jogo]`
- [ ] **Com o `FS25_additionalVehicleInfo` 1.0.0.0 instalado**: loja mostra
      as linhas deste mod, HUD in-world mostra as do AVI, log sem erro de
      nenhum dos dois. `[PENDENTE verificação em jogo — requer o AVI real
      instalado]`
- [ ] **`debug#enabled=true` + `debug#simulateFailure="hook"` em jogo**: após
      3 aberturas da loja, log mostra o erro e a desativação do hook real
      (`ShopConfigAdapter`), loja segue funcional só com linhas vanilla. O
      comportamento **equivalente** já está coberto por teste automatizado
      isolado (`tests/unit/resilience_spec.lua`, com um hook genérico via
      `HookRegistry`, já que o hook real da loja pode vir de uma fase em
      paralelo). A verificação com o hook real, em jogo, fica
      `[PENDENTE verificação em jogo]`.
- [ ] **Dedicated server** (real ou `g_dedicatedServer` simulado dentro do
      jogo): mod fica em `disabled-dedicated`, sem hooks. A transição de
      estado já é testada fora do jogo (`tests/unit/bootstrap_spec.lua`); a
      confirmação num processo de dedicated server real fica
      `[PENDENTE verificação em jogo]`.
- [ ] **MP como cliente**: loja funciona, métricas sem dado saem
      "desconhecido" ou são omitidas, sem erro. `[PENDENTE verificação em
      jogo — requer sessão MP com host/dedicated]`
- [ ] **Um mod de teste** chama
      `g_vehiclePerformanceApi.getMetric(vehicle, "drivetrain")` e recebe o
      Value. A API em si (`app/PublicApi.lua`) está testada isoladamente em
      `tests/unit/api_spec.lua`; a exposição real como `g_vehiclePerformanceApi`
      é feita pelo `GameBootstrap` (fora do escopo desta fase — ver nota
      abaixo) e por isso a chamada de um mod de teste real fica
      `[PENDENTE verificação em jogo]`.

## Nota sobre `g_vehiclePerformanceApi`

O plano registra este item como "[A VALIDAR na Fase 5, no jogo, com um mod de
teste mínimo]" (linha 910 do plano). A atribuição de
`getfenv(0).g_vehiclePerformanceApi = ns.api` em `loadMap` e sua limpeza em
`deleteMap` são responsabilidade de `src/adapters/GameBootstrap.lua`, que
este worktree **não edita** (o orquestrador da integração final aplica essa
mudança ao mesclar as fases). `app/PublicApi.lua` e seus testes cobrem tudo
que é testável fora do jogo: `ns.api.getPerformance/getMetric/getCurrentConfiguration`
funcionam corretamente com portas fake, nunca lançam erro, e
`getCurrentConfiguration` sempre devolve cópia.

## Resumo

Nada neste checklist que dependa do jogo, do TestRunner ou do AVI real foi
marcado como concluído. Todos esses itens estão listados também em
`CHANGELOG.md`, seção "Pendente (ambiente sem FS25 instalado)".
