# Fórmulas — FS25 Vehicle Performance

Este documento é a fonte de referência (leitura humana) das métricas calculadas
pelo mod. A fonte de verdade formal é
`specs/plans/2026-09-27-fs25-vehicle-performance-1.0.md` (§Fórmulas); esta
cópia existe para consulta sem precisar abrir o plano inteiro, e deve ser
mantida em sincronia com ele.

Todas as entradas vêm do `Snapshot` (Fase 2, `src/core/`). Toda métrica tem
`status="ok"` ou `status="unknown"`, com `reason` quando `unknown` — nenhuma
métrica lança erro; uma métrica sem dados aparece como "desconhecido" na loja,
ou é omitida (regra do `RowFormatter`, Fase 4).

## Unidades internas (SI)

- massa em **t** (toneladas, como o próprio jogo usa);
- força em **kN**;
- torque em **kN·m** (o jogo aplica `torque × torqueScale`);
- potência em **kW** (`peakMotorPower`), convertida para cv só na exibição;
- velocidade em **m/s** no core, convertida para km/h só no `RowFormatter`;
- relação de transmissão em **rad/m** (a relação do jogo mapeia rad/s do
  motor para m/s do veículo:
  `VehicleMotor.calculatePhysicalMaximumSpeed = maxRpm·π/(30·ratio)`), portanto
  `F[kN] = T[kN·m] · R`.
- constantes em `core/util/Units.lua`: `G = 9.81`, `KW_PER_CV = 0.73549875`,
  `RPM_TO_RADS = π/30`.

## Tabela de fórmulas (F1–F12)

| Id | Métrica | Tipo | Definição | `unknown` quando |
|---|---|---|---|---|
| F1 | `powerDeclaredCv` | declared | `snapshot.declared.powerHp` (vem de `motorConfiguration#hp` ou de `storeData.specs.power`, a mesma regra de `processStoreItemPowerOutput`, `ShopConfigScreen.lua:350`) | ausente |
| F2 | `peakPowerKw`, `peakPowerCv` | calculated | `motor.peakPowerKw` lido do jogo. Se ausente, recalcular pela curva com o mesmo algoritmo do `VehicleMotor.new` (`:169-201`): em cada segmento linear da curva, o ótimo é `rpm* = clamp((r2·T1 − r1·T2)/(2(T1−T2)), r1, r2)` e `P = T(rpm*)·rpm*·π/30`. Converte-se para cv com `/KW_PER_CV`. | sem curva e sem peak |
| F3 | `peakTorqueKnm` | calculated | `motor.peakTorque`, ou o máximo da curva | sem curva |
| F4 | `torqueReservePct` | calculated | `100·(T_pico − T(maxRpm))/T(maxRpm)`, onde `T(maxRpm)` é o torque do último ponto da curva | `T(maxRpm) ≤ 0` |
| F5 | `massT`, `powerToWeightKgPerCv` | calculated | `massT = snapshot.mass.totalT` (`getTotalMass(true)` após `updateMass()`, que já inclui rodas, rodas duplas, lastros e objectChange). `kg/cv = massT·1000 / peakPowerCv`. | massa ≤ 0 ou potência desconhecida |
| F6 | `drivetrain` (`label`, `drivenWheels`, `drivenAxles`) | calculated | Rodas motrizes = união dos índices de roda referenciados diretamente por qualquer diferencial (`diffIndexNIsWheel=true`; índice 1-based). `label = "<#wheels>x<#driven>"`. `drivenAxles` = nº de diferenciais com os dois lados roda + nº de rodas motrizes referenciadas por diferenciais cujo outro lado é diferencial. | sem diferenciais, índice fora do intervalo `1..#wheels`, `diffIndex` de diferencial fora de `0..#diffs-1`, ou nenhuma roda motriz |
| F7 | `maxRatio` | calculated | CVT (`motor.maxForwardGearRatio ~= nil`): `maxForwardGearRatio`. Com marchas: `max(forwardGears[i].ratio) × max(gearGroups[j].ratio or 1)`. O jogo já guarda o grupo como `1/xmlRatio` (`Motorized.lua:1419`) e as marchas já multiplicadas por `axleRatio`. | sem ratios |
| F8 | `motorForceKn` | calculated | `F_mot = peakTorqueKnm · maxRatio` | F3 ou F7 unknown |
| F9 | `adhesionForceKn` | estimated | `F_ad = G · Σ_{i∈motrizes} μ_i · m_i`, com `m_i = massT · restLoad_i / Σ_all restLoad` (distribuição estática declarada pelo autor do veículo) e `μ_i = fieldFriction_i · frictionScale_i`. `fieldFriction` = `WheelsUtil.getTireFriction(tireType, GROUND_FIELD, 0, 0)` lido pelo adapter; o jogo aplica `frictionScale × coef` em `setWheelShapeTireFriction`. **Referência: campo seco.** | F6 unknown, `Σ restLoad ≤ 0` ou μ ausente numa roda motriz |
| F10 | `tractionForceKn` + `tractionLimit` | estimated | `min(F_mot, F_ad)`. `tractionLimit = "adhesion"` se `F_ad < F_mot`, senão `"motor"`. | F8 e F9 ambos unknown. Com só um deles disponível, usa esse valor e `tractionLimit="partial"`. |
| F11 | `loadSpeedKmh` | estimated | Carga de referência `F_load = k·massT·G`, com `k = metrics#loadRefWeightFraction` (padrão 0.5, "puxar 50% do próprio peso"). Se `F10 ≥ F_load`: `v = min(P_kW / F_load, maxForwardSpeed)·3.6`. Senão `status="insufficient"` (a linha mostra "tração insuficiente"). | F2 ou F5 unknown |
| F12 | `pullingIndex` (0–100) | heuristic | `100 · F10 / (F10 + F_ref)`, com `F_ref = metrics#pullingRefKN` (padrão 50 kN; ver §Calibração abaixo). Justificativa: é monotônico em F10, satura sem corte (não há teto artificial) e vale 50 exatamente em `F_ref`. **Desligado por padrão** (`ui#showPullingIndex=false`). | F10 unknown |

