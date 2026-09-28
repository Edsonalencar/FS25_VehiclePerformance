# ADR-0005: Linhas via `registerCustomSpecValues`, sem seção de GUI própria

## Status
Aceito

## Contexto
Os requisitos §10 sugerem uma "seção DESEMPENHO" com cabeçalho próprio na
tela de configuração da loja. Na pesquisa (PRD §Data Flow,
`ShopConfigScreen.lua:456,759,773`), verificou-se que o jogo chama
`processAttributeData` ao montar o preview e, ao final, chama
`self:registerCustomSpecValues(values, storeItems, vehicle, saleItem)`
(`:759`) — um ponto de extensão **vazio** (`:773`), feito para mods: basta um
`table.insert(values, {profile=..., value=...})` e o jogo desenha a linha
(ícone + texto) na lista de atributos já existente, com o mesmo layout das
linhas vanilla (potência, peso, velocidade máxima etc.). Não há rótulo nem
cabeçalho de seção nativos nesse ponto de extensão. Construir uma seção
própria com cabeçalho exigiria clonar `self.attributeItem`/criar um layout
novo e mexer em partes do `GUI_PROFILE` e do layout da tela que não são um
ponto de extensão oficial — mais frágil a mudanças de patch e mais código
para manter.

## Decisão
As linhas de desempenho são adicionadas só via `registerCustomSpecValues`,
usando os ícones nativos já catalogados em `ShopConfigScreen.GUI_PROFILE`
(`WHEELS`, `POWER`, `WEIGHT`, `TRANSMISSION`, `MAX_SPEED`, conforme a
tabela do plano de implementação). Não há seção "DESEMPENHO" com cabeçalho
próprio, nem GUI customizada. Cada linha é só ícone + texto, formatada por
`app/RowFormatter.lua` (Fase 4) a partir da `PerformanceData` calculada pelo
`core/`.

## Consequências
- A integração usa só um ponto de extensão oficial do jogo (mesmo padrão que
  as linhas vanilla usam internamente), o que reduz o risco de quebra em
  patches futuros e evita reimplementar layout de GUI.
- As linhas deste mod ficam visualmente indistinguíveis das linhas nativas
  (mesmo ícone + texto), sem destaque de "seção de mod" — uma limitação
  aceita em troca de robustez.
- Outros mods que também usam `registerCustomSpecValues` (via `append`) se
  encadeiam sem conflito; a ordem final das linhas depende da ordem de carga
  dos mods, não é controlada por este mod (PRD §Dependencies&Risks).
- Se o jogo remover ou renomear `registerCustomSpecValues` num patch futuro,
  o `HookRegistry` (ADR-0003) detecta o alvo ausente, loga um warning e
  desativa só essa integração — a loja continua funcional sem as linhas do
  mod.
