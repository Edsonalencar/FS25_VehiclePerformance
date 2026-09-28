---
date: 2026-09-27T23:40:00-03:00
researcher: claude
git_commit: n/a (diretório ainda não é repositório git)
branch: n/a
topic: "FS25 Vehicle Performance — análise e apresentação de desempenho de veículos na loja do FS25"
tags: [research, fs25, shop, ShopConfigScreen, Motorized, VehicleMotor, Wheels, differentials, AdditionalVehicleInfo, EnhancedVehicle]
status: complete
---

# Research: FS25 Vehicle Performance

## Research Question
Construir o mod **FS25 Vehicle Performance** conforme [requisitos.md](../../requisitos.md): exibir na loja do FS25 métricas técnicas (massa, motor/curva de torque, transmissão, diferenciais, rodas) e índices derivados da **configuração selecionada**, com núcleo de cálculo separado da UI, compatibilidade obrigatória (não dependência) com *Additional Vehicle Info*, e usando `ZhooL/FS25_EnhancedVehicle` (CC BY-NC-SA 4.0, arquivado) apenas como referência de infraestrutura. Projeto irmão independente: `../SmartShopSearch`. Fixtures reais: Ford 8030, Volvo FH 2012, Valtra BH180.

## Summary
**O diretório do mod está vazio** (só `requisitos.md` e `.claude/skills`). Não há código a alterar; o PRD mapeia a plataforma, os padrões a reutilizar e os dados de validação.

**Descoberta central (verificada no código do jogo 1.21.1.0):** a tela de configuração da loja (`ShopConfigScreen`) **instancia veículos reais de preview** a cada mudança de configuração, com `setForceServer(true)`. Por isso os dados de física só do servidor já existem na loja: `spec_motorized.motor` (VehicleMotor com curva de torque, marchas, grupos, `peakMotorPower`), `spec_motorized.differentials`, `spec_wheels.wheels[i].physics` e `getTotalMass(true)`. Além disso, o jogo oferece um **hook vazio feito para mods**, `ShopConfigScreen:registerCustomSpecValues(values, storeItems, vehicle, saleItem)`, chamado ao fim de `processAttributeData` a cada reload do preview. Basta dar `table.insert(values, {profile=..., value=...})` e o jogo desenha as linhas na lista de atributos. Com isso, a maior parte do parsing XML pedido nos requisitos §4 pode ser trocada por **leitura em runtime do veículo de preview** já montado pelo próprio motor do jogo. O parsing XML fica como caminho offline para testes e fallback.

**Compatibilidade:** o *Additional Vehicle Info* publicado no ModHub para FS25 (`FS25_additionalVehicleInfo`, Helfer B., v1.0.0.0) **não toca a loja**. Ele só estende a caixa de informações do HUD in-world (`PlayerHUDUpdater.showVehicleInfo`) e não expõe API pública. O risco de conflito na loja é portanto nulo, mas isso contradiz a premissa dos requisitos §11 (ver Open Questions). O EnhancedVehicle também não toca a loja nem lê motor, marchas ou rodas. Ele serve só para o bootstrap, o registro de specialization e a leitura de `differentials`. Os padrões mais valiosos vêm do **SmartShopSearch**, do mesmo autor: arquitetura hexagonal core/app/adapters, HookRegistry, SafeCall com degradação, Logger, busted em Lua 5.1, build.py e ADRs. Ressalva: nada do SSS foi validado in-game.

## Codebase Map

### Estado atual
| Caminho | Conteúdo |
|---|---|
| `requisitos.md` | Requisitos v1 (25 seções). Única fonte do projeto. |
| `.claude/skills/{prd,spec,code,commit,open-pr,skill-architect}` | Mesmas skills do SSS. |
| (nada mais) | Sem `src/`, sem git, sem modDesc. |

### Arquivos a criar (espelhando o SSS; nomes conforme requisitos §8)
| Arquivo | Papel |
|---|---|
| `src/modDesc.xml` | descVersion, l10n, `extraSourceFiles` → `main.lua`, multiplayer |
| `src/main.lua` + `src/manifest.lua` | Bootstrap: captura `g_currentModDirectory/Name`, 1 global, `source()` na ordem do manifest |
| `src/core/*` | Lua 5.1 puro, sem `g_*`: `PerformanceData`, analyzers (Motor/Transmission/Mass/Differential/Wheel/Traction), metrics |
| `src/app/*` | Orquestração, cache e invalidação, `SafeCall`, `StateMachine`, API pública |
| `src/adapters/*` | Único lugar com FS25: `GameBootstrap`, `HookRegistry`, `ShopConfigAdapter` (hook `registerCustomSpecValues`), `RuntimeVehicleReader` (lê o preview), `XmlVehicleReader` (offline/fallback), `AdditionalVehicleInfoAdapter`, `GameLogger`, `SettingsStore` |
| `src/translations/translation_{en,br}.xml` | Chaves com prefixo próprio (ex.: `vp_`) |
| `tests/{unit,golden,fixtures}` | busted; fixtures = dumps normalizados dos 3 veículos |
| `tools/{build.py,check_deps.py,fs25_globals.lua}`, `Makefile`, `.luacheckrc`, `.stylua.toml`, `types/fs25.lua` | Copiar e adaptar do SSS (projeto próprio, MIT) |