### Por que F11 usa carga fixa

A versão `P/(0,5·F_tração)` foi rejeitada: premiava o 4x2 em relação ao 4x4
(11,3 contra 7,2 km/h nos fixtures manuais). Isso violava a validação relativa
de requisitos §7.4, que exige que um veículo estritamente mais capaz de
tração (mesma motorização, mais rodas motrizes) nunca fique em desvantagem
numa métrica derivada. Por isso F11 usa uma carga de referência fixa
(`F_load = k·massT·G`) em vez de uma fração da própria força de tração
estimada do veículo.

## Valores esperados nos fixtures manuais da Fase 2

Calculados em Python com o mesmo algoritmo das fórmulas acima; tolerância
relativa `1e-3`. Esses são os valores **manuais** (calculados fora do jogo, a
partir dos XMLs dos veículos), usados como golden inicial antes de existirem
dumps reais em jogo.

| Fixture | P kW / cv | T kN·m | reserva % | kg/cv | R_max | F_mot | F_ad | F_tração (limite) | v carga km/h | índice |
|---|---|---|---|---|---|---|---|---|---|---|
| `ford_auto_largo` | 148.20 / 201.5 | 0.850 | 38.9 | 25.12 | 250.00 | 212.50 | 75.48 | 75.48 (adhesion) | 21.49 | 60.2 |
| `ford_manual_dual_ballast` | 188.22 / 255.9 | 0.950 | 38.9 | 37.11 | 188.50 | 179.07 | 141.61 | 141.61 (adhesion) | 14.55 | 73.9 |
| `valtra_145_michelin` | 104.79 / 142.5 | 0.601 | 38.9 | 71.64 | 174.54 | 104.90 | 152.20 | 104.90 (motor) | 7.54 | 67.7 |
| `valtra_205_michelin` | 160.41 / 218.1 | 0.920 | 38.9 | 46.80 | 174.54 | 160.58 | 152.20 | 152.20 (adhesion) | 11.53 | 75.3 |
| `valtra_145_4x2` (sintético) | 104.79 / 142.5 | 0.601 | 38.9 | 71.64 | 174.54 | 104.90 | 66.97 | 66.97 (adhesion) | 7.54 | 57.3 |
| `volvo_6x2_ferro` | 311.92 / 424.1 | 1.789 | 42.9 | 31.39 | 150.00 | 268.35 | 172.69 | 172.69 (adhesion) | 17.20 | 77.5 |
| `volvo_6x4_alcoa` | 311.92 / 424.1 | 1.789 | 42.9 | 31.39 | 150.00 | 268.35 | 345.38 | 268.35 (motor) | 17.20 | 84.3 |

### Invariantes relativos

Testados nos fixtures manuais acima e, quando existirem, nos dumps reais:

- `valtra_205 > valtra_145` em P, F_tração e índice;
- `volvo_6x4 > volvo_6x2` em F_tração;
- `valtra_145 (4x4) > valtra_145_4x2` em F_tração;
- `ford_manual_dual_ballast > ford_auto_largo` em massT e F_ad.

## Calibração de `F_ref` em jogo

**PENDENTE.** `F_ref` (`metrics#pullingRefKN`, F12) deveria ser calibrado como
a mediana de `tractionForceKn` (F10) sobre uma amostra representativa de
veículos reais, coletada via `vpDump` em jogo (ver `docs/api-findings/`). Este
ambiente de desenvolvimento não tem o FS25 instalado, então não há dumps
reais disponíveis, e essa calibração não foi feita.

O valor atual em produção é o default original do spec,
`metrics#pullingRefKN = 50` (kN) — **não recalibrado**. Ele produz os índices
da tabela de fixtures manuais acima (calculados sobre XMLs, não sobre dumps do
jogo rodando) e deve ser revisto assim que dumps reais existirem, seguindo o
mesmo processo: coletar `tractionForceKn` de uma amostra ampla de veículos
(tratores 2WD/4WD, caminhões 4x2/6x2/6x4, etc.), calcular a mediana, e
atualizar o default em `src/adapters/SettingsStore.lua`. Isso é rastreado em
`docs/release-checklist.md`.
