---
date: 2026-09-27T23:55:00-03:00
author: claude
source_prd: specs/research/2026-09-27-fs25-vehicle-performance.md
git_commit: n/a (git init na Fase 1)
branch: n/a
status: implemented (verificação em jogo pendente)
tags: [spec, fs25, shop, ShopConfigScreen, Motorized, VehicleMotor, Wheels, differentials, metrics]
---

# Spec: FS25 Vehicle Performance 1.0

## Overview
O mod `FS25_VehiclePerformance` é só de script e roda só no PC. Ele acrescenta linhas de desempenho à **tela de configuração da loja** (`ShopConfigScreen`) usando o ponto de extensão vazio do jogo, `ShopConfigScreen:registerCustomSpecValues`. Esse método é chamado ao final de `processAttributeData`, logo depois de o jogo carregar o **veículo de amostra** (preview) da configuração selecionada. O preview é montado com `setForceServer(true)`, então já contém `spec_motorized.motor`, `spec_motorized.differentials`, `spec_wheels.wheels[i].physics` e `getTotalMass(true)` resolvidos pelo próprio jogo (PRD §Data Flow).

A arquitetura hexagonal é a mesma do SmartShopSearch (SSS). Os módulos têm três camadas:
- **`adapters/`**: é a única camada que toca o FS25. O `RuntimeVehicleReader` converte o preview num `Snapshot`, uma tabela Lua pura e serializável.
- **`core/`**: Lua 5.1 puro. Transforma o `Snapshot` em `PerformanceData`, onde cada métrica é marcada como `declared`, `calculated`, `estimated` ou `heuristic`, com estado de disponibilidade.
- **`app/`**: formata as linhas com uma porta de texto injetada e guarda cache por `xmlFilename + configurações`.

O comando `vpDump` grava snapshots reais em XML, e eles viram os fixtures golden dos testes offline.

Decisões fechadas com o usuário (sessão de 27/09/2026):
1. **Additional Vehicle Info**: só coexistência e detecção.
2. **Exibição**: linhas ícone + texto via `registerCustomSpecValues`.
3. **Fonte de dados**: preview em runtime + dump para fixtures.
4. **Índices**: fórmulas definidas neste spec (§Fórmulas). O índice heurístico fica desligado por padrão.

Padrões aceitos:
- licença MIT;
- global único `VehiclePerformance`;
- prefixo l10n `vp_`;
- `descVersion="111"`;
- idiomas `en` e `br`;
- sem specialization própria;
- fixtures de terceiros mantidos como estão.

## Current State
- O diretório contém só `requisitos.md`, `.claude/skills/` e o PRD. Não há git.
- Padrões de referência (código próprio, MIT) em `/home/alencar/WorkSpace/FS25/SmartShopSearch`:
  - `src/main.lua:1-20`, `src/manifest.lua`;
  - `src/adapters/{HookRegistry,GameLogger,SettingsStore,GameBootstrap}.lua`, `src/app/{SafeCall,StateMachine}.lua`;
  - `Makefile`, `.luacheckrc`, `.stylua.toml`, `.luarc.json`;
  - `tools/{build.py,check_deps.py,setup_dev.sh,make_icon.sh,fs25_globals.lua}`, `tests/support/{load.lua,xml.lua}`.
- API do jogo verificada em dataS 1.21.1.0 (`maxkra1985/FarmingSimulator25_dataS@754ef8a`):
  - `ShopConfigScreen.lua:456,759,773,907`;
  - `ShopConfigScreen.GUI_PROFILE` (`:2539`);
  - `VehicleMotor.lua:31-201`;
  - `Motorized.lua:1156-1203,1338,1405-1425`;
  - `WheelPhysics.lua:79-158`, `Wheel.lua:331`;
  - `WheelsUtil.lua:3-6,57-68,70-185,397-403`;
  - `I18N.lua:284-300,414-419`;
  - `XMLFile.lua:25`.

## Desired End State
- `make ci` (fmt-check, lint, deps, test, verify) passa. `make build` gera `dist/FS25_VehiclePerformance-1.0.0.zip` e `SHA256SUMS`.
- No jogo, na tela de configuração de qualquer veículo motorizado, aparecem até 6 linhas extras:

  | Ícone (`ShopConfigScreen.GUI_PROFILE`) | Texto (br) | Tipo |
  |---|---|---|
  | `WHEELS` | `Tração 4x4 · 2 eixos motrizes` | calculado |
  | `POWER` | `Pico calc.: 201 cv / 148 kW · 850 N·m (+39%)` (`formatNumber` com precisão 0 trunca) | calculado |
  | `WEIGHT` | `25,1 kg/cv` | calculado |
  | `TRANSMISSION` | `Força de tração ~75 kN (aderência)` | estimado |
  | `MAX_SPEED` | `Sob carga (50% do peso) ~21 km/h` | estimado |
  | `POWER` | `Índice de puxada 60 (heurístico)` | heurístico (só com `ui#showPullingIndex=true`) |

  Uma métrica sem dados mostra `desconhecido` ou é omitida (regra em `RowFormatter`). Nunca causa erro.
- As linhas se atualizam a cada troca de veículo ou de configuração, sem trabalho por frame.
- O mod funciona com e sem `FS25_additionalVehicleInfo`. Com ele, `vpStatus` mostra `avi=present`.
- Uma falha de hook ou de leitura degrada o mod sem quebrar a loja. Em dedicated server o mod fica em `disabled-dedicated`.
- API pública disponível em `VehiclePerformance.api.{getPerformance,getMetric,getCurrentConfiguration}`.
- `docs/FORMULAS.md` documenta cada métrica: variáveis, unidades, justificativas e valores de referência dos dumps.

## What We're NOT Doing
- **Linhas na listagem da loja (`addSpecType`).** A listagem não tem preview e exigiria um parser XML.
- **Parser XML próprio dos veículos.** Os fixtures vêm de dumps runtime.
- **Seção de GUI própria com cabeçalho.** Usamos só `registerCustomSpecValues`, que é mais robusto.
- **HUD in-world, specialization própria e eventos de rede.** O mod é só cliente e não tem dados de mundo.
- **Integração ativa com o AVI** (hooks, esconder linhas). O AVI não toca a loja.
- **Interoperar com o Smart Shop Search.** Fica para o futuro, via a API pública.
- **Alterar física, preço ou configuração.** O mod só lê.
- **Idiomas além de en e br**, e **CI remoto / TestRunner** (não há remote git). O TestRunner fica no checklist manual de release.
- **Atrito em estrada, molhado ou neve.** A referência é campo seco (§Fórmulas F6).
- **Rastreabilidade automatizada (`check_trace.py`).** `requisitos.md` não tem IDs; a rastreabilidade é uma tabela manual na Fase 5.

## Convenções gerais (valem para todas as fases)
- Lua 5.1, 4 espaços, 120 colunas, aspas duplas (`.stylua.toml` do SSS).
- Módulos seguem o padrão `local NS = VehiclePerformance; local X = {}; ...; NS.<camada>.X = X`. Classes usam `X.__index = X` e `setmetatable`.
- Pureza das camadas, verificada por `tools/check_deps.py`:
  - `core/` não usa `g_*`, `Utils.`, `XMLFile`, `print`, `os.` nem `io.`;
  - `app/` não usa `g_*`, `XMLFile` nem `adapters`;
  - nenhum arquivo de `src/` usa `require`, `dofile`, `load(`, `io.` ou URLs.
- Todo acesso à API do jogo tem guarda `type(x)=="function"/"table"` e pcall por campo. Nada é gravado em objetos do jogo; estado de UI fica em tabela de chave fraca.
- Comentários e documentação em PT-BR, identificadores em inglês.
- Commits ao fim de cada fase via skill `commit` (PT-BR `tipo(escopo): ...`).
- Unidades internas SI:
  - massa em **t** (do jogo) e força em **kN**;
  - torque em **kN·m** (o jogo usa `torque × torqueScale`);
  - potência em **kW** (`peakMotorPower`) e velocidade em **m/s** no core, convertida só no `RowFormatter`;
  - relação de transmissão em **rad/m** (a relação do FS mapeia rad/s do motor → m/s do veículo; `VehicleMotor.calculatePhysicalMaximumSpeed = maxRpm·π/(30·ratio)`), portanto `F[kN] = T[kN·m]·R`.
- Constantes em `core/util/Units.lua`: `G = 9.81`, `KW_PER_CV = 0.73549875`, `RPM_TO_RADS = π/30`.

---

## Fórmulas (fonte de verdade; copiadas para `docs/FORMULAS.md` na Fase 5)

