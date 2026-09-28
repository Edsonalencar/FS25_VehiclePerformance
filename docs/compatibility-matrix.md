# Matriz de compatibilidade

**Nenhuma célula desta matriz foi verificada em jogo.** Este ambiente de
desenvolvimento não tem o Farming Simulator 25 instalado. Toda célula abaixo
representa o resultado **esperado** segundo `specs/plans/2026-09-27-fs25-vehicle-performance-1.0.md`
e `requisitos.md` §20/§21, e está marcada explicitamente como
`[PENDENTE verificação em jogo]`. Ninguém deve tratar esta tabela como prova
de que o mod funciona — é um roteiro para quem for testar manualmente.

## Veículos × integração

Veículos conforme requisitos §20 ("Testes mínimos") e §21 ("Casos reais
iniciais de validação"), cruzados com os quatro cenários de integração.

Legenda de integração:
- **Sem AVI** — `FS25_additionalVehicleInfo` não instalado, single-player.
- **Com AVI** — `FS25_additionalVehicleInfo` 1.0.0.0 instalado, single-player.
- **Dedicated** — servidor dedicado (`g_dedicatedServer ~= nil`).
- **MP cliente** — cliente conectado a um host/dedicated, sem ser o host.

| Veículo | Sem AVI | Com AVI | Dedicated | MP cliente |
|---|---|---|---|---|
| Ford 8030 (`FS25_Ford_8030_jonilson`, tratores 2WD/4WD conforme config, CVT e manual) | Linhas de desempenho aparecem na loja; F6 `drivenAxles` reflete a config selecionada. `[PENDENTE verificação em jogo]` | Igual à coluna anterior + HUD in-world do AVI funciona normalmente, sem erro de nenhum dos dois mods. `[PENDENTE verificação em jogo]` | Mod em `disabled-dedicated`; nenhuma linha, nenhum hook instalado, sem erro no log do servidor. `[PENDENTE verificação em jogo]` | Loja funciona igual à coluna "Sem AVI" (preview força dados de servidor, ADR-0004); métricas sem dado saem "desconhecido" ou omitidas, nunca erro. `[PENDENTE verificação em jogo]` |
| Volvo FH 2012 (`FS25_VolvoFH12antiga`, caminhão 6x2/6x4, rodas por XML externo) | Linhas aparecem; F6 distingue 6x2 de 6x4 corretamente (`volvo_6x4 > volvo_6x2` em F_tração, `docs/FORMULAS.md`). `[PENDENTE verificação em jogo]` | Idem + coexistência sem erro. `[PENDENTE verificação em jogo]` | `disabled-dedicated`. `[PENDENTE verificação em jogo]` | Igual à coluna "Sem AVI". `[PENDENTE verificação em jogo]` |
| Valtra BH180 (`FS25_Valtra_BH180_Dentinho`, XML malformado na l.234, arquivos de som/config ausentes) | Config "BH 145" completa mostra linhas; demais configs herdam de `config(0)` e ainda assim não devem gerar erro (regra "XML válido porém não convencional", requisitos §20). `[PENDENTE verificação em jogo]` | Idem + coexistência sem erro. `[PENDENTE verificação em jogo]` | `disabled-dedicated`. `[PENDENTE verificação em jogo]` | Igual à coluna "Sem AVI". `[PENDENTE verificação em jogo]` |
| Trator nativo 2WD (ex.: um trator base sem diferencial dianteiro habilitado) | F6 sai `label` do tipo `NxK` sem tração dianteira; sem índice de puxada por padrão (`ui#showPullingIndex=false`). `[PENDENTE verificação em jogo]` | Idem + coexistência sem erro. `[PENDENTE verificação em jogo]` | `disabled-dedicated`. `[PENDENTE verificação em jogo]` | Igual à coluna "Sem AVI". `[PENDENTE verificação em jogo]` |
| Trator nativo com esteiras (`Crawlers`, visual sobre rodas comuns) | Rodas motrizes calculadas normalmente (esteira é só visual sobre a física de roda, PRD §Rodas); nenhuma métrica deveria sair `unknown` por causa da esteira em si. `[PENDENTE verificação em jogo]` | Idem + coexistência sem erro. `[PENDENTE verificação em jogo]` | `disabled-dedicated`. `[PENDENTE verificação em jogo]` | Igual à coluna "Sem AVI". `[PENDENTE verificação em jogo]` |
| Caminhão nativo (qualquer, para comparação com o Volvo de terceiros) | Linhas aparecem; valores plausíveis (potência/torque/tração compatíveis com a categoria "trucks"). `[PENDENTE verificação em jogo]` | Idem + coexistência sem erro. `[PENDENTE verificação em jogo]` | `disabled-dedicated`. `[PENDENTE verificação em jogo]` | Igual à coluna "Sem AVI". `[PENDENTE verificação em jogo]` |

## Cenários adicionais de integração (requisitos §20)

| Cenário | Resultado esperado | Status |
|---|---|---|
| Troca rápida entre veículos na loja | Linhas atualizam a cada preview novo, sem acumular trabalho por frame, sem travar a UI. | `[PENDENTE verificação em jogo]` |
| Mudança de configuração (motor/rodas/transmissão) | Linhas recalculadas no próximo `registerCustomSpecValues`; cache por `xmlFilename + configurações` invalida corretamente. | `[PENDENTE verificação em jogo]` |
| Abertura/fechamento repetido da loja | Sem hooks duplicados (idempotência do `HookRegistry`, ADR-0003), sem crescimento de memória perceptível. | `[PENDENTE verificação em jogo]` |
| Veículo com parâmetros incompletos (sem curva de motor, sem diferenciais, etc.) | Métricas dependentes saem "desconhecido" ou omitidas; nunca erro na tela. | `[PENDENTE verificação em jogo]` |
| `debug#enabled=true` + `debug#simulateFailure=hook` | Após 3 aberturas, log mostra erro e desativação do hook; loja segue funcional só com linhas vanilla (equivalente automatizado: `tests/unit/resilience_spec.lua`). | Comportamento equivalente **validado em teste automatizado** fora do jogo; a verificação com o hook real (`ShopConfigAdapter`) e o jogo rodando fica `[PENDENTE verificação em jogo]`. |
| GIANTS TestRunner sobre o ZIP publicado | Sem erros/avisos. | `[PENDENTE — requer TestRunner, não disponível neste ambiente]` |

## Notas para quem for preencher esta matriz de verdade

1. Rodar cada veículo nas 4 colunas de integração, anotando `OK` ou o desvio
   observado (com print/log relevante) em vez de `[PENDENTE verificação em
   jogo]`.
2. Para "Com AVI", confirmar especificamente: (a) as linhas deste mod
   aparecem normalmente na loja; (b) o HUD in-world do AVI aparece
   normalmente; (c) nenhum dos dois loga erro.
3. Para "Dedicated", confirmar que nenhuma linha de log deste mod aparece
   além do bootstrap básico, e que `vpStatus`/`vpDump`/`vpAnalyze` não
   registram comandos de console no servidor (ou, se registram, respondem de
   forma segura sem GUI).
4. Qualquer célula que não bater com o "esperado" descrito aqui deve virar um
   item em `docs/api-findings/` (Fase 3) e, se for um defeito de fórmula,
   uma atualização em `docs/FORMULAS.md`.
