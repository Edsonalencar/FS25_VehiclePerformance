# ADR-0001: Implementação clean-room, sem código do EnhancedVehicle nem do AVI

## Status
Aceito

## Contexto
Duas referências de infraestrutura foram estudadas durante a pesquisa (PRD
`specs/research/2026-09-27-fs25-vehicle-performance.md`, §Reference
Implementations):

- `ZhooL/FS25_EnhancedVehicle` (`cd80bd2`), licenciado sob CC BY-NC-SA 4.0
  (declarado em `README.md:91-92` e `FS25_EnhancedVehicle.lua:63`, sem arquivo
  LICENSE), arquivado desde 09/08/2026. É *share-alike*, não comercial e exige
  atribuição — incompatível com uma licença MIT permissiva.
- `FS25_additionalVehicleInfo` (Helfer B., v1.0.0.0), publicado no ModHub, sem
  licença declarada em lugar nenhum encontrado.

Nenhum dos dois pode ter código copiado sem violar a licença (ou, no caso do
AVI, sem uma licença explícita que autorize reuso). Por outro lado, o
`SmartShopSearch` (SSS) é projeto próprio, do mesmo autor, licenciado MIT, com
arquitetura e ferramental já validados em outro mod FS25.

## Decisão
Nenhum trecho de código do EnhancedVehicle ou do AVI é copiado. Ambos servem
só como referência de **comportamento observado** (quais hooks existem, quais
campos são lidos, como cada um se posiciona na loja/HUD) — documentado no
PRD, nunca colado no código deste mod. Nomes de APIs do jogo (`g_modIsLoaded`,
`VehicleMotor`, `ShopConfigScreen`, etc.) pertencem à GIANTS, não às
referências.

O `SmartShopSearch`, por ser MIT e do mesmo autor, é reaproveitado como
**padrão de arquitetura e ferramental** (hexagonal, `HookRegistry`,
`SafeCall`/`StateMachine`, `Makefile`, `tools/*.py`, formato de ADR) — não
como "código copiado sem adaptação": cada arquivo reaproveitado é adaptado ao
domínio deste mod (fórmulas de desempenho, `ShopConfigScreen` em vez de
`ShopMenu`/busca textual, etc.).

## Consequências
- Elimina as obrigações de atribuição e *share-alike* do CC BY-NC-SA do
  EnhancedVehicle, e o risco de uma licença não declarada do AVI.
- Todo o núcleo de análise (`core/`) e a leitura do veículo (`adapters/`) são
  escritos a partir da API documentada do jogo (dataS + LUADOC + GDN), não a
  partir do código das referências.
- README e PRD citam as duas referências como fonte de pesquisa, não como
  dependência ou base de código.
- Se no futuro houver interesse em reaproveitar algo específico de qualquer
  referência de terceiros, isso exige licença explícita do autor original,
  registrada antes do reuso.