### Existing Patterns to Follow (SmartShopSearch, `/home/alencar/WorkSpace/FS25/SmartShopSearch`)

**Pattern: bootstrap com global único + manifest** (`src/main.lua:1-20`)
```lua
local MOD_DIR, MOD_NAME = g_currentModDirectory, g_currentModName
SmartShopSearch = {MOD_DIR=MOD_DIR, MOD_NAME=MOD_NAME, VERSION=..., core={}, app={}, adapters={}, data={}}
source(MOD_DIR.."manifest.lua")
for _, f in ipairs(SmartShopSearch.manifest) do source(MOD_DIR..f) end
SmartShopSearch.adapters.GameBootstrap.install(SmartShopSearch)
```
Módulo: `local NS = SmartShopSearch; local X = {}; ...; NS.core.X = X` (spec SSS `:84-91`).

**Pattern: HookRegistry** (`src/adapters/HookRegistry.lua:12-60`, ADR-0003). `add{id,target,method,kind,fn}`:
- é idempotente por id e só avisa se o alvo não for função;
- roda o corpo em pcall e se auto-desativa após 3 falhas;
- em `overwrite`, cai para `superFunc` em caso de erro.

É o único lugar que instala hooks. Hooks são sempre `append` em classe concreta, nunca em classe base (o hook em `TabbedMenuWithDetails.onOpen` quebrou o Garage Menu, SSS PRD D6).

**Pattern: SafeCall + StateMachine** (`src/app/SafeCall.lua:5-20`, `src/app/StateMachine.lua:5-11`). Estados: `loaded`, `ready`, `degraded` (terminal) e `disabled-dedicated`. Após 3 falhas por contexto, o SafeCall chama `degrade()`. Isso atende requisitos §11.4 e §12.

**Pattern: Logger** (`src/adapters/GameLogger.lua:33-79`). Níveis error/warning/info/debug (requisitos §17). Prefixo `[Mod] level:`. Usa `Logging.*` e cai para `print`. Limita erros a 1 por 60 s por chave.

**Pattern: Settings** (`src/adapters/SettingsStore.lua:7-24`). Grava em `modSettings/<Mod>/settings.xml` via `XMLFile`, sem dados no savegame. Tem `debug#simulateFailure` para testar degradação.

**Pattern: guardas** (ADR/PRD SSS P7):
- `type(x)=="function"` antes de todo acesso à API do jogo;
- pcall por campo e por item;
- tabela de UI com chaves fracas (`setmetatable({}, {__mode="k"})`) em vez de campos nos objetos do jogo;
- nada de GUI em dedicated server (`g_dedicatedServer ~= nil`).

**Pattern: tooling.**
- `Makefile:1-21`: fmt, lint, deps, trace, unit, golden, bench, build, verify, ci.
- Testes: busted em Lua 5.1 via hererocks `.lua/`.
- `tests/support/load.lua` carrega core/app fora do jogo.
- `tools/check_deps.py` proíbe `g_*`, `Utils.` e `XMLFile` em `core/`.
- `tools/build.py:46-111` valida o modDesc, as chaves l10n e o manifest, e gera o ZIP e o SHA256SUMS.
- Documentação: ADRs em `docs/adr/`, `docs/api-findings/TEMPLATE.md` para validação in-game.
- Commits em PT-BR `tipo(escopo): ...` sem co-autoria (skill `commit`).
- Licença: MIT para o código, arte com todos os direitos reservados.

**Ressalvas do SSS**:
- Todo o código de jogo está `[A VALIDAR]` e o spike nunca rodou (`docs/PENDENCIAS.md §1`).
- `Utils.cloneButton` provavelmente não é vanilla. Veio de uma lib de terceiros.
- `tools/check_trace.py:5` lê `ROOT/requisitos.md`, mas o arquivo foi movido para `docs/`.
- O `descVersion="96"` não foi confirmado.

