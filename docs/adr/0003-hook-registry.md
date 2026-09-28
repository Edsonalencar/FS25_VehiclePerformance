# ADR-0003: HookRegistry central para todos os hooks no jogo

## Status
Aceito

## Contexto
O mod precisa se anexar a `ShopConfigScreen:registerCustomSpecValues` (Fase
4) sem quebrar a loja caso a API mude num patch futuro, e sem conflitar com
outros mods que façam o mesmo (requisitos §7, §12; PRD §Dependencies&Risks:
"outros mods que também anexam em `registerCustomSpecValues`"). Sobrescrever
funções do jogo diretamente, sem uma camada central, tem riscos conhecidos:
retorno original descartado, hook instalado em classe base afetando telas
não relacionadas, hook instalado duas vezes duplicando comportamento, e uma
falha dentro do hook quebrando a tela inteira da loja. Essa é a mesma
decisão do `SmartShopSearch` (ADR-0003 de lá), reaplicada aqui.

## Decisão
Todo hook do jogo passa por `src/adapters/HookRegistry.lua`. `HookRegistry.add`
recebe `{id, target, method, kind, fn}`:
- `kind` é sempre `"append"` (via `Utils.appendedFunction`) para hooks deste
  mod, nunca `"overwrite"` — o mod só lê, nunca substitui comportamento da
  loja (requisitos §"O mod só lê"; `"overwrite"` existe no `HookRegistry`
  como mecanismo genérico, herdado do SSS, mas nenhum adapter deste mod o
  usa);
- é sempre instalado numa classe concreta (`ShopConfigScreen`), nunca numa
  classe base compartilhada com outras telas;
- é idempotente por `id`: registrar o mesmo id duas vezes não duplica o
  efeito;
- o corpo roda em `pcall`; após 3 falhas consecutivas o hook se
  autodesativa (`entry.active = false`) e passa a não fazer nada, sem
  propagar o erro para o jogo nem para outros mods;
- se o alvo não existir ou não for função, o registro falha e loga um
  warning, em vez de lançar erro no carregamento do mod.

## Consequências
- Um hook instalado duas vezes (ex.: por engano, ou por outro caminho de
  código) não duplica linhas na loja.
- Uma falha de leitura ou de formatação dentro do hook não quebra a
  `ShopConfigScreen`: a loja continua funcional só com as linhas vanilla
  (verificado em `tests/unit/resilience_spec.lua`, Fase 5).
- `vpStatus` expõe o estado de cada hook (ativo/falhas) via
  `HookRegistry.status()`, para diagnóstico sem precisar abrir o log.
- `AdditionalVehicleInfoAdapter` (Fase 5) não usa o `HookRegistry` porque não
  instala hook nenhum — só lê `g_modIsLoaded`/`g_modManager` (ADR-0006).