Entradas vêm do `Snapshot` (§Fase 2). Toda métrica tem `status="ok"` ou `"unknown"`, com `reason` quando `unknown`.

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
| F12 | `pullingIndex` (0–100) | heuristic | `100 · F10 / (F10 + F_ref)`, com `F_ref = metrics#pullingRefKN` (padrão 50 kN; recalibrado na Fase 3). Justificativa: é monotônico em F10, satura sem corte (não há teto artificial) e vale 50 exatamente em `F_ref`. **Desligado por padrão** (`ui#showPullingIndex=false`). | F10 unknown |

**Por que F11 usa carga fixa.** A versão `P/(0,5·F_tração)` foi rejeitada: premiava o 4x2 em relação ao 4x4 (11,3 contra 7,2 km/h nos fixtures). Isso violava a validação relativa de requisitos §7.4.

**Valores esperados nos fixtures manuais da Fase 2** (calculados em Python com o mesmo algoritmo; tolerância relativa `1e-3`):

| Fixture | P kW / cv | T kN·m | reserva % | kg/cv | R_max | F_mot | F_ad | F_tração (limite) | v carga km/h | índice |
|---|---|---|---|---|---|---|---|---|---|---|
| `ford_auto_largo` | 148.20 / 201.5 | 0.850 | 38.9 | 25.12 | 250.00 | 212.50 | 75.48 | 75.48 (adhesion) | 21.49 | 60.2 |
| `ford_manual_dual_ballast` | 188.22 / 255.9 | 0.950 | 38.9 | 37.11 | 188.50 | 179.07 | 141.61 | 141.61 (adhesion) | 14.55 | 73.9 |
| `valtra_145_michelin` | 104.79 / 142.5 | 0.601 | 38.9 | 71.64 | 174.54 | 104.90 | 152.20 | 104.90 (motor) | 7.54 | 67.7 |
| `valtra_205_michelin` | 160.41 / 218.1 | 0.920 | 38.9 | 46.80 | 174.54 | 160.58 | 152.20 | 152.20 (adhesion) | 11.53 | 75.3 |
| `valtra_145_4x2` (sintético) | 104.79 / 142.5 | 0.601 | 38.9 | 71.64 | 174.54 | 104.90 | 66.97 | 66.97 (adhesion) | 7.54 | 57.3 |
| `volvo_6x2_ferro` | 311.92 / 424.1 | 1.789 | 42.9 | 31.39 | 150.00 | 268.35 | 172.69 | 172.69 (adhesion) | 17.20 | 77.5 |
| `volvo_6x4_alcoa` | 311.92 / 424.1 | 1.789 | 42.9 | 31.39 | 150.00 | 268.35 | 345.38 | 268.35 (motor) | 17.20 | 84.3 |

Invariantes relativos, testados nos fixtures manuais e depois nos dumps reais:
- `valtra_205 > valtra_145` em P, F_tração e índice;
- `volvo_6x4 > volvo_6x2` em F_tração;
- `valtra_145 (4x4) > valtra_145_4x2` em F_tração;
- `ford_manual_dual_ballast > ford_auto_largo` em massT e F_ad.

---

## Phase 1: Estrutura, ferramentas e bootstrap

### Goal
Criar o repositório com a toolchain do SSS e um mod que carrega no jogo, registra logger, estado e settings, e não faz mais nada.

### Changes

**Run**:
- `git init` na raiz.
- Criar `.gitignore` com `.lua/`, `dist/`, `*.zip`, `__pycache__/`.

**Create** (copiados do SSS e adaptados, trocando `SmartShopSearch`→`VehiclePerformance`, `sss_`→`vp_`, `FS25_SmartShopSearch`→`FS25_VehiclePerformance`):
- `Makefile`: igual a `SmartShopSearch/Makefile:1-21`, **sem** `trace`, `prop` e `bench`. Os alvos são `setup fmt fmt-check lint deps test unit golden build verify ci`, com `test: unit golden` e `ci: fmt-check lint deps test verify`.
- `.luacheckrc`, `.stylua.toml`, `.editorconfig`, `.luarc.json`: iguais, com `globals = { "VehiclePerformance" }`.
- `tools/setup_dev.sh`: igual.
- `tools/check_deps.py`: igual (`CORE_FORBIDDEN`, `APP_FORBIDDEN`, `ALL_FORBIDDEN`).
- `tools/fs25_globals.lua`, com a lista abaixo:
  ```lua
  return {
      "g_shopConfigScreen", "ShopConfigScreen", "g_i18n", "g_modIsLoaded", "g_modManager", "g_brandManager",
      "g_storeManager", "g_dedicatedServer", "g_currentModDirectory", "g_currentModName", "g_modSettingsDirectory",
      "WheelsUtil", "Utils", "XMLFile", "Logging", "addModEventListener", "addConsoleCommand",
      "removeConsoleCommand", "source", "getTimeSec", "createFolder", "getfenv",
  }
  ```
- `tools/build.py`: igual a `SmartShopSearch/tools/build.py`, com estas mudanças:
  - `MOD_NAME = "FS25_VehiclePerformance"`, `KEY_RE = re.compile(r"\bvp_[a-z0-9_]+\b")`;
  - em `validate_moddesc`, **remover** a validação de `<actions>`/`<inputBinding>` (o mod não tem input);
  - remover a chamada a `check_trace.py` em `--release`.
- `tools/make_icon.sh`: igual, com `SRC_PNG="art/icon.png"` e `OUT_DDS="src/icon_VehiclePerformance.dds"`. Se `art/icon.png` não existir, gerar um placeholder:
  ```bash
  [ -f "$SRC_PNG" ] || convert -size 512x512 xc:'#1f4e5f' -gravity center -fill white -pointsize 220 -annotate 0 'VP' "$SRC_PNG"
  ```
- `tests/support/load.lua`: igual a `SmartShopSearch/tests/support/load.lua:1-19`, com `VehiclePerformance = { MOD_DIR="src/", VERSION="test", core={}, app={}, adapters={}, api={} }`.
- `tests/support/xml.lua`: cópia literal de `SmartShopSearch/tests/support/xml.lua`.
- `tests/stubs/MemoryLogger.lua`: cópia do SSS.
- `LICENSE` (MIT, "Copyright (c) 2026 FS25 Mods Editor"), `LICENSE-ART.md` (todos os direitos reservados), `README.md` (curto, PT-BR).
- `CHANGELOG.md` com `## 1.0.0 — não lançado` e `### Adicionado`.

**Create**: `src/modDesc.xml`
```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc descVersion="111">
    <author>FS25 Mods Editor</author>
    <version>1.0.0.0</version>
    <title>
        <en>Vehicle Performance</en>
        <br>Desempenho de Veículos</br>
    </title>
    <description>
        <en><![CDATA[Adds performance data to the shop configuration screen: drivetrain, calculated peak power and torque, power-to-weight, estimated traction force and speed under load. Reads the game's own vehicle data; changes nothing.]]></en>
        <br><![CDATA[Adiciona dados de desempenho à tela de configuração da loja: tração, potência e torque de pico calculados, relação peso/potência, força de tração estimada e velocidade sob carga. Lê os dados do próprio jogo; não altera nada.]]></br>
    </description>
    <iconFilename>icon_VehiclePerformance.dds</iconFilename>
    <multiplayer supported="true"/>
    <l10n filenamePrefix="translations/translation"/>
    <extraSourceFiles>
        <sourceFile filename="main.lua"/>
    </extraSourceFiles>
</modDesc>
```

**Create**: `src/main.lua` (espelha `SmartShopSearch/src/main.lua:1-20`)
```lua
-- FS25_VehiclePerformance — ponto de entrada único (extraSourceFiles)
local MOD_DIR = g_currentModDirectory
local MOD_NAME = g_currentModName

VehiclePerformance = {
    MOD_DIR = MOD_DIR,
    MOD_NAME = MOD_NAME,
    VERSION = "1.0.0",
    core = {},
    app = {},
    adapters = {},
    api = {},
}

source(MOD_DIR .. "manifest.lua")
for _, rel in ipairs(VehiclePerformance.manifest) do
    source(MOD_DIR .. rel)
end

VehiclePerformance.adapters.GameBootstrap.install(VehiclePerformance)
```

**Create**: `src/manifest.lua`. Nesta fase lista só os módulos abaixo; cada fase acrescenta os seus, em ordem de dependência.
```lua
-- Ordem de carga fixa. Lida por main.lua, tests/support/load.lua e tools/build.py.
VehiclePerformance.manifest = {
    "app/SafeCall.lua",
    "app/StateMachine.lua",
    "adapters/GameLogger.lua",
    "adapters/HookRegistry.lua",
    "adapters/SettingsStore.lua",
    "adapters/GameBootstrap.lua",
}
```