### Data Flow (loja vanilla, verificado em dataS 1.21.1.0)
```
ShopConfigScreen:setStoreItem(storeItem, vehicle, saleItem, ...)            ShopConfigScreen.lua:1139
  └─ self.configurations = defaultConfigurationIds ⊕ vehicle ⊕ saleItem     :1146-1167
  └─ updateDisplay → updateData                                             :1048 / :818
       └─ loadCurrentConfiguration(storeItem)                               :858
            VehicleLoadingData: setConfigurations(self.configurations),
            setPropertyState(SHOP_CONFIG), setForceServer(true) (:877), load(onVehiclesLoaded)
  └─ onVehiclesLoaded(vehicles)                                             :889
       previews antigos → removeFromPhysics → previousVehicles (apagados em onFinishedLoading :967)
       self.previewVehicles = vehicles
       processAttributeData(storeItem, previewVehicle)                      :456 (chamado em :907)
         ├─ StoreItemUtil.loadSpecsFromXML(item)  (preenche storeItem.specs uma vez só)
         ├─ linhas vanilla: power (:350, = motorConfiguration#hp, texto de loja),
         │   weight (:377 → Vehicle.getSpecValueWeight → updateMass + getTotalMass(true)),
         │   maxSpeed (Motorized.getSpecValueMaxSpeed :531), transmission, pneus
         ├─ self:registerCustomSpecValues(values, storeItems, vehicle, saleItem)   :759  ← PONTO DE EXTENSÃO
         └─ clona self.attributeItem para cada {profile,value} em attributesLayout  :760-770
Mudança de opção (onClickCallback :1723-1729): self.configurations[name]=index → updateData → novo preview
```

## External Research

