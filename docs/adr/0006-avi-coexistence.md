# ADR-0006: Coexistência com o Additional Vehicle Info, sem integração ativa

## Status
Aceito

## Contexto
Os requisitos §11 pedem compatibilidade explícita com o *Additional Vehicle
Info* (AVI). A pesquisa (PRD §External Research, "Additional Vehicle Info")
identificou o mod `FS25_additionalVehicleInfo` (Helfer B., v1.0.0.0) e
verificou, no seu `src/main.lua`, que ele:
- só estende a caixa de informações do HUD **in-world**
  (`PlayerHUDUpdater.showVehicleInfo`, sobrescrito guardando o original) e a
  tela de configurações do menu (`InGameMenuSettingsFrame`);
- **não toca `ShopConfigScreen`, `processAttributeData` nem
  `registerCustomSpecValues`** (verificado por leitura do código);
- não expõe API pública nem depende de outro mod no `modDesc`.

Como este mod (`FS25_VehiclePerformance`) atua exclusivamente na tela de
configuração da loja (ADR-0005) e o AVI atua exclusivamente no HUD in-world e
no menu de configurações, não há sobreposição de tela nem de dado exibido
entre os dois. O risco de conflito é, portanto, estruturalmente nulo — não
por acordo entre os dois mods, mas porque eles não competem pelo mesmo ponto
de extensão do jogo.

## Decisão
A integração com o AVI é só **coexistência e detecção**, nunca integração
ativa. `adapters/AdditionalVehicleInfoAdapter.detect(logger)`:
- detecta a presença via `g_modIsLoaded["FS25_additionalVehicleInfo"]`
  (nome exato, minúsculo) e a versão via `g_modManager:getModByName(...)`,
  tudo dentro de um `pcall`;
- não instala nenhum hook, não lê nenhuma tabela interna do AVI
  (`_G["FS25_additionalVehicleInfo"]` ou equivalente) e não esconde nem
  altera nenhuma linha do AVI;
- o resultado (`present`, `version`, `integration`) só alimenta `vpStatus`,
  para diagnóstico do jogador/desenvolvedor.

Se no futuro surgir um mod "Additional Vehicle Info" diferente que **toque**
a loja (hipótese registrada como Open Question na pesquisa), esta decisão
precisa ser revisitada.

## Consequências
- Nenhum código deste mod depende do AVI estar presente, instalado com
  determinada versão, ou sequer existir — o mod funciona de forma idêntica
  com ou sem ele.
- Uma falha na própria detecção (ex.: `g_modManager` incompatível num patch
  futuro) fica isolada: `integration="error"`, logada uma vez, sem afetar o
  restante do mod (requisitos §11.4; testado em `tests/unit/avi_spec.lua`).
- Não há teste automatizado possível que rode o AVI real, porque ele não
  está disponível neste ambiente de desenvolvimento (sem o FS25 instalado).
  A verificação "loja e HUD funcionam juntos, sem erro de nenhum dos dois"
  fica pendente de teste manual em jogo (`docs/release-checklist.md`).