**Create** (portados literalmente do SSS, trocando o namespace e o prefixo de log `[VehiclePerformance]`):
- `src/app/SafeCall.lua` ← `SmartShopSearch/src/app/SafeCall.lua:1-23`
- `src/app/StateMachine.lua` ← `SmartShopSearch/src/app/StateMachine.lua:1-46`. Em `ALLOWED`, **remover o estado `indexed`**:
  ```lua
  local ALLOWED = {
      loaded = { ready = true, ["disabled-dedicated"] = true, degraded = true, unloaded = true },
      ready = { degraded = true, unloaded = true },
      degraded = { unloaded = true },
      ["disabled-dedicated"] = { unloaded = true },
  }
  ```
- `src/adapters/GameLogger.lua` ← `SmartShopSearch/src/adapters/GameLogger.lua:1-94` (`PREFIX = "[VehiclePerformance]"`)
- `src/adapters/HookRegistry.lua` ← `SmartShopSearch/src/adapters/HookRegistry.lua:1-77`
- `src/adapters/SettingsStore.lua` ← `SmartShopSearch/src/adapters/SettingsStore.lua:1-107`, com estes valores:
  ```lua
  local DEFAULTS = {
      ["debug#enabled"] = false,
      ["debug#logLevel"] = "info",
      ["debug#simulateFailure"] = "", -- "reader" | "hook" (só com debug#enabled)
      ["ui#enabled"] = true,
      ["ui#showPullingIndex"] = false,
      ["metrics#pullingRefKN"] = 50,
      ["metrics#loadRefWeightFraction"] = 0.5,
  }
  local FILE_KEY = "VehiclePerformanceSettings"
  -- relPath(): (g_modSettingsDirectory or "") .. "FS25_VehiclePerformance/settings.xml"
  ```

**Create**: `src/adapters/GameBootstrap.lua`. É o `SmartShopSearch/src/adapters/GameBootstrap.lua` reduzido: mantém `ConsoleRegistrar` (`:8-29`), `listener:loadMap`, `listener:deleteMap` e `install`. Nesta fase o `loadMap` é:
```lua
function listener:loadMap() -- luacheck: ignore 212/self
    NS.app.SafeCall.run("bootstrap:loadMap", function()
        if g_dedicatedServer ~= nil then
            NS.app.state:set("disabled-dedicated")
            return
        end
        NS.app.settings:loadSettings()
        NS.app.logger:setLevel(NS.app.settings:get("debug#logLevel"))
        -- Fase 4: shopConfigAdapter:install(); Fase 3/5: Console.install(...)
        NS.app.state:set("ready")
        NS.app.logger:info("bootstrap", "v%s carregado", NS.VERSION)
    end)
end
```
`install(namespace)` cria `settings`, `logger` e `state`, e chama `addModEventListener(listener)`.

**Create**: `src/translations/translation_en.xml` e `translation_br.xml` no formato `<l10N><texts>…</texts></l10N>`, com `vp_mod_title` ("Vehicle Performance" / "Desempenho de Veículos").

**Create**: `src/icon_VehiclePerformance.dds` via `./tools/make_icon.sh`.

**Create**: `tests/unit/bootstrap_spec.lua`. Carrega com `load({adapters=true})` e stubs de `addModEventListener` e `XMLFile`, e verifica:
- `install` registra o listener;
- `loadMap` com `g_dedicatedServer = {}` leva a `disabled-dedicated`;
- sem ele leva a `ready`;
- `SafeCall` degrada após 3 falhas;
- `HookRegistry.add` é idempotente e se desativa após 3 erros.

**Create**: `tools/dev_link.sh` (cópia do SSS com o nome trocado) para criar o symlink de `src/` na pasta de mods.

### Success Criteria

#### Automated Verification
- [x] `make setup` instala `.lua/` com busted e luacheck. (adaptado: toolchain reaproveitada de `SmartShopSearch/.lua`, mesma versão Lua 5.1/busted/luacheck, em vez de rebaixar hererocks sem rede neste ambiente)
- [x] `make fmt-check lint deps`: sem erros.
- [x] `make unit`: `bootstrap_spec` passa.
- [x] `make verify`: modDesc, manifest e l10n válidos, e o ZIP reaberto tem hashes idênticos.

#### Manual Verification
- [ ] Com o mod ativo num savegame, o `log.txt` mostra `[VehiclePerformance] info: v1.0.0 carregado` e nenhum erro Lua ou XML.
- [ ] A loja abre e funciona normalmente, sem nenhuma linha nova.

**⏸ PAUSE**: confirmação humana dos testes manuais antes da Fase 2.

---

## Phase 2: Núcleo offline (Snapshot → PerformanceData)

### Goal
Implementar todas as fórmulas F1–F12 em `core/`, testadas contra fixtures montados à mão a partir do inventário XML (PRD §Fixtures).

### Changes

**Create**: `src/core/util/Units.lua`: `G`, `KW_PER_CV`, `RPM_TO_RADS`, `isNum(x)` (número finito), `clamp`.

**Create**: `src/core/util/Flatten.lua`. Faz `flatten(tbl) -> {{k="motor.maxRpm", t="n", v=2200}, ...}`, com chaves ordenadas, arrays como `wheels.1.radius`, tipos `n`, `s` e `b`. Faz também `unflatten(list) -> tbl`, que reconstrói números inteiros de chave como índices de array. É usado pelo writer de dump (Fase 3) e pelo loader de testes.

**Create**: `src/core/util/Hash.lua`: `djb2(str) -> string hex de 8 chars`, usado no nome do arquivo de dump.

**Create**: `src/core/model/Snapshot.lua`. Define o schema e faz a validação. É o **contrato** entre adapter e core.
```lua
-- Snapshot schema 1 (todas as grandezas SI do jogo; campos ausentes = nil)
-- {
--   schema = 1,
--   identity = { xmlFilename, name, brand, category, typeName },
--   configuration = { [configName] = index },            -- vehicle.configurations
--   declared = { powerHp, maxSpeedKmh, price },
--   mass = { totalT, defaultT },
--   motor = { minRpm, maxRpm, peakTorque, peakPowerKw, maxForwardSpeedMs,
--             torqueCurve = { {rpm=, torque=}, ... },       -- ordenado por rpm
--             forwardGears = { ratio, ... } | nil, gearGroups = { ratio, ... } | nil,
--             minForwardGearRatio, maxForwardGearRatio } | nil,
--   differentials = { {torqueRatio, maxSpeedRatio, diffIndex1, diffIndex1IsWheel, diffIndex2, diffIndex2IsWheel}, ... },
--   wheels = { {radius, width, shapeWidth, massT, restLoad, frictionScale, fieldFriction, tireTypeName,
--               isLeft, additionalCount}, ... },
-- }
function Snapshot.validate(s) -- devolve (ok:boolean, missing:string[]) sem lançar erro
```
`validate` só lista campos ausentes (para log DEBUG e `availability`). Nunca lança erro. A tolerância a ausências fica nos analyzers.

**Create**: `src/core/model/PerformanceData.lua`
```lua
-- Value: { value=number|string|nil, unit=string, kind="declared"|"calculated"|"estimated"|"heuristic",
--          status="ok"|"unknown"|"insufficient"|"partial", reason=string|nil }
function PerformanceData.value(v, unit, kind) ... end            -- status ok
function PerformanceData.unknown(unit, kind, reason) ... end
function PerformanceData.new(snapshot)  -- { identity, configuration, metrics = {}, availability = {missing = {...}} }
function PerformanceData:set(id, value) self.metrics[id] = value end
function PerformanceData:get(id) return self.metrics[id] end
```

**Create**: os analyzers em `src/core/analyzers/`, cada um com uma função `analyze(snapshot, data, opts)` que preenche métricas:
- `MotorAnalyzer.lua`: F1, F2, F3, F4. Contém `peakPowerFromCurve(curve)`, que replica `VehicleMotor.lua:169-201`:
  ```lua
  function MotorAnalyzer.peakPowerFromCurve(curve)
      local best = 0
      for i = 2, #curve do
          local a, b = curve[i - 1], curve[i]
          local rpm, t = a.rpm, a.torque
          if math.abs(a.torque - b.torque) > 0.0001 then
              local opt = (b.rpm * a.torque - a.rpm * b.torque) / (2 * (a.torque - b.torque))
              rpm = math.min(math.max(opt, a.rpm), b.rpm)
              t = a.torque + (b.torque - a.torque) * (rpm - a.rpm) / (b.rpm - a.rpm)
          end
          if t * rpm > best then best = t * rpm end
      end
      return best * Units.RPM_TO_RADS -- kW (torque em kN·m)
  end
  ```
  A curva com 1 ponto usa `rpm·torque·π/30`, como em `:199-201`.
