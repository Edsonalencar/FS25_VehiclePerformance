# Rastreabilidade — requisitos.md → componente → verificação

`requisitos.md` não tem IDs por item (nota do plano, "O que não estamos
fazendo": "Rastreabilidade automatizada (`check_trace.py`)"). Esta tabela é
manual, feita na Fase 5, e mapeia cada seção de `requisitos.md` para o(s)
componente(s) que a implementa(m) e para o teste ou verificação
correspondente. Quando a verificação só é possível em jogo, isso está
marcado explicitamente — este ambiente de desenvolvimento não tem o FS25
instalado (ver `docs/release-checklist.md`).

| Seção de `requisitos.md` | Componente(s) | Teste / verificação |
|---|---|---|
| §1 Visão geral | `src/main.lua`, `src/manifest.lua`, arquitetura geral (`docs/adr/0002-hexagonal.md`) | `tests/unit/bootstrap_spec.lua` |
| §2 Objetivos | Todo o mod (linhas na loja + índices + degradação segura) | Ver linhas específicas abaixo (§6, §7, §10, §11) |
| §3 Fora de escopo | Decisões "What We're NOT Doing" no plano; nenhuma listagem via `addSpecType`, nenhum parser XML próprio no caminho principal (ADR-0004), nenhuma seção de GUI própria (ADR-0005) | Revisão de código/PR; ausência de `addSpecType` e de GUI custom em `src/adapters/` |
| §4 Fonte dos dados (4.1-4.6: dados básicos, massa, motor, transmissão, tração/diferenciais, rodas/pneus/esteiras) | `src/adapters/RuntimeVehicleReader.lua` (Fase 2/3), `src/core/analyzers/*` (Fase 2) | `tests/unit/core_*_spec.lua` (Fase 2) com fixtures manuais; golden real `[PENDENTE — requer dumps em jogo]` |
| §5 Configurações do veículo | `app/ConfigurationResolver.lua` (Fase 3), cache por `xmlFilename + configurações` (`app/PerformanceService.lua`, Fase 4) | Testes de cache/ordem estável de chaves (Fase 3/4) |
| §6 Métricas objetivas | `core/metrics/*` (F1-F5, F7-F9), `docs/FORMULAS.md` | `tests/unit/core_metrics_spec.lua` (Fase 2), fixtures manuais em `docs/FORMULAS.md` |
| §7 Índices de desempenho (7.1 Puxada/Tração F10/F12, 7.2 peso/potência F5, 7.3 sob carga F11, 7.4 regra contra índices arbitrários) | `core/metrics/*` (F5, F9-F12), `docs/FORMULAS.md` (§"Por que F11 usa carga fixa") | `tests/unit/core_metrics_spec.lua`, invariantes relativos da tabela de fixtures (`docs/FORMULAS.md`) |
| §8 Arquitetura | `src/core/`, `src/app/`, `src/adapters/`, `tools/check_deps.py` | `python3 tools/check_deps.py` (parte de `make ci`); `docs/adr/0002-hexagonal.md` |
| §9 Modelo interno de dados | `Snapshot` (Fase 2), `PerformanceData` (Fase 2) | Testes de `core/` (Fase 2), roundtrip `Flatten`/`SnapshotXmlWriter` (Fase 3) |
| §10 Integração com a loja do FS25 | `adapters/ShopConfigAdapter.lua` (Fase 4), `app/RowFormatter.lua` (Fase 4), `docs/adr/0005-registerCustomSpecValues.md` | Testes de `RowFormatter`/`ShopConfigAdapter` (Fase 4); linhas reais na tela de configuração `[PENDENTE verificação em jogo]` |
| §11 Compatibilidade com Additional Vehicle Info (11.1-11.4) | `src/adapters/AdditionalVehicleInfoAdapter.lua`, `docs/adr/0006-avi-coexistence.md` | `tests/unit/avi_spec.lua` (Fase 5); coexistência com o AVI real `[PENDENTE verificação em jogo]` |
| §12 Compatibilidade com mods de veículos | `HookRegistry` (`append`, idempotência, autodesativação), degradação segura em `RuntimeVehicleReader`/`core/` para veículos com dados incompletos | `tests/unit/resilience_spec.lua` (Fase 5), `tests/unit/bootstrap_spec.lua` |
| §13 Infraestrutura open source de referência | `docs/adr/0001-clean-room.md` | Revisão de licenças (nenhum código copiado do EnhancedVehicle/AVI) |
| §14 Independência entre projetos | Namespace único `VehiclePerformance` (não `SmartShopSearch`), sem dependência declarada no `modDesc.xml` entre os dois mods | `src/modDesc.xml` (sem `<dependencies>` para o SSS); leitura de `src/main.lua` |
| §15 API interna e extensibilidade | `src/app/PublicApi.lua`, `g_vehiclePerformanceApi` (exposto por `GameBootstrap`, Fase 5/orquestrador) | `tests/unit/api_spec.lua` (Fase 5); um mod de teste chamando `g_vehiclePerformanceApi.getMetric` `[PENDENTE verificação em jogo]` |
| §16 Cache e desempenho | `app/PerformanceService.lua` (cache por configuração, Fase 4), recálculo só ao trocar preview/configuração (ADR-0004) | Testes de cache (Fase 4); ausência de trabalho por frame `[PENDENTE verificação em jogo, profiling]` |
| §17 Logging e diagnóstico | `src/adapters/GameLogger.lua`, `vpStatus` (Fase 3/5) | `tests/unit/bootstrap_spec.lua` (rate-limit, níveis); log limpo em nível info `[PENDENTE verificação em jogo]` |
| §18 Localização | `src/translations/translation_{en,br}.xml`, prefixo `vp_` | Verificação de chaves via `tools/build.py` (parte de `make build`/`make verify`) |
| §19 Critérios de qualidade | `make ci` (fmt-check, lint, deps, test, verify) | `make ci` local; CI remoto fora de escopo (Environment Considerations) |
| §20 Testes mínimos (veículos + integração) | Fixtures de veículos (Ford 8030, Volvo FH, Valtra BH180, tratores/caminhões nativos) | `docs/compatibility-matrix.md` — todas as células `[PENDENTE verificação em jogo]` |
| §21 Casos reais iniciais de validação (Volvo FH, Ford 8030) | `tests/fixtures/` (Fase 2), `tests/golden/` (Fase 3) | Fixtures manuais em `docs/FORMULAS.md`; golden real `[PENDENTE — requer dumps em jogo]` |
| §22 Decisões arquiteturais obrigatórias | `docs/adr/0001` a `0007` | Revisão de PR / leitura dos ADRs |
| §23 Próximas etapas de engenharia | `specs/plans/2026-09-27-fs25-vehicle-performance-1.0.md` (Fases 1-5) | Este documento e o CHANGELOG cobrem o estado de cada fase |
| §24 Referências técnicas | `specs/research/2026-09-27-fs25-vehicle-performance.md` (§External Research) | N/A (documentação, não código) |
| §25 Princípio do produto | Todo o mod: só lê, nunca altera física/preço/configuração | Ausência de qualquer `set*`/`setMass`/`setPrice` em `src/adapters/`; `python3 tools/check_deps.py` não cobre isso diretamente — verificado por revisão de código |