### Documentação e fontes do jogo
| Fonte | Commit | Uso |
|---|---|---|
| [maxkra1985/FarmingSimulator25_dataS](https://github.com/maxkra1985/FarmingSimulator25_dataS) | `754ef8aadcfae3ad15e257c0cc1575f1425591bc` | Decompilação do jogo 1.21.1.0. Os locais aparecem como `vNN_` e há ao menos uma string corrompida (`Vehicle.loadSpecValueWeight` lê `connections` em vez de `components`). Conferir literais no LUADOC. |
| [umbraprior/FS25-Community-LUADOC](https://github.com/umbraprior/FS25-Community-LUADOC) | `24afb18e7cfb788b7686b9ec791671e0dcba32b9` | Espelho do GDN 1.20.0.0 com os nomes originais. Não tem página de ShopConfigScreen. |
| [GDN FS25 scripting](https://gdn.giants-software.com/documentation_scripting_fs25.php) | – | Fonte primária oficial (requisitos §24). |
| [ModHub guidelines](https://forum.giants-software.com/viewtopic.php?t=209169) | – | Prefixo `FS25_`. Mods com Lua são **só PC** (console e crossplay proíbem script). Usar o TestRunner. |

Permalink base: `https://github.com/maxkra1985/FarmingSimulator25_dataS/blob/754ef8aadcfae3ad15e257c0cc1575f1425591bc/scripts/`

**Loja — `gui/ShopConfigScreen.lua`**
- Instância global `g_shopConfigScreen` (`main.lua:550`).
- Estado atual:
  - `g_shopConfigScreen.configurations` (nome → índice);
  - `.storeItem`;
  - `.configurationData`;
  - `.previewVehicles[i]` (com `propertyState == VehiclePropertyState.SHOP_CONFIG`, testável via `vehicle:getIsInShowroom()`, `Vehicle.lua:3060`).
- O preview é **recriado a cada mudança**, então não se deve guardar referência a ele.
- Hook recomendado, com o vazio verificado em `:773`:
  ```lua
  ShopConfigScreen.registerCustomSpecValues = Utils.appendedFunction(ShopConfigScreen.registerCustomSpecValues,
      function(self, values, storeItems, vehicle, saleItem) table.insert(values, {profile="shopConfigAttributeIconPower", value="…"}) end)
  ```
- Profiles de ícone disponíveis em `ShopConfigScreen.GUI_PROFILE` (`shopConfigAttributeIconPower/MaxSpeed/Weight/Wheels/Transmission…`).
- Cada linha é **ícone + texto**, sem rótulo separado.

**Spec types — `shop/StoreManager.lua:414`**
- Assinatura: `addSpecType(name, profile, loadFunc, getValueFunc, species, relatedConfigurations, configDataFunc)`. Dá erro se o nome já existir.
- `loadFunc(xmlFile, customEnv, baseDir)` guarda o resultado em `storeItem.specs[name]`.
- `getValueFunc(storeItem, realItem, configurations, saleItem, returnValues, returnRange)` devolve a string exibida.
- Uso na loja:
  - a lista da loja (`ShopController:makeDisplayItem`, `ShopController.lua:322/424`) itera os spec types;
  - a tela de configuração usa linhas fixas mais `registerCustomSpecValues`.
- O cache é preguiçoso: `StoreItemUtil.loadSpecsFromXML` (`StoreItemUtil.lua:177`) só roda quando `specs == nil`. Registrar spec type depois disso não afeta itens já carregados. [I]
- Exemplos no jogo: `Motorized.lua:10-16` e `Vehicle.lua:237-246`.

**Motor — `vehicles/VehicleMotor.lua`, `vehicles/specializations/Motorized.lua`**
- `VehicleMotor.new(vehicle, minRpm, maxRpm, maxFwdSpeed, maxBwdSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minFwdRatio, maxFwdRatio, minBwdRatio, maxBwdRatio, ptoRatio, minSpeed)` (`:31`). Velocidades em m/s.
- Campos:
  - `torqueCurve` (AnimCurve; keyframes `{torque, time=rpm}`);
  - `peakMotorTorque`;
  - `peakMotorPower` (**kW**) e `peakMotorPowerRotSpeed` (rad/s);
  - `minRpm`, `maxRpm`;
  - `forwardGears`/`backwardGears` (`{ratio,name,default}`, **já multiplicados por axleRatio**, nil em CVT);
  - `min/maxForwardGearRatio` (só em CVT);
  - `gearGroups{ratio,isDefault,name}` e `activeGearGroupIndex`;
  - `rotInertia`, `brakeForce`.
- Métodos:
  - `getPeakTorque()` (`:357`); **não existe `getMaxTorque`**;
  - `getMinRpm()`/`getMaxRpm()` (`:365/369`);
  - `getTorqueCurveValue(rpm)`, que aplica o dano `×(1-damage·0.3)`;
  - `getGearRatioMultiplier()` (`:1889`);
  - `VehicleMotor.calculatePhysicalMaximumSpeed(minRatio, gears, maxRpm)` = `maxRpm·π/(30·minRatio)` m/s (`:719`).
- `Motorized:loadMotor` (`:1205-1343`):
  - a chave vem de `ConfigurationUtil.getXMLConfigurationKey(..., "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")`, com **fallback para `motorConfiguration(0)`** (explica o caso Valtra);
  - defaults: `minRpm=1000`, `maxRpm=1800`, `brakeForce=10·2`, `torqueScale=1`;
  - torque = `torque(?)#normRpm × maxRpm`, e `#torque × torqueScale`;
  - `#maxForwardSpeed` da configuração de rodas sobrescreve o do motor;
  - transmissão **inline** em `<config>.transmission` com fallback para config(0); não existe `$data/shared/transmissions` [V por grep];
  - `loadGears` (`:1356`): um gear só com `#maxSpeed` vira ratio `maxRpm·π/(maxSpeed/3.6·30)`, depois `×axleRatio`;
  - `loadGearGroups`: `ratio = 1/xmlRatio` (`:1419`).
- Os valores de loja (`motorConfiguration#hp`/`#maxSpeed`, `VehicleConfigurationItemMotor.lua`) são **texto declarado**, não física. Ex.: Ford storeData 150 cv contra configs de 200/250 cv.

**Diferenciais — `Motorized.lua:1156-1203, 2242-2266`**
- Caminho XML: `vehicle.motorized.differentialConfigurations.differentialConfiguration(i).differentials.differential` ou `vehicle.motorized.differentials.differential`.
- **O índice é escolhido pela configuração de rodas**: `self.differentialIndex = <wheelConfig>.wheels#differentialIndex` (`Wheels.lua:298`). Isso resolve o caso Volvo: `<wheels differentialIndex="1|3">` é padrão, não anômalo.
- Cada entrada tem `{torqueRatio(0.5), maxSpeedRatio(1.3), diffIndex1, diffIndex1IsWheel, diffIndex2, diffIndex2IsWheel}`:
  - `#wheelIndexN` é 1-based e marca `isWheel=true`;
  - `#differentialIndexN` é guardado como N-1 e marca `isWheel=false`.
- Os diferenciais só existem `if self.isServer` (no preview existem, por causa do forceServer).
- **Rodas motrizes = rodas alcançadas pela árvore de diferenciais.** Não há flag por roda. [V/I]
- O EnhancedVehicle assume heuristicamente os índices 1/3/0 (frente/trás/centro) e não lê `diffIndex2`. Não copiar essa heurística.

**Rodas — `vehicles/wheels/*`**
- Acesso: `spec_wheels.wheels`, `getWheels()`, `getWheelFromWheelIndex(i)`.
- `Wheel.new(...)` (LUADOC `Wheels/Wheel.md:361`):
  - campos `.physics`, `.additionalMass`, `.name`, `.isLeft`, `.node`;
  - `getMass() = physics.mass + additionalMass`.
- `WheelPhysics:loadFromXML` (`WheelPhysics.md:320-420`), com defaults:
  - `radius` 0.5, `width` 0.5, `mass` 0.1 t;
  - `restLoad` 1, `frictionScale` 1, `forcePointRatio` 0;
  - `maxLongStiffness` 30, `maxLatStiffness` 40, `maxLatStiffnessLoad` 2;
  - `tireType` "mud".
- `finalize()`:
  - `restLoad += mass - baseMass`;
  - `maxLatStiffness *= restLoad`.
- Arquivo de roda externo:
  - usa `#filename` + `#configId` (default "default");
  - `WheelXMLObject:getValue` resolve **XML do veículo primeiro, depois o arquivo externo**; `"-"` significa nil;
  - o catálogo fica em `g_wheelManager` (`data/shared/wheels/wheels.xml`).
- Rodas duplas (`additionalWheel(i)`) somam massa e `maxLat/LongStiffness`. `physics.width` continua sendo a largura de um pneu só; a largura efetiva está em `physics.wheelShapeWidth`.
- Esteiras (`Crawlers.lua:225`) são apenas visuais sobre rodas comuns.
- Atrito: `WheelsUtil.getTireFriction(tireType, groundType, wet, snow)`, com coeficientes em `WheelsUtil.lua:70-183` (tipos mud, offRoad, street, crawler, chains, metalSpikes).

**Massa — `vehicles/Vehicle.lua`**
- `component.defaultMass = #mass/1000` (t) (`:2730-2745`).
- `updateMass()` (`:2490`) soma a massa adicional (carga, implementos, cintas).
- `getTotalMass(onlyGivenVehicle)` (`:2551`) soma `getComponentMass`, e `Wheels:getComponentMass` inclui `wheel:getMass()`.
- `getDefaultMass()` devolve só a soma dos componentes.
- Lastro por configuração: `VehicleConfigurationDataAdditionalMass.lua` (`<config>.component(?)#node/#additionalMass(kg)/#additionalMassNode`).
- `objectChange` de massa → `setMass` e `defaultMass = v/1000` (`utils/ObjectChangeUtil.lua:172-182`).
- `massScale` não existe [V].
- Na loja, `Vehicle.getSpecValueWeight` com o preview já chama `updateMass(); getTotalMass(true)`.
- Unidade de potência: `P[kW] = T[kN·m] · rpm · π/30`, com T = `torque × torqueScale`. Isso vale nas fixtures: ex. Ford AUTOMATICO `0.85·0.88 kN·m @ 0.86·2200 rpm ≈ 148 kW ≈ 199 cv`.

**Configurações — `configurations/ConfigurationManager.lua`, `shop/StoreManager.lua:803-808`**
- Estrutura no storeItem:
  - `storeItem.configurations[name] = {items com .index,.name,.price,.isDefault,.power,.maxSpeed,…}`;
  - `storeItem.defaultConfigurationIds`;
  - `storeItem.configurationSets`.
- Utilitários: `ConfigurationUtil.getConfigItemByConfigId`, `getXMLConfigurationKey`.
- `g_vehicleConfigurationManager:addConfigurationType(...)` registra tipos (ex. motor em `Motorized.lua:9`).

**Ambiente de mod — `mods.lua:431-462, 980`, `main.lua:30-31`**
- Cada mod roda em `_G[modName]` com `__index=_G`. Globais do mod ficam no env dele; classes do jogo são as tabelas reais.
- O mod tem `g_i18n` próprio.
- Detecção de mods: `g_modIsLoaded[modName]`.
- `descVersion` aceito: 90 a **111** (jogo 1.21.1.0).
- Hooks (`utils/Utils.lua:451-475`):
  - `appendedFunction` roda o original e depois o novo;
  - `prependedFunction` roda o novo e depois o original;
  - `overwrittenFunction` chama `new(self, old, ...)`.

### Reference Implementations
**FS25_EnhancedVehicle**
- Repo [ZhooL/FS25_EnhancedVehicle](https://github.com/ZhooL/FS25_EnhancedVehicle) @ `cd80bd265e2a583e1a0b79f1a55beda523ceb7b2`, v1.1.7.1, arquivado.
- Licença CC BY-NC-SA 4.0 declarada em `README.md:91-92` e `FS25_EnhancedVehicle.lua:63`; não há arquivo LICENSE.
- Serve como referência, **não copiar código**.
- Bootstrap (`FS25_EnhancedVehicle_Loader.lua:13-52`):
  - captura dir/name no momento do source;
  - hooks `Mission00.load` (prepend), `Mission00.loadMission00Finished` (append), `FSBaseMission.delete` (append) e `TypeManager.validateTypes` (prepend, filtrando `types.typeName=='vehicle'`).
- Specialization (`FS25_EnhancedVehicle.lua:240-261`):
  - `g_specializationManager:addSpecialization(name, className, file)`;
  - loop em `g_vehicleTypeManager.types` com `SpecializationUtil.hasSpecialization(Drivable/Enterable/Motorized)`, seguido de `vehicleTypeManager:addSpecialization(typeName, modName.."."..name)`;
  - a tabela gerada é `vehicle["spec_"..modName.."."..name]`.
  - **Não é necessária para a loja**: o preview já tem `spec_motorized`. Só vale se o mod mostrar dados in-world ou no HUD.
- Armadilha: o arquivo da spec é carregado 2× (pelo loader e por `addSpecialization`), então overrides no escopo do arquivo rodam duas vezes.
- Leitura de diferenciais (`:556-571`): `self.spec_motorized.differentials[].{diffIndex1, diffIndex1IsWheel, torqueRatio, maxSpeedRatio}`. Só no servidor.
- UI:
  - HUD com `Class(X, HUDDisplayElement)` e `Overlay`, em append em `mission.hud.drawControlledEntityHUD`;
  - diálogo via `g_gui:loadGui(xml, name, instance)`.
- Config em `modSettings/<name>/<name>_v<ver>.xml` com a API legada `loadXMLFile`. O SSS usa `XMLFile`, que é preferível.
- Logging por `print` com um nível global `debug`. O Logger do SSS é superior.

**Additional Vehicle Info**
- `FS25_additionalVehicleInfo`, Helfer B., v1.0.0.0, 02/09/2026, `descVersion 111`, MP.
- [ModHub](https://farming-simulator.com/mod.php?mod_id=372725&title=fs2025). O zip exige User-Agent e Referer; a cópia analisada está no scratchpad desta sessão.
- Detecção: `g_modIsLoaded["FS25_additionalVehicleInfo"]` (atenção ao "a" minúsculo). O global `AVI` fica em `_G["FS25_additionalVehicleInfo"].AVI` [I].
- Hooks (`src/main.lua`):
  - `PlayerHUDUpdater.showVehicleInfo` sobrescrito guardando o original (`:722-729`);
  - `InGameMenuSettingsFrame.onFrameOpen` e `FocusManager.setGui` para a página de settings (`:182-300`, ids `avi_sectionHeader`, `<controlId>Box`, guarda `page.AVI_menuInjected`).
- **Não toca `ShopConfigScreen`, `processAttributeData` nem `addSpecType`** [V].
- Lê `storeItem.specs.*` e `storeItem.configurations.motor[i].{power,maxSpeed}`, e chama `StoreItemUtil.loadSpecsFromXML` a cada exibição do HUD (`:323-331`). Qualquer `loadFunc` de spec type nosso precisa ser idempotente e barato.
- Esconde linhas do HUD pelo texto localizado: `shop_neededPower`, `shop_workingWidth`, `infohud_mass` e outros. Se nosso mod adicionar linhas no HUD, usar rótulos próprios.
- Sem API pública e sem dependências no modDesc.

### Libraries & Dependencies
Nenhuma dependência de runtime. Dev: Lua 5.1 (hererocks), busted, luacheck, stylua e Python 3.11. É a mesma toolchain do SSS (`tools/setup_dev.sh`, `.github/workflows/ci.yml`).

## Fixtures de validação (requisitos §20/§21)

Todas as referências relevantes para desempenho são **locais ao mod**. Os `$data` usados são só visuais e de som. A massa dos componentes está em kg e a das rodas em t. O "(calc)" é potência calculada por `torqueScale × curva × rpm`.

| | Ford 8030 `FS25-mods/FS25_Ford_8030_jonilson/7630.xml` | Volvo FH 2012 `corrigindo/FS25_VolvoFH12antiga/VolvoFH.xml` | Valtra BH180 `corrigindo/FS25_Valtra_BH180_Dentinho/Valtra_BH180.xml` |
|---|---|---|---|
| tipo | `tractor` (l.2) | `tractor` (l.2), categoria `trucks` | `Valtra` (tipo custom no modDesc, parent tractor) |
| storeData power/maxSpeed | 150 / 31 (l.8-9) | 420 / 85 | 180 / 52 |
| componentes | 2200 + 1750 = 3950 kg (l.29-30) | 10527 + 1092 + 1092 = 12711 kg (l.33-35) | 6508 + 2621 = 9129 kg |
| massa por config | design "420": `objectChange massActive="3949"` + `centerOfMassActive` (l.73-78); rodas `R42_axioBib.xml` configs `dual`/`dualweight` com `<additional mass="1"/>` | nenhuma | nenhuma |
| motorConfigurations | AUTOMATICO hp200 (CVT, ratios 15.6–250, calc ≈199 cv); CAIXA MANUAL hp250 (POWERSHIFT L0.5/H1.0, 4 gears só `maxSpeed`, calc ≈252 cv) (l.605-637) | "FH 420" **sem `hp`**, torqueScale 1.789, CVT 10–150, calc ≈418 cv (l.358-367) | 5 configs; só "BH 145" completa (6 gears, POWERSHIFT A-D); as outras 4 só `torqueScale` e herdam o resto de config(0) (l.471-527); "BH 180" calc ≈162 cv ≠ hp180 |
| diferenciais | 3 entradas 0.5/1.8: rodas 1-2, 3-4, diffs 1-2 (4x4) (l.591-602) | 4 configs: "6x2" / "6x2 II" (rodas 3-4), "6x4" / "6x4 II" (rodas 5-6 + 3-4 + diffs 1-2), escolhidas por `wheels#differentialIndex` (l.144/170, l.375-400) | igual ao Ford |
| rodas | 9 configs, 4 rodas; duals via `additionalWheel` (+`configId`), pé-de-pato, gaiola (l.163-451) | 2 configs, 6 rodas; **overrides de physics no XML do veículo** sobre o arquivo (r 0.50 vs 0.537, frictionScale) | 9 configs; linha 234 com XML malformado (`"0.50"widthAndDiam=`) |
| defeitos | — | — | `Agriculte.xml` declarado no modDesc mas inexistente; `sounds/sound_MF.xml` inexistente |

Implicações para o parser offline:
1. Mesclar a physics do arquivo de roda com o override do veículo.
2. Fazer fallback de motor e transmissão para config(0).
3. Tratar `objectChange massActive` e `<additional mass>` pelo `configId`.
4. Selecionar o diferencial pela configuração de rodas.
5. Calcular hp quando o atributo estiver ausente.
6. Tolerar XML inválido.

Em runtime o próprio jogo já resolve os itens 1 a 5.

## Historical Context
- Projeto novo. Não há specs nem git.
- O SSS registra decisões reaproveitáveis em `docs/adr/0001-0015`:
  - clean-room (0001);
  - hexagonal (0002);
  - HookRegistry (0003);
  - sem dados no savegame (0009);
  - só no cliente (0010);
  - global único (0011);
  - core offline primeiro (0013).
- O SSS também mantém um template de validação in-game em `docs/api-findings/TEMPLATE.md` e um checklist de release e do ModHub em `docs/release-checklist.md`.
- Requisitos §13: a consulta de 27/09/2026 confirmou que o EnhancedVehicle está arquivado. O último commit é "Update README to reflect project conclusion", de 09/08/2026.

## Constraints & Considerations
- **Lua 5.1 no sandbox do jogo.** `g_currentModDirectory` só é válido durante o source. Não há `io` nem `require` no mod publicado.
- **Mods com script são só para PC.** Isso está alinhado com a plataforma dos requisitos.
- **O preview só existe na `ShopConfigScreen`.** A lista da loja (`ShopController:makeDisplayItem`) não tem instância de veículo; lá só existem `storeItem.specs` via spec types e, portanto, parsing XML.
- **O preview é recriado a cada troca de configuração.** O hook `registerCustomSpecValues` já roda exatamente nesse momento, o que satisfaz os requisitos §5, §10 e §16 sem polling.
- **Chave de cache:** `xmlFilename + configurations serializadas`, sem guardar referência ao veículo.
- **`processAttributeData` roda para cada item de bundle** (`storeItems`). Nesse caso, `vehicle` pode ser um só e `self.previewVehicles[i]` vários.
- **Dano reduz torque** (`getTorqueCurveValue`). Na loja o dano deve ser 0, mas para métricas estáticas é mais seguro ler `torqueCurve`/`peakMotorPower` diretamente.
- **`peakMotorPower` está em kW**, e `storeItem power` é o hp declarado. Essa é a base da distinção declarado × calculado × estimado dos requisitos §6.
- **Linhas da tela de config são ícone + texto.** Não há rótulo nem cabeçalho de seção nativos. A "seção DESEMPENHO" dos requisitos §10 exigiria GUI própria (clonar `attributeItem` ou um layout novo), o que é mais frágil.
- **Spec types precisam ser registrados antes do cache de specs** (source ou `loadMap`). Qualquer `loadFunc` pode rodar fora da loja (o AVI chama `loadSpecsFromXML` no HUD).
- **Dedicated server:** não instalar GUI. Multiplayer: análise só no cliente, sem eventos de rede.
- **Licenças:** EnhancedVehicle é CC BY-NC-SA e o AVI não tem licença declarada. Nenhum código dos dois deve ser copiado, e a fonte do jogo (dataS) também não pode ser redistribuída. O SSS é MIT e do mesmo autor, então pode ser reaproveitado.
- **dataS decompilado tem literais corrompidos.** Confirmar caminhos XML e nomes no LUADOC e in-game.

## Open Questions
1. **Qual "Additional Vehicle Info"?** O mod FS25 encontrado (Helfer B., `FS25_additionalVehicleInfo`) atua só no HUD in-world, não na loja. Três possibilidades:
   - o alvo é outro mod (outro autor, ou um port do FS22 que adiciona dados na loja);
   - a compatibilidade dos requisitos §11 se reduz a coexistência;
   - o Vehicle Performance também exibirá dados no HUD in-world, e nesse caso precisa evitar duplicar as linhas do AVI.
2. **Onde exibir:** apenas na tela de configuração, via `registerCustomSpecValues` (robusto, mas só ícone + texto, sem seção nem rótulo)? Ou numa seção própria com cabeçalho "DESEMPENHO", que exige GUI custom e é mais frágil? Também exibir na lista da loja via `addSpecType`, o que exige parsing XML sem preview?
3. **Estratégia de dados:** runtime via preview (recomendação que emerge da pesquisa) como fonte primária, e o parser XML só para testes offline e para a lista da loja? Ou o parser XML completo desde o início, como descrevem os requisitos §4?
4. **Fixtures offline:** gerar os fixtures por dump runtime in-game (console command que serializa o `VehiclePerformanceData` do preview) ou por parser XML dos 3 mods? A opção de dump exige rodar o jogo cedo.
5. **Fórmulas dos índices** (requisitos §7): quais variáveis e normalizações para força de tração estimada, desempenho sob carga e índice de puxada? Isso exige definição matemática antes do /spec, conforme requisitos §7.4.
6. **Licença do projeto:** MIT como o SSS? Nome do global único e prefixo de l10n (sugestão: `VehiclePerformance` e `vp_`)?
7. **descVersion:** usar 111 (máximo aceito no 1.21.1.0, igual ao AVI) ou o mínimo compatível com versões anteriores do jogo?
8. **Specialization própria:** necessária? Só se houver exibição in-world ou HUD, ou uma API `getPerformance(vehicle)` para veículos no mundo, cujos diferenciais só existem no servidor.
9. **Fixtures defeituosos:** o Valtra tem XML malformado na l.234 e arquivos declarados que não existem. Ele deve ficar na suíte como caso "XML válido porém não convencional", ou ser corrigido antes?

## Code References Index
- `requisitos.md` — requisitos v1 (única fonte do projeto)
- `../SmartShopSearch/src/main.lua:1-20` — bootstrap com global único e manifest
- `../SmartShopSearch/src/adapters/HookRegistry.lua:12-60` — registro de hooks com pcall e auto-desativação
- `../SmartShopSearch/src/app/SafeCall.lua:5-20` — pcall com contagem e degradação
- `../SmartShopSearch/src/app/StateMachine.lua:5-11` — estados do mod
- `../SmartShopSearch/src/adapters/GameLogger.lua:33-79` — logger com níveis e rate-limit
- `../SmartShopSearch/src/adapters/SettingsStore.lua:7-24` — settings em modSettings
- `../SmartShopSearch/src/adapters/GameBootstrap.lua:46-138` — loadMap, dedicated e console
- `../SmartShopSearch/Makefile:1-21`, `tools/build.py:46-111`, `tools/check_deps.py` — tooling
- `../SmartShopSearch/docs/adr/`, `docs/api-findings/TEMPLATE.md`, `docs/release-checklist.md` — decisões e checklists
- dataS `gui/ShopConfigScreen.lua:456` processAttributeData · `:759` chamada do hook · `:773` hook vazio · `:858/877` loadCurrentConfiguration/forceServer · `:889/907` onVehiclesLoaded · `:1139` setStoreItem · `:1723-1729` troca de opção
- dataS `shop/StoreManager.lua:414` addSpecType · `:803-808` configurations do storeItem · `shop/StoreItemUtil.lua:177` loadSpecsFromXML
- dataS `vehicles/specializations/Motorized.lua:10-16` spec types · `:1156-1203` diferenciais · `:1205-1343` loadMotor · `:1356/1419` gears/groups · `:3057/3091` maxSpeed
- dataS `vehicles/VehicleMotor.lua:31` new · `:357-369` getters · `:719` velocidade física · `:1889` multiplicador de grupo
- dataS `vehicles/Vehicle.lua:2490` updateMass · `:2551` getTotalMass · `:2730-2745` massa dos componentes · `:3695` getSpecValueWeight
- dataS `vehicles/specializations/Wheels.lua:298` differentialIndex da configuração de rodas · `vehicles/WheelsUtil.lua:70-183` atrito por tipo de pneu
- dataS `utils/ObjectChangeUtil.lua:172-182` massa via objectChange · `utils/Utils.lua:451-475` hooks · `mods.lua:431-462,980` env e g_modIsLoaded · `main.lua:30-31` descVersion
- EnhancedVehicle `FS25_EnhancedVehicle_Loader.lua:13-52` bootstrap · `FS25_EnhancedVehicle.lua:240-261` specialization · `:556-571` differentials
- AVI `src/main.lua:722-729` hook do HUD · `:323-331` loadSpecsFromXML · `:182-300` settings
- Fixtures: `FS25-mods/FS25_Ford_8030_jonilson/7630.xml:29-30,73-78,591-637` · `corrigindo/FS25_VolvoFH12antiga/VolvoFH.xml:33-35,144,170,358-400` · `corrigindo/FS25_Valtra_BH180_Dentinho/Valtra_BH180.xml:471-527`