- `MassAnalyzer.lua`: F5 `massT`. O `powerToWeight` depende de F2 e fica no metric.
- `TransmissionAnalyzer.lua`: F7 `maxRatio`, mais `transmissionType = "cvt"|"gears"|"unknown"`, `gearCount`, `groupCount`.
- `DifferentialAnalyzer.lua`: F6. Valida os índices conforme a regra de F6 e devolve `{label, drivenWheels(set), drivenAxles}` ou unknown com `reason` (`"no_differentials"`, `"bad_wheel_index"`, `"bad_diff_index"`).
  ```lua
  for _, d in ipairs(diffs) do
      for side = 1, 2 do
          local idx, isWheel = d["diffIndex" .. side], d["diffIndex" .. side .. "IsWheel"]
          if isWheel then
              if idx < 1 or idx > #wheels then return unknown("bad_wheel_index") end
              driven[idx] = true
          elseif idx < 0 or idx > #diffs - 1 then return unknown("bad_diff_index") end
      end
      if d.diffIndex1IsWheel and d.diffIndex2IsWheel then axles = axles + 1
      elseif d.diffIndex1IsWheel or d.diffIndex2IsWheel then axles = axles + 1 end -- roda sem par (raro)
  end
  ```
- `WheelAnalyzer.lua`: `wheelCount`, `hasDuals` (`additionalCount > 0` em alguma roda), e `Σ restLoad`.
- `TractionAnalyzer.lua`: F9, usando o conjunto de motrizes do DifferentialAnalyzer.

**Create**: as métricas em `src/core/metrics/`:
- `PowerToWeightMetric.lua`: F5 kg/cv.
- `TractionMetric.lua`: F8 e F10.
- `LoadPerformanceMetric.lua`: F11. Recebe `opts.loadRefWeightFraction`.
- `PullingPerformanceMetric.lua`: F12. Recebe `opts.pullingRefKN`.

**Create**: `src/core/VehicleAnalyzer.lua`
```lua
--- @param snapshot table  Snapshot schema 1
--- @param opts {loadRefWeightFraction:number, pullingRefKN:number}
--- @return PerformanceData
function VehicleAnalyzer.analyze(snapshot, opts)
    local data = NS.core.PerformanceData.new(snapshot)
    local _, missing = NS.core.Snapshot.validate(snapshot)
    data.availability.missing = missing
    for _, step in ipairs(STEPS) do step.analyze(snapshot, data, opts) end -- Motor, Mass, Transmission, Differential,
    return data                                                        -- Wheel, Traction, depois os 4 metrics
end
```
A ordem de `STEPS` é fixa. Cada passo lê só métricas de passos anteriores.

**Modify**: `src/manifest.lua`. Inserir antes de `app/SafeCall.lua`:
```lua
    "core/util/Units.lua",
    "core/util/Flatten.lua",
    "core/util/Hash.lua",
    "core/model/Snapshot.lua",
    "core/model/PerformanceData.lua",
    "core/analyzers/MotorAnalyzer.lua",
    "core/analyzers/MassAnalyzer.lua",
    "core/analyzers/TransmissionAnalyzer.lua",
    "core/analyzers/DifferentialAnalyzer.lua",
    "core/analyzers/WheelAnalyzer.lua",
    "core/analyzers/TractionAnalyzer.lua",
    "core/metrics/PowerToWeightMetric.lua",
    "core/metrics/TractionMetric.lua",
    "core/metrics/LoadPerformanceMetric.lua",
    "core/metrics/PullingPerformanceMetric.lua",
    "core/VehicleAnalyzer.lua",
```

**Create**: `tests/fixtures/manual/*.lua`, um arquivo por fixture da tabela §Fórmulas. Cada arquivo `return { ... }` é um Snapshot com os valores abaixo, e o cabeçalho de cada arquivo registra a origem (arquivo e linha do XML):
- **Ford** (`7630.xml`):
  - curva: normRpm/torque `0.45/0.9, 0.5/0.97, 0.59/1, 0.72/1, 0.86/0.88, 1/0.72`, com `rpm = normRpm·maxRpm` e `torque = t·torqueScale`.
  - `ford_auto_largo`:
    - motor: `maxRpm=2200`, `torqueScale=0.85`, CVT `maxForwardGearRatio=250`, `maxForwardSpeedMs=40/3.6`;
    - `massT=5.062`;
    - 4 rodas com `restLoad` 2.8/2.8/2.7/2.7, `fieldFriction=0.95`, `frictionScale=1.6`;
    - diferenciais: `{1,2 rodas}`, `{3,4 rodas}`, `{diff 0, diff 1}`;
    - `declared.powerHp=200`.
  - `ford_manual_dual_ballast`:
    - motor: `maxRpm=2500`, `torqueScale=0.95`;
    - marchas: `forwardGears` ratios `2500π/(kmh/3.6·30)` para 10/20/30/40 km/h, `gearGroups` ratios `{1/0.5, 1/1.0}`;
    - `massT=9.497`;
    - traseiras com `restLoad=4.043` e `additionalCount=1`;
    - `declared.powerHp=250`.
- **Valtra** (`Valtra_BH180.xml:471-527`):
  - motor: curva igual à do Ford, `maxRpm=2200`;
  - marchas 14.1/15.2/17.2/20/33/40 km/h, grupos `1/{0.337,0.515,0.738,1}`;
  - `massT=10.207`;
  - rodas com `restLoad` 2.8/2.8/2.2/2.2, `fieldFriction=0.95`, `frictionScale=1.6`.
  - As variantes mudam o seguinte:

    | Fixture | `torqueScale` | `declared.powerHp` | diferenciais |
    |---|---|---|---|
    | `valtra_145_michelin` | 0.601 | 145 | os mesmos do Ford |
    | `valtra_205_michelin` | 0.92 | 205 | os mesmos do Ford |
    | `valtra_145_4x2` | 0.601 | 145 | só `{3,4 rodas}` |
- **Volvo** (`VolvoFH.xml:358-400`):
  - motor: curva `0.45/0.5, 0.5/0.6, 0.59/0.7, 0.72/1, 0.86/0.88, 1/0.7`, `torqueScale=1.789`, `maxRpm=2200`, CVT 150, `maxForwardSpeedMs=85/3.6`;
  - `massT=13.311`;
  - dianteiras: `restLoad=2.3`, `frictionScale=2.1`;
  - 4 traseiras: `restLoad=1.27`, `fieldFriction=0.9` (street), `frictionScale=5.6`;
  - `declared.powerHp=nil`.
  - As variantes mudam o seguinte:

    | Fixture | `fieldFriction` dianteiras | diferenciais |
    |---|---|---|
    | `volvo_6x2_ferro` | 1.0 (offRoad) | `{3,4 rodas}` |
    | `volvo_6x4_alcoa` | 0.9 (street) | `{5,6}`, `{3,4}`, `{diff 0, diff 1}` |
- **Degenerados**:
  - `no_motor` (`motor=nil`);
  - `bad_diff` (índice de roda 9 em veículo de 4 rodas);
  - `empty` (`{schema=1}`);
  - `single_point_curve`.

**Create**: `tests/fixtures/manual/expected.lua`. Tabela `id → {peakPowerKw, peakPowerCv, peakTorqueKnm, torqueReservePct, powerToWeightKgPerCv, maxRatio, motorForceKn, adhesionForceKn, tractionForceKn, tractionLimit, loadSpeedKmh, pullingIndex, drivetrain="4x4", drivenAxles=2}`, com os valores exatos da tabela §Fórmulas. Nos rótulos de tração: Volvo `6x2`/`6x4`, `valtra_145_4x2` `4x2`, os demais `4x4`.

**Create**: os testes em `tests/unit/`:
- `motor_spec.lua`:
  - `peakPowerFromCurve` na curva do Ford dá `148.20 ± 0.01` kW;
  - o segmento de torque constante usa o `rpm` inicial;
  - a curva de 1 ponto funciona;
  - F4 com `T(maxRpm)=0` dá `unknown`.
- `differential_spec.lua`:
  - 4x4 dá 2 eixos; 6x2 dá 1; 6x4 dá 2;
  - `bad_wheel_index`, `bad_diff_index` e `no_differentials` dão `unknown` com o `reason` correspondente.
- `transmission_spec.lua`: CVT, marchas × grupos, e ratios ausentes.
- `traction_spec.lua`:
  - o limite (`tractionLimit`) sai `adhesion` ou `motor` conforme o caso;
  - com só F8 ou só F9 disponível, `tractionLimit` fica `partial`;
  - `Σ restLoad = 0` dá `unknown`.
- `load_spec.lua`: o limite por `maxForwardSpeed` e `insufficient` quando `F10 < k·m·g`.
- `flatten_spec.lua`: `unflatten(flatten(snapshot))` é igual ao snapshot em todos os fixtures (roundtrip).
- `analyzer_spec.lua`:
  - para cada fixture, cada métrica de `expected.lua` confere com tolerância relativa `1e-3`;
  - os fixtures degenerados não lançam erro e devolvem métricas `unknown`.
- `relative_spec.lua`: os 4 invariantes relativos de §Fórmulas.

### Success Criteria

