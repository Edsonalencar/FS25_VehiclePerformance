# ADR-0004: Veículo de preview em runtime como fonte primária de dados

## Status
Aceito

## Contexto
Os requisitos §4 descrevem, na origem, um parser XML dos veículos (motor,
transmissão, diferenciais, rodas). Na pesquisa (PRD §Data Flow), verificou-se
que `ShopConfigScreen` já monta um **veículo real de preview** a cada troca de
configuração, com `setForceServer(true)` (`loadCurrentConfiguration`,
`ShopConfigScreen.lua:877`). Isso significa que, no momento em que o jogo
chama o hook `registerCustomSpecValues` (`:759`), o preview já tem
`spec_motorized.motor` (curva de torque, marchas, grupos, `peakMotorPower`),
`spec_motorized.differentials`, `spec_wheels.wheels[i].physics` e
`getTotalMass(true)` — tudo já resolvido pelo próprio motor do jogo,
incluindo merges de arquivo externo de rodas, fallback de motor/transmissão
para `config(0)`, `objectChange` de massa e seleção de diferencial pela
configuração de rodas. Escrever um parser XML próprio que reproduzisse tudo
isso seria redundante e arriscado (literais corrompidos no dataS decompilado,
XMLs de terceiros malformados — caso do Valtra BH180, PRD §Fixtures).

## Decisão
A fonte primária de dados em jogo é o veículo de preview lido em runtime
(`adapters/RuntimeVehicleReader.lua`, Fase 2/3), no momento exato em que
`registerCustomSpecValues` é chamado. Não existe parser XML de veículo
próprio no caminho principal. O comando de console `vpDump` (Fase 3) grava
esse mesmo `Snapshot`, já resolvido pelo jogo, como XML — e esses dumps viram
os fixtures golden dos testes offline (`tests/golden/`), não o inverso.

## Consequências
- A maior parte da complexidade de merge (motor/transmissão com fallback,
  massa com `objectChange`, diferencial por configuração de rodas, rodas com
  arquivo externo) fica delegada ao próprio jogo, e não precisa ser
  reimplementada nem mantida em sincronia com patches futuros.
- O núcleo de análise (`core/`) nunca vê XML: recebe sempre o mesmo formato
  de `Snapshot`, seja ele produzido a partir do preview em jogo ou carregado
  de um dump de fixture nos testes — por isso o roundtrip
  `Flatten`/`SnapshotXmlWriter` precisa ser exatamente inverso (Fase 2/3).
- A lista da loja (`ShopController:makeDisplayItem`) não tem preview, então
  este mod **não** exibe linhas ali (decisão já registrada em "O que não
  estamos fazendo", requisitos e plano) — só na tela de configuração.
- Sem o jogo rodando neste ambiente de desenvolvimento, não há dumps reais
  disponíveis; os testes desta fase e das anteriores usam só os fixtures
  manuais (`docs/FORMULAS.md`). Isso fica registrado como pendência real em
  `docs/release-checklist.md` e `CHANGELOG.md`.