#### Automated Verification
- [x] `make deps`: `core/` limpo (sem `g_`, `Utils.`, `XMLFile`, `print`, `io`, `os`).
- [x] `make unit`: todos os specs passam, incluindo `analyzer_spec` com 7 fixtures e 4 degenerados.
- [x] `make lint fmt-check verify`: passam.

#### Manual Verification
- [ ] Revisar `expected.lua` contra a tabela §Fórmulas. Nenhum número deve ter sido alterado para "fazer o teste passar".

**⏸ PAUSE**: confirmação humana antes da Fase 3.

---

## Phase 3: Leitor em runtime, dump e fixtures reais (exige o jogo)

### Goal
Converter o preview real em Snapshot, gravar dumps por console e transformar os dumps dos veículos de validação em testes golden.

### Changes

**Create**: `src/adapters/RuntimeVehicleReader.lua`
```lua
--- Lê o veículo de preview da ShopConfigScreen (ou qualquer veículo com dados de servidor) → Snapshot schema 1.
--- Cada bloco sob pcall próprio; falha num bloco = campo nil (registrado em DEBUG), nunca erro para cima.
function RuntimeVehicleReader.read(vehicle, storeItem, logger)
    local s = { schema = 1, identity = {}, configuration = {}, declared = {}, mass = {}, differentials = {}, wheels = {} }
    guard(logger, "identity", function() ... end)
    guard(logger, "configuration", function()                 -- cópia de vehicle.configurations
        for name, idx in pairs(vehicle.configurations or {}) do s.configuration[name] = idx end
    end)
    guard(logger, "declared", function()
        local specs = storeItem.specs or {}
        s.declared.powerHp = type(specs.power) == "number" and specs.power or nil
        local cfgs = storeItem.configurations and storeItem.configurations.motor
        local idx = s.configuration.motor
        if cfgs and idx and cfgs[idx] and type(cfgs[idx].power) == "number" then s.declared.powerHp = cfgs[idx].power end
        s.declared.price = storeItem.price
    end)
    guard(logger, "mass", function()
        if type(vehicle.updateMass) == "function" then vehicle:updateMass() end
        s.mass.totalT = vehicle:getTotalMass(true)
        if type(vehicle.getDefaultMass) == "function" then s.mass.defaultT = vehicle:getDefaultMass() end
    end)
    guard(logger, "motor", function()
        local spec = vehicle.spec_motorized
        local m = spec and spec.motor
        if m == nil then return end
        local curve = {}
        for _, kf in ipairs((m.torqueCurve and m.torqueCurve.keyframes) or {}) do
            curve[#curve + 1] = { rpm = kf.time, torque = kf[1] }     -- keyframe {torque, time=rpm} (Motorized.lua:1338)
        end
        s.motor = { minRpm = m.minRpm, maxRpm = m.maxRpm, peakTorque = m.peakMotorTorque, peakPowerKw = m.peakMotorPower,
            maxForwardSpeedMs = m.maxForwardSpeed, torqueCurve = curve,
            minForwardGearRatio = m.minForwardGearRatio, maxForwardGearRatio = m.maxForwardGearRatio,
            forwardGears = ratios(m.forwardGears), gearGroups = ratios(m.gearGroups) }
    end)
    guard(logger, "differentials", function() ... end)       -- cópia dos 6 campos (Motorized.lua:1191-1198)
    guard(logger, "wheels", function()
        for i, w in ipairs(vehicle:getWheels()) do
            local p = w.physics
            s.wheels[i] = { radius = p.radius, width = p.width, shapeWidth = p.wheelShapeWidth, massT = w:getMass(),
                restLoad = p.restLoad, frictionScale = p.frictionScale, isLeft = w.isLeft,
                tireTypeName = WheelsUtil.getTireTypeName(p.tireType),
                fieldFriction = WheelsUtil.getTireFriction(p.tireType, WheelsUtil.GROUND_FIELD, 0, 0),
                additionalCount = additionalCount(w) }
        end
    end)
    return s
end
```
Detalhes:
- `identity`: `xmlFilename`, `name`, `categoryName` e `vehicle.typeName` vêm de `storeItem`; a marca vem de `g_brandManager:getBrandByIndex(storeItem.brandIndex)`, lendo `.title` ou `.name`.
- `ratios(list)` extrai `.ratio` numérico.
- `additionalCount(w)` conta `#w.visualWheels - 1`, com fallback 0. [A VALIDAR na Fase 3]
- `debug#simulateFailure == "reader"` com `debug#enabled` faz `read` lançar erro de propósito, para o teste de degradação da Fase 5.

**Create**: `src/adapters/SnapshotXmlWriter.lua`. Usa `NS.core.Flatten.flatten`:
```lua
function SnapshotXmlWriter.write(snapshot, logger)
    local dir = (g_modSettingsDirectory or "") .. "FS25_VehiclePerformance/dumps/"
    local base = (snapshot.identity.xmlFilename or "unknown"):match("([^/\\]+)%.xml$") or "unknown"
    local path = string.format("%s%s_%s.xml", dir, base, NS.core.Hash.djb2(NS.app.ConfigurationResolver.key(snapshot)))
    pcall(createFolder, dir)
    local xmlFile = XMLFile.create("VPSnapshot", path, "vpSnapshot")
    xmlFile:setInt("vpSnapshot#schema", 1)
    for i, e in ipairs(NS.core.Flatten.flatten(snapshot)) do
        local key = string.format("vpSnapshot.v(%d)", i - 1)
        xmlFile:setString(key .. "#k", e.k); xmlFile:setString(key .. "#t", e.t)
        xmlFile:setString(key .. "#v", e.t == "n" and string.format("%.17g", e.v) or tostring(e.v))
    end
    xmlFile:save(); xmlFile:delete()
    return path
end
```

**Create**: `src/app/ConfigurationResolver.lua`. `key(snapshot)` = `xmlFilename .. "|" .. "name=idx;..."`, com os nomes ordenados. É a identidade técnica exigida por requisitos §5.

**Create**: `src/app/Console.lua`. Registra os comandos via a porta `registrar` (o `ConsoleRegistrar` do bootstrap) e recebe as dependências injetadas:
- `vpStatus`: estado, `HookRegistry.status()`, tamanho do cache (Fase 4), status do AVI (Fase 5) e versão.
- `vpDump`: para cada `g_shopConfigScreen.previewVehicles[i]`, chama `reader.read` e depois `writer.write`, e imprime os caminhos. Se não houver preview, responde "abra a tela de configuração de um veículo". Os acessos a `g_` ficam num adapter injetado (`previewSource:list()`), porque `app/` não pode usar `g_`.
- `vpAnalyze`: imprime todas as métricas do preview atual (`id = valor unidade [kind/status]`).
- `vpSet <showIndex|logLevel|pullingRef> <valor>`: grava em settings.

**Create**: `src/adapters/PreviewSource.lua`. `list()` devolve `{vehicle, storeItem}` para cada `previewVehicles` de `g_shopConfigScreen`, com guardas.

**Modify**: `src/adapters/GameBootstrap.lua`. Em `loadMap`, depois de `setLevel`:
```lua
        NS.adapters.reader = NS.adapters.RuntimeVehicleReader
        NS.app.consoleRegistrar = NS.app.consoleRegistrar or ConsoleRegistrar.new()
        NS.app.Console.install(NS.app.consoleRegistrar, {
            hookStatus = NS.adapters.HookRegistry.status,
            previewSource = NS.adapters.PreviewSource,
            reader = NS.adapters.RuntimeVehicleReader,
            writer = NS.adapters.SnapshotXmlWriter,
            analyze = NS.core.VehicleAnalyzer.analyze,
            settings = NS.app.settings,
            logger = NS.app.logger,
        })
```
Em `deleteMap`, chamar `NS.app.Console.uninstall()`.

**Modify**: `src/manifest.lua`. Acrescentar `app/ConfigurationResolver.lua` e `app/Console.lua` depois de `app/StateMachine.lua`, e `adapters/RuntimeVehicleReader.lua`, `adapters/SnapshotXmlWriter.lua` e `adapters/PreviewSource.lua` antes de `adapters/GameBootstrap.lua`.

**Modify**: `tools/fs25_globals.lua`. Garantir `WheelsUtil`, `g_brandManager` e `createFolder`.

**Coleta in-game** (humano, guiado): com o mod em `debug#logLevel=debug`, rodar `vpDump` para cada configuração abaixo. Depois copiar `modSettings/FS25_VehiclePerformance/dumps/*.xml` para `tests/fixtures/dumps/`, renomeando com os ids:

| id | Veículo | Configuração |
|---|---|---|
| `ford_auto_largo` | Ford 8030 | AUTOMATICO + PENEU LARGO + design 1 |
| `ford_auto_largo_ballast` | Ford 8030 | AUTOMATICO + PENEU LARGO + design "420" |
| `ford_manual_dual` | Ford 8030 | CAIXA MANUAL + DUPLA TRAZERA + design 1 |
| `valtra_145` / `valtra_180` / `valtra_205` | Valtra BH | BH 145 / BH 180 / BH 205i + MICHELIN (o 180 valida o fallback de motor parcial) |
| `volvo_ferro` / `volvo_alcoa` | Volvo FH | Roda De Ferro (6x2) / alcoa (6x4) |
| `base_2wd` | trator 2WD nativo (escolher na loja) | padrão |
| `base_crawler` | trator de esteiras nativo | padrão |
| `base_truck` | caminhão nativo | padrão |

**Create**: `docs/api-findings/2026-xx-xx-runtime.md`. Registra o que foi confirmado ou corrigido no jogo:
- nomes de campo;
- `additionalCount`;
- como o Valtra 180 resolve curva e marchas;
- se a massa em loja inclui combustível;
- se `peakMotorPower` bate com F2 recalculado.

Qualquer campo que divergir do Snapshot corrige o `RuntimeVehicleReader` **e** é registrado aqui.

**Create**: `tests/support/dump_loader.lua`. Lê o XML do dump com `tests/support/xml.lua`, gera a lista `{k,t,v}` e aplica `Flatten.unflatten`, devolvendo o Snapshot.

**Create**: `tests/fixtures/dumps/index.lua`, com a lista de ids, pares relativos e as seguintes invariantes:
```lua
return {
    ids = { "ford_auto_largo", "ford_auto_largo_ballast", "ford_manual_dual", "valtra_145", "valtra_180",
            "valtra_205", "volvo_ferro", "volvo_alcoa", "base_2wd", "base_crawler", "base_truck" },
    greater = { -- {métrica, maior, menor}
        { "tractionForceKn", "valtra_205", "valtra_145" }, { "tractionForceKn", "volvo_alcoa", "volvo_ferro" },
        { "massT", "ford_auto_largo_ballast", "ford_auto_largo" }, { "adhesionForceKn", "ford_auto_largo_ballast", "ford_auto_largo" },
        { "peakPowerKw", "valtra_180", "valtra_145" },
    },
    drivetrain = { volvo_ferro = "6x2", volvo_alcoa = "6x4", ford_auto_largo = "4x4", base_2wd = "4x2" },
}
```

**Create**: `tools/golden.lua` (rodado com `.lua/bin/lua`). Carrega o core via `tests/support/load.lua`, analisa todos os dumps e grava `tests/golden/expected.lua`, uma tabela com as métricas arredondadas a 6 casas. É executado **uma vez** após revisão humana dos valores, com `make golden-update`.

**Create**: `tests/golden/golden_spec.lua`, que verifica para cada dump:
- (a) a análise não lança erro;
- (b) as métricas batem com `expected.lua` (tolerância `1e-6`);
- (c) os invariantes `greater` e `drivetrain` de `index.lua` valem;
- (d) `peakPowerKw` do jogo e F2 recalculado da curva diferem menos de 1%.

**Modify**: `Makefile`. Acrescentar `golden-update: ; $(LUA) tools/golden.lua --write` (e incluir o alvo em `.PHONY`).

**Calibração de `F_ref`**: calcular a mediana de `tractionForceKn` dos dumps, arredondada a 5 kN. Se ela estiver fora de [30, 80], atualizar o default `metrics#pullingRefKN` em `SettingsStore.lua` e regenerar `expected.lua`. Registrar o valor e a mediana em `docs/api-findings`.

### Success Criteria

#### Automated Verification
- [ ] `make unit golden`: `golden_spec` passa com os 11 dumps. — **BLOQUEADO (ambiente sem FS25)**: infraestrutura pronta; `golden_spec` fica `pending` até os dumps serem coletados em jogo com `vpDump`.
- [x] `make deps lint fmt-check verify`: passam (`app/Console.lua` não usa `g_`).

#### Manual Verification
- [ ] `vpDump` grava um arquivo por preview e o caminho aparece no console.
- [ ] `vpAnalyze` no Ford mostra `drivetrain=4x4`, e no Volvo alcoa mostra `6x4`.
- [ ] O log em DEBUG lista os campos ausentes para veículos incompletos, sem erros.
- [ ] `docs/api-findings/...-runtime.md` está preenchido e as divergências foram corrigidas.

**⏸ PAUSE**: confirmação humana antes da Fase 4.

---

## Phase 4: Integração com a tela de configuração da loja

### Goal
Mostrar as linhas de desempenho via `registerCustomSpecValues`, localizadas e com cache, atualizando a cada troca de configuração.

### Changes

**Create**: `src/app/PerformanceService.lua`. Faz cache e análise, sem dependência do jogo:
```lua
function PerformanceService.new(deps) -- {analyze, settings, logger, maxEntries=64}
function PerformanceService:get(snapshot)
    local key = NS.app.ConfigurationResolver.key(snapshot)
    local hit = self.cache[key]
    if hit then self.hits = self.hits + 1; return hit end
    local data = self.analyze(snapshot, {
        loadRefWeightFraction = self.settings:get("metrics#loadRefWeightFraction"),
        pullingRefKN = self.settings:get("metrics#pullingRefKN"),
    })
    self:store(key, data) -- FIFO: remove a entrada mais antiga acima de maxEntries
    self.logger:debug("perf", "%s analisado; ausentes=%d", key, #(data.availability.missing or {}))
    return data
end
function PerformanceService:clear() self.cache, self.order, self.hits = {}, {}, 0 end
```
Observação: o `RuntimeVehicleReader` roda a cada reload do preview, o que é barato (só leitura de campos). O cache evita repetir a análise quando a mesma configuração é revisitada. As settings de métricas entram na chave via `vpSet`, que chama `clear()`.

**Create**: `src/app/RowFormatter.lua`. Converte `PerformanceData` em linhas. Recebe a porta `text` com `get(key)`, `number(v, precision)`, `speed(kmh) -> valor, unidade`, e `profiles` (ids simbólicos).
```lua
-- Devolve lista { {profile="WHEELS", text="..."}, ... } na ordem fixa abaixo; omite linha cujo valor principal é unknown,
-- exceto drivetrain (mostra vp_drivetrain_unknown) e load (mostra vp_row_load_insufficient).
function RowFormatter.rows(data, text, opts) -- opts.showPullingIndex
    local rows = {}
    -- 1 WHEELS:       vp_row_drivetrain        "%s · %d"  (label, drivenAxles)  | vp_drivetrain_unknown
    -- 2 POWER:        vp_row_power_calc        (cv, kW, N·m = kN·m*1000, reserva%) — omite reserva se unknown
    -- 3 WEIGHT:       vp_row_power_weight      (kg/cv, 1 casa)
    -- 4 TRANSMISSION: vp_row_traction          (kN 0 casas, vp_limit_adhesion|vp_limit_motor|vp_limit_partial)
    -- 5 MAX_SPEED:    vp_row_load              (fração %, velocidade, unidade) | vp_row_load_insufficient
    -- 6 POWER:        vp_row_pulling_index     (0 casas) — só se opts.showPullingIndex e status ok
    return rows
end
```
Os textos usam `string.format(text.get(key), ...)` sob pcall. Se o formato falhar, a linha é omitida e logada em WARNING.

**Create**: `src/adapters/GameText.lua`. Implementa a porta `text`:
- `get(key)` usa `g_i18n:getText(key)` (o mod tem `g_i18n` próprio no env);
- `number(v, p)` usa `g_i18n:formatNumber(v, p)` (`I18N.lua:419`), com fallback `string.format("%." .. p .. "f", v)`;
- `speed(kmh)` usa `g_i18n:getSpeed(kmh), g_i18n:getSpeedMeasuringUnit()` (`I18N.lua:284-300`).

**Create**: `src/adapters/ShopConfigAdapter.lua`
```lua
function ShopConfigAdapter.new(deps) -- {reader, service, formatter, text, settings, logger, state}
function ShopConfigAdapter:install()
    return NS.adapters.HookRegistry.add({
        id = "ShopConfigScreen.registerCustomSpecValues",
        target = ShopConfigScreen, method = "registerCustomSpecValues", kind = "append",
        fn = function(screen, values, storeItems, vehicle, saleItem) -- luacheck: ignore 212
            self:onCustomSpecValues(screen, values, vehicle)
        end,
    })
end
function ShopConfigAdapter:onCustomSpecValues(screen, values, vehicle)
    if not self.settings:get("ui#enabled") or type(values) ~= "table" then return end
    if vehicle == nil or vehicle.spec_motorized == nil then return end        -- não motorizado: nada a fazer
    local storeItem = screen and screen.storeItem
    if storeItem == nil then return end
    local snapshot = self.reader.read(vehicle, storeItem, self.logger)
    local data = self.service:get(snapshot)
    for _, row in ipairs(self.formatter.rows(data, self.text, { showPullingIndex = self.settings:get("ui#showPullingIndex") })) do
        local profile = ShopConfigScreen.GUI_PROFILE and ShopConfigScreen.GUI_PROFILE[row.profile]
        if profile then table.insert(values, { profile = profile, value = row.text }) end
    end
end
```
Notas:
- `processAttributeData` é chamado **só** a partir de `onVehiclesLoaded` com o preview (`ShopConfigScreen.lua:907`). O hook roda uma vez por preview carregado, nunca por frame.
- Qualquer erro é contido pelo pcall do HookRegistry, que se desativa após 3 falhas. Como o hook é `append`, as linhas vanilla já foram inseridas e continuam intactas.
- `debug#simulateFailure == "hook"` com `debug#enabled` faz `onCustomSpecValues` lançar erro de propósito (Fase 5).

**Modify**: `src/adapters/GameBootstrap.lua` (`loadMap`). Depois do Console:
```lua
        NS.app.performanceService = NS.app.PerformanceService.new({
            analyze = NS.core.VehicleAnalyzer.analyze, settings = NS.app.settings, logger = NS.app.logger })
        NS.adapters.shopConfigAdapter = NS.adapters.ShopConfigAdapter.new({
            reader = NS.adapters.RuntimeVehicleReader, service = NS.app.performanceService,
            formatter = NS.app.RowFormatter, text = NS.adapters.GameText, settings = NS.app.settings,
            logger = NS.app.logger, state = NS.app.state })
        if not NS.adapters.shopConfigAdapter:install() then
            NS.app.logger:warning("bootstrap", "ShopConfigScreen.registerCustomSpecValues indisponível; UI desativada")
        end
```
Em `deleteMap`, chamar `NS.app.performanceService:clear()`. O `Console` passa a receber `service` (para `vpStatus` e para `vpSet`, que chama `clear()`).

**Modify**: `src/manifest.lua`. Acrescentar `app/PerformanceService.lua` e `app/RowFormatter.lua` depois de `app/ConfigurationResolver.lua`, e `adapters/GameText.lua` e `adapters/ShopConfigAdapter.lua` antes de `adapters/GameBootstrap.lua`.

**Modify**: `src/translations/translation_en.xml` e `translation_br.xml`. Chaves (en / br). `%%` gera um `%` literal.

| key | en | br |
|---|---|---|
| `vp_row_drivetrain` | `Drive %s · %d driven axle(s)` | `Tração %s · %d eixo(s) motriz(es)` |
| `vp_drivetrain_unknown` | `Drive: unknown` | `Tração: desconhecida` |
| `vp_row_power_calc` | `Calc. peak: %s hp / %s kW · %s N·m (+%s%%)` | `Pico calc.: %s cv / %s kW · %s N·m (+%s%%)` |
| `vp_row_power_calc_noreserve` | `Calc. peak: %s hp / %s kW · %s N·m` | `Pico calc.: %s cv / %s kW · %s N·m` |
| `vp_row_power_weight` | `%s kg/hp` | `%s kg/cv` |
| `vp_row_traction` | `Traction force ~%s kN (%s)` | `Força de tração ~%s kN (%s)` |
| `vp_limit_adhesion` | `grip` | `aderência` |
| `vp_limit_motor` | `engine` | `motor` |
| `vp_limit_partial` | `partial data` | `dados parciais` |
| `vp_row_load` | `Under load (%s%% of weight) ~%s %s` | `Sob carga (%s%% do peso) ~%s %s` |
| `vp_row_load_insufficient` | `Under load: insufficient traction` | `Sob carga: tração insuficiente` |
| `vp_row_pulling_index` | `Pulling index %s (heuristic)` | `Índice de puxada %s (heurístico)` |

**Create**: os testes em `tests/unit/`:
- `service_spec.lua`:
  - hit e miss;
  - a chave muda quando uma configuração muda;
  - FIFO com `maxEntries=2`;
  - `clear()` zera o cache.
- `formatter_spec.lua`, com a porta `text` falsa (`get` devolve a chave com `%s`):
  - ordem e perfis das linhas;
  - omissão de linhas unknown;
  - `insufficient`;
  - índice só com `showPullingIndex`;
  - formato quebrado omite a linha sem lançar erro.
- `shop_adapter_spec.lua`, com stubs de `ShopConfigScreen = {registerCustomSpecValues=function() end, GUI_PROFILE={...}}` e `Utils.appendedFunction`:
  - chamar o método instalado com um veículo falso e `values={}` insere linhas;
  - com `spec_motorized=nil`, não insere nada;
  - reader que lança erro: após 3 chamadas o hook fica inativo e `values` segue sem linhas extras e sem erro;
  - com `ui#enabled=false`, nada é inserido.

### Success Criteria

#### Automated Verification
- [x] `make unit golden`: passam (golden `pending`, ver Fase 3).
- [x] `make deps lint fmt-check verify`: passam, incluindo as chaves `vp_` presentes em `translation_en.xml`.

#### Manual Verification
- [ ] Na tela de configuração do Ford 8030 aparecem as 5 linhas (sem índice), coerentes com `vpAnalyze`.
- [ ] Trocar a motorização de AUTOMATICO para CAIXA MANUAL atualiza potência, peso/potência e tração. Trocar o design "420" altera peso/potência e aderência.
- [ ] No Volvo, trocar Roda De Ferro por alcoa muda `6x2 · 1` para `6x4 · 2`.
- [ ] Um implemento não motorizado (ex.: reboque) não ganha linhas extras e não gera erro.
- [ ] Trocar rapidamente entre 10 veículos e abrir/fechar a loja 10 vezes: nenhum erro, e nenhuma lentidão perceptível em comparação com o mod desativado.
- [ ] Idioma inglês e português: os textos saem corretos e as unidades mph/km/h seguem a configuração do jogo.
- [ ] `vpSet showIndex 1` faz a linha do índice aparecer na próxima troca de configuração.

**⏸ PAUSE**: confirmação humana antes da Fase 5.

---

## Phase 5: Compatibilidade, API pública, endurecimento e documentação

### Goal
Detectar o AVI, expor a API pública, provar a degradação segura e fechar a documentação e o checklist de release.

### Changes

**Create**: `src/adapters/AdditionalVehicleInfoAdapter.lua`
```lua
local MOD_NAME = "FS25_additionalVehicleInfo" -- nome exato (a minúsculo) — PRD §AVI
function AdditionalVehicleInfoAdapter.detect(logger)
    local status = { present = false, version = nil, integration = "coexist" }
    local ok = pcall(function()
        status.present = type(g_modIsLoaded) == "table" and g_modIsLoaded[MOD_NAME] == true
        if status.present and g_modManager and type(g_modManager.getModByName) == "function" then
            local mod = g_modManager:getModByName(MOD_NAME)
            status.version = mod and mod.version
        end
    end)
    if not ok then status.integration = "error" end
    logger:info("avi", "Additional Vehicle Info: %s (v%s, %s)", status.present and "presente" or "ausente",
        tostring(status.version), status.integration)
    return status
end
```
Regras:
- sem hooks e sem acesso ao env do AVI;
- a integração atual é coexistência (o AVI atua só no HUD, `PlayerHUDUpdater.showVehicleInfo`, e nós só na `ShopConfigScreen`);
- um erro na detecção não afeta o resto do mod (requisitos §11.4).

**Create**: `src/app/PublicApi.lua`. Expõe `NS.api`:
```lua
-- API pública estável (requisitos §15). Leitura sob demanda; nunca lança erro para o chamador.
function PublicApi.install(ns, deps) -- deps: {reader, service, storeItemOf(vehicle)}
    ns.api.VERSION = 1
    ns.api.getPerformance = function(vehicle)          -- PerformanceData ou nil
        local ok, data = pcall(function()
            local storeItem = deps.storeItemOf(vehicle)
            if storeItem == nil then return nil end
            return deps.service:get(deps.reader.read(vehicle, storeItem, deps.logger))
        end)
        return ok and data or nil
    end
    ns.api.getMetric = function(vehicle, metricId)
        local data = ns.api.getPerformance(vehicle)
        return data and data:get(metricId)
    end
    ns.api.getCurrentConfiguration = function(vehicle)
        local out = {}
        for k, v in pairs((vehicle and vehicle.configurations) or {}) do out[k] = v end
        return out
    end
end
```
Detalhes:
- `storeItemOf` fica em `adapters/PreviewSource.lua` e usa `g_storeManager:getItemByXMLFilename(vehicle.configFileName)`.
- Os diferenciais só existem em veículos com dados de servidor. Num cliente MP puro, `drivetrain` pode sair `unknown`, e isso deve constar da documentação da API.
- A API fica acessível a outros mods via `getfenv(0).g_vehiclePerformanceApi = ns.api`, atribuído no `loadMap` e limpo no `deleteMap`, no mesmo padrão do `g_EnhancedVehicle` (EnhancedVehicle `Loader.lua:62`). [A VALIDAR na Fase 5, no jogo, com um mod de teste mínimo]

**Modify**: `src/adapters/GameBootstrap.lua`. No `loadMap`:
- chamar `NS.app.aviStatus = NS.adapters.AdditionalVehicleInfoAdapter.detect(NS.app.logger)` e `NS.app.PublicApi.install(NS, {...})`;
- expor `g_vehiclePerformanceApi`.

No `deleteMap`, zerar `g_vehiclePerformanceApi`. O `Console` recebe `aviStatus` para o `vpStatus`.

**Modify**: `src/manifest.lua`. Acrescentar `app/PublicApi.lua` e `adapters/AdditionalVehicleInfoAdapter.lua`.

**Create**: os testes em `tests/unit/`:
- `resilience_spec.lua`:
  - `simulateFailure="reader"`: 3 aberturas desativam o hook e `values` permanece com as linhas vanilla;
  - `simulateFailure="hook"`: o mesmo resultado;
  - `StateMachine` não sai de `degraded`;
  - `SafeCall` no `loadMap` com erro degrada sem propagar.
- `avi_spec.lua`:
  - presente, ausente e `g_modManager` com erro devolvem `integration="error"` sem lançar erro;
  - nenhum hook é registrado.
- `api_spec.lua`:
  - `getPerformance(nil)` devolve nil;
  - um veículo falso devolve dados;
  - `getMetric` devolve o Value;
  - um reader que lança erro devolve nil;
  - `getCurrentConfiguration` devolve uma cópia (mutar a cópia não altera o veículo).

**Create**: a documentação em `docs/`:
- `docs/FORMULAS.md`: tabela §Fórmulas completa, unidades, justificativas, valores dos fixtures manuais e dos dumps, e o `F_ref` calibrado. Cumpre requisitos §7.4.
- `docs/adr/0001-clean-room.md`: sem código do EnhancedVehicle nem do AVI; o SSS é próprio.
- `docs/adr/0002-hexagonal.md`
- `docs/adr/0003-hook-registry.md`
- `docs/adr/0004-preview-runtime-source.md`: preview + dump, sem parser XML.
- `docs/adr/0005-registerCustomSpecValues.md`: linhas nativas, sem seção própria.
- `docs/adr/0006-avi-coexistence.md`
- `docs/adr/0007-client-only.md`

  Todos no formato Status / Contexto / Decisão / Consequências, como os ADRs do SSS.
- `docs/compatibility-matrix.md`: veículos §20 e integração §20 × resultado (preenchido na verificação manual).
- `docs/traceability.md`: seção de `requisitos.md` → componente → teste ou verificação.
- `docs/release-checklist.md`: TestRunner GIANTS sem erros, ZIP `FS25_` sem versão no nome interno, ícone DDS, log limpo em nível info, en e br, MP host/cliente e dedicated.

**Modify**: `CHANGELOG.md`. Preencher `### Adicionado` com as funcionalidades.

**Modify**: `README.md`. Descrever uso, comandos de console, settings (`modSettings/FS25_VehiclePerformance/settings.xml`) e a API pública.

### Success Criteria

#### Automated Verification
- [x] `make ci`: fmt-check, lint, deps, unit, golden e verify passam (99 unit; golden `pending` sem dumps reais).
- [x] `make build`: gera `dist/FS25_VehiclePerformance-1.0.0.zip` e `SHA256SUMS`.

#### Manual Verification
- [ ] Sem o AVI: `vpStatus` mostra `avi=ausente` e a loja fica igual à da Fase 4.
- [ ] Com o `FS25_additionalVehicleInfo` 1.0.0.0 instalado: a loja mostra as nossas linhas, o HUD in-world mostra as do AVI, e o log não tem erros de nenhum dos dois.
- [ ] `debug#enabled=true` + `simulateFailure="hook"`: após 3 aberturas o log mostra o erro e a desativação, e a loja segue funcional só com as linhas vanilla.
- [ ] Dedicated server (ou `g_dedicatedServer` simulado): o mod fica em `disabled-dedicated`, sem hooks.
- [ ] MP como cliente: a loja funciona, e métricas sem dados saem `desconhecido` ou são omitidas, sem erro.
- [ ] Um mod de teste chama `g_vehiclePerformanceApi.getMetric(vehicle, "drivetrain")` e recebe o Value.
- [ ] O GIANTS TestRunner no ZIP não aponta erros. `docs/compatibility-matrix.md` está preenchido.

**⏸ PAUSE**: confirmação humana. Depois disso, `status: approved` no CHANGELOG e release.

---

## Testing Strategy

### Unit Tests
- `core/`: cada analyzer e cada métrica, isolados, com os fixtures manuais. Casos de borda:
  - curva de 1 ponto, torque constante e `T(maxRpm)=0`;
  - sem motor, sem diferenciais e índices inválidos;
  - `Σ restLoad = 0` e μ ausente;
  - CVT versus marchas, sem grupos;
  - tração insuficiente e só uma força disponível (`partial`).
- `app/`: cache (chave por configuração, FIFO, clear), formatter (omissão, formatos quebrados), API (erros contidos), ConfigurationResolver (ordem estável das chaves).
- `adapters/`: com stubs dos globais (padrão de `SmartShopSearch/tests/unit/adapters_spec.lua:1-40`, `rawset(_G, ...)`). Cobre HookRegistry, ShopConfigAdapter, AVI, bootstrap e dedicated.
- Roundtrip `Flatten`, para garantir que dump e loader são inversos.

### Integration Tests
- `tests/golden/golden_spec.lua`: dumps reais → análise → valores golden + invariantes relativos + consistência `peakMotorPower` versus F2.
- In-game (manual, por fase): troca de veículo e configuração, abrir/fechar repetido, AVI presente/ausente, degradação, MP e dedicated.

### Migration & Rollback
- Não há savegame nem migração. O mod só lê.
- Rollback = remover o ZIP. As settings em `modSettings/FS25_VehiclePerformance/` podem ser apagadas sem efeito colateral.
- Desligar a UI sem desinstalar: `ui#enabled=false` no settings.xml.

## Environment Considerations
- **CI/CD**: só local (`make ci`). O `ci.yml` fica para quando houver remote (fora de escopo).
- **Migrations**: nenhuma.
- **Config/Secrets**: `modSettings/FS25_VehiclePerformance/settings.xml` com os defaults da Fase 1. Nenhum segredo.
- **Multi-environment**: SP e MP host têm dados completos. No cliente MP puro os diferenciais podem estar ausentes (a API degrada). O preview da loja tem `forceServer`, então tem dados completos mesmo no cliente [A VALIDAR na Fase 5]. Dedicated server fica desativado.

## Dependencies & Risks
- **Decompilação dataS** (literais possivelmente corrompidos): todo nome de campo usado no reader é confirmado na Fase 3 e registrado em `docs/api-findings`.
- **Mudança de API em patch futuro** (`registerCustomSpecValues` ou nomes de campo): mitigada pelo HookRegistry (alvo ausente gera WARNING e desativa só a UI) e pelas guardas por bloco no reader.
- **Fase 3 depende de rodar o jogo**: sem os dumps, as Fases 4 e 5 seguem com os fixtures manuais, mas a calibração de `F_ref` e os goldens reais ficam pendentes.
- **Fixtures de terceiros com defeitos** (Valtra: XML malformado na l.234 e arquivos ausentes): se impedirem o carregamento no jogo, substituir o Valtra por um trator nativo com múltiplas motorizações e registrar em `api-findings`.
- **Fidelidade das estimativas** (F9–F12): são modelos simplificados, sem atrito em estrada nem carga dinâmica, e estão marcados como `estimated`/`heuristic`. O índice fica desligado por padrão.
- **Outros mods que também anexam em `registerCustomSpecValues`**: `append` encadeia sem conflito. A ordem das linhas depende da ordem de carga dos mods.

## References
- PRD: `specs/research/2026-09-27-fs25-vehicle-performance.md`
- Requisitos: `requisitos.md`
- Padrões: `/home/alencar/WorkSpace/FS25/SmartShopSearch` (`src/`, `tools/`, `tests/support/`, `docs/adr/`)
- Fonte do jogo: https://github.com/maxkra1985/FarmingSimulator25_dataS (`754ef8a`), https://github.com/umbraprior/FS25-Community-LUADOC (`24afb18`), https://gdn.giants-software.com/documentation_scripting_fs25.php
- Additional Vehicle Info: https://farming-simulator.com/mod.php?mod_id=372725&title=fs2025
- Referência de infraestrutura (sem copiar código): https://github.com/ZhooL/FS25_EnhancedVehicle (`cd80bd2`)
