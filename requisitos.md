# Requisitos --- FS25 Vehicle Performance

**Status:** Documento inicial de requisitos\
**Plataforma:** Farming Simulator 25 (PC)\
**Tipo:** Mod independente de análise e apresentação de desempenho de
veículos\
**Projeto relacionado:** FS25 Smart Shop Search\
**Objetivo de qualidade:** arquitetura modular, compatibilidade com
outros mods e preparação para os padrões de publicação do ModHub.

------------------------------------------------------------------------

## 1. Visão geral

O **FS25 Vehicle Performance** será um mod independente para Farming
Simulator 25 cujo objetivo é enriquecer a listagem e a visualização de
veículos na loja com informações técnicas e métricas de desempenho que
não são apresentadas diretamente pelo jogo.

O mod deverá interpretar dados reais da configuração dos veículos,
incluindo motor, curva de torque, transmissão, massa, diferenciais,
rodas e configurações selecionáveis, transformando esses dados em
informações compreensíveis e comparáveis.

O projeto **não faz parte do FS25 Smart Shop Search**. Os dois mods
deverão permanecer independentes, ainda que futuramente possam
interoperar por interfaces públicas e opcionais.

------------------------------------------------------------------------

## 2. Objetivos

O mod deverá:

1.  Exibir informações técnicas adicionais na loja do FS25.
2.  Calcular métricas derivadas de desempenho a partir dos dados reais
    do veículo.
3.  Permitir que o jogador compare melhor tratores, caminhões e demais
    veículos motorizados.
4.  Refletir alterações provocadas pelas configurações escolhidas na
    loja.
5.  Diferenciar potência anunciada de características efetivas
    relacionadas à tração e desempenho sob carga.
6.  Funcionar com veículos nativos e veículos adicionados por mods,
    sempre que seus dados puderem ser interpretados.
7.  Integrar-se de maneira segura com outros mods que alterem ou ampliem
    a interface da loja.
8.  Ter compatibilidade explícita com **Additional Vehicle Info**.
9.  Manter o núcleo de análise separado da camada de apresentação.
10. Degradar de forma segura quando um parâmetro não puder ser
    determinado.

------------------------------------------------------------------------

## 3. Fora de escopo

Nesta fase, o FS25 Vehicle Performance não deverá:

-   substituir o sistema de física do Farming Simulator 25;
-   modificar artificialmente potência, torque, transmissão ou aderência
    dos veículos;
-   atuar como mod de tuning ou upgrade de performance;
-   substituir o Additional Vehicle Info;
-   depender obrigatoriamente do Additional Vehicle Info;
-   depender obrigatoriamente do FS25 Smart Shop Search;
-   modificar arquivos de outros mods;
-   alterar permanentemente XMLs de veículos de terceiros.

O objetivo é **analisar, calcular e apresentar informações**, e não
alterar a física original do veículo.

------------------------------------------------------------------------

## 4. Fonte dos dados

O mod deverá obter informações a partir das estruturas carregadas pelo
próprio FS25 e/ou dos dados XML disponíveis ao veículo.

Entre os parâmetros relevantes estão:

### 4.1 Dados básicos

-   nome;
-   marca;
-   categoria;
-   preço;
-   potência informada;
-   velocidade máxima;
-   tipo do veículo.

### 4.2 Massa e distribuição

O analisador deverá considerar:

-   massa dos componentes;
-   soma das massas;
-   centro de massa quando disponível;
-   alterações de massa causadas por configurações;
-   lastros;
-   pesos adicionais;
-   alterações de massa por `objectChange` ou mecanismo equivalente
    suportado pelo jogo.

A massa utilizada nos cálculos deverá corresponder, sempre que
tecnicamente possível, à configuração efetivamente selecionada.

### 4.3 Motor

Deverão ser analisados, quando disponíveis:

-   potência;
-   `torqueScale`;
-   RPM mínimo;
-   RPM máximo;
-   curva de torque;
-   pontos `normRpm`;
-   valores relativos de torque;
-   velocidade máxima associada ao motor;
-   diferentes `motorConfigurations`.

O sistema não deverá assumir que a potência exibida em `storeData`
descreve todas as configurações disponíveis.

### 4.4 Transmissão

Deverão ser considerados:

-   relações mínima e máxima;
-   marchas;
-   grupos;
-   velocidades máximas por marcha;
-   direção;
-   configurações automáticas;
-   configurações manuais;
-   powershift e outros tipos reconhecidos pelo FS25;
-   diferentes transmissões associadas às configurações de motor.

### 4.5 Tração e diferenciais

O sistema deverá identificar, quando possível:

-   rodas motrizes;
-   quantidade de eixos motrizes;
-   diferenciais;
-   `torqueRatio`;
-   `maxSpeedRatio`;
-   diferenciais entre rodas;
-   diferenciais entre eixos;
-   configurações como 4x2, 4x4, 6x2, 6x4, 6x6 ou equivalentes
    inferíveis com segurança.

Quando a configuração não puder ser determinada de forma confiável, o
mod deverá informar que o dado é desconhecido em vez de inventar uma
classificação.

### 4.6 Rodas, pneus e esteiras

O analisador deverá considerar:

-   `wheelConfigurations`;
-   arquivos XML externos de rodas;
-   rodas adicionais;
-   pneus duplos;
-   largura;
-   raio;
-   parâmetros físicos;
-   `frictionScale` quando disponível;
-   `restLoad`;
-   `forcePointRatio`;
-   configurações especiais;
-   esteiras, quando aplicável.

O parser deverá conseguir seguir referências para arquivos XML
auxiliares quando isso for necessário e seguro.

------------------------------------------------------------------------

## 5. Configurações do veículo

Um veículo não deverá ser representado internamente como possuidor de
uma única especificação imutável.

O modelo deverá considerar:

`Veículo + configuração de motor + transmissão + rodas + lastro + demais configurações relevantes`

como uma configuração técnica específica.

Mudanças feitas pelo jogador na loja deverão provocar a atualização das
métricas afetadas.

### Exemplo conceitual

Um mesmo trator poderá apresentar resultados diferentes para:

-   200 cv automático + pneus simples + sem lastro;
-   250 cv manual + pneus duplos + peso frontal.

As métricas exibidas deverão corresponder à configuração atualmente
selecionada.

------------------------------------------------------------------------

## 6. Métricas objetivas

Sempre que os dados permitirem, deverão ser exibidas grandezas objetivas
antes dos índices derivados.

Exemplos:

-   potência;
-   massa;
-   relação peso/potência;
-   faixa de RPM;
-   característica da transmissão;
-   configuração de tração;
-   número de eixos motrizes;
-   configuração de pneus;
-   torque calculável/estimável;
-   força de tração calculável/estimável.

O sistema deverá distinguir visualmente valores:

-   **declarados** pelo veículo;
-   **calculados** matematicamente;
-   **estimados** pelo modelo do mod.

------------------------------------------------------------------------

## 7. Índices de desempenho

O mod deverá possuir uma camada específica para métricas derivadas.

Os índices iniciais a serem estudados incluem:

### 7.1 Índice de Puxada / Tração

Representará a capacidade estimada do veículo de transformar o
desempenho do conjunto motriz em força utilizável para deslocar carga.

Deverá considerar, conforme disponibilidade e validade física:

-   torque;
-   curva de torque;
-   transmissão;
-   relação efetiva;
-   raio das rodas;
-   massa;
-   distribuição sobre rodas motrizes;
-   diferenciais;
-   configuração de tração;
-   pneus/esteiras;
-   parâmetros de aderência expostos pelo FS25.

### 7.2 Relação peso/potência

Deverá apresentar uma medida objetiva e compreensível da relação entre
massa e potência.

### 7.3 Desempenho sob carga

Deverá representar a capacidade estimada de manter trabalho/movimento
sob carga, sem ser confundido com força máxima de tração.

### 7.4 Regra contra índices arbitrários

Nenhum índice de 0--100 deverá ser publicado como métrica final sem:

1.  definição matemática documentada;
2.  identificação das variáveis utilizadas;
3.  justificativa dos pesos ou normalizações;
4.  testes com veículos representativos;
5.  validação de comportamento relativo;
6.  tratamento de dados ausentes;
7.  diferenciação clara entre medida física e índice heurístico.

------------------------------------------------------------------------

## 8. Arquitetura

O núcleo de cálculo deverá ser independente da interface.

Estrutura conceitual:

``` text
VehiclePerformance
│
├── Core
│   ├── VehicleAnalyzer
│   ├── ConfigurationResolver
│   └── PerformanceData
│
├── Analyzers
│   ├── MotorAnalyzer
│   ├── TransmissionAnalyzer
│   ├── MassAnalyzer
│   ├── TractionAnalyzer
│   ├── DifferentialAnalyzer
│   └── WheelAnalyzer
│
├── Metrics
│   ├── PowerToWeightMetric
│   ├── PullingPerformanceMetric
│   ├── TractionMetric
│   └── LoadPerformanceMetric
│
├── Compatibility
│   └── AdditionalVehicleInfoAdapter
│
└── UI
    ├── VanillaShopAdapter
    └── PerformanceSection
```

A UI não deverá realizar cálculos físicos diretamente.

------------------------------------------------------------------------

## 9. Modelo interno de dados

O núcleo deverá produzir uma representação normalizada semelhante a:

``` text
VehiclePerformanceData
├── identity
├── configuration
├── engine
├── transmission
├── mass
├── drivetrain
├── wheels
├── objectiveMetrics
├── derivedMetrics
└── confidence / availability
```

A camada de UI deverá consumir esse modelo sem precisar conhecer a
origem específica dos dados.

------------------------------------------------------------------------

## 10. Integração com a loja do FS25

O mod deverá adicionar informações à experiência de compra sem
prejudicar a navegação original.

### Requisitos

-   funcionar na interface padrão;
-   atualizar os dados quando o veículo selecionado mudar;
-   atualizar os dados quando uma configuração relevante mudar;
-   evitar sobreposição visual;
-   respeitar resolução e escala da UI;
-   manter textos localizáveis;
-   não bloquear a compra;
-   não alterar preço ou configuração do veículo;
-   não exigir interação adicional para informações essenciais;
-   permitir expansão futura da seção de desempenho.

Exemplo conceitual:

``` text
INFORMAÇÕES DO VEÍCULO
────────────────────────────
Potência                  250 cv
Peso                     4,37 t
Velocidade máxima        40 km/h

DESEMPENHO
────────────────────────────
Tração                       4x4
Relação peso/potência        ...
Força de tração estimada     ...
Desempenho sob carga         ...
Índice de puxada             ...
```

------------------------------------------------------------------------

## 11. Compatibilidade com Additional Vehicle Info

A coexistência com **Additional Vehicle Info** é requisito obrigatório.

### 11.1 Sem Additional Vehicle Info

O FS25 Vehicle Performance deverá funcionar de forma autônoma e
apresentar sua própria seção de desempenho.

### 11.2 Com Additional Vehicle Info

Quando Additional Vehicle Info estiver instalado:

-   o mod deverá detectar sua presença de forma segura;
-   não deverá duplicar desnecessariamente informações já apresentadas;
-   não deverá sobrescrever arquivos ou estruturas do outro mod;
-   não deverá exigir alterações no Additional Vehicle Info;
-   deverá evitar conflitos de hooks;
-   deverá evitar sobreposição de elementos;
-   deverá preservar as funcionalidades dos dois mods;
-   poderá utilizar pontos de extensão públicos/seguros caso existam;
-   deverá possuir fallback para sua própria apresentação caso a
    integração específica deixe de funcionar.

### 11.3 Adapter

A integração deverá ficar isolada em uma camada equivalente a:

`AdditionalVehicleInfoAdapter`

Alterações internas do Additional Vehicle Info não deverão exigir
mudanças no núcleo de cálculo.

### 11.4 Falha segura

Caso uma versão futura do Additional Vehicle Info seja incompatível com
o adapter:

1.  o erro deverá ser tratado;
2.  o núcleo do Vehicle Performance deverá continuar funcional;
3.  a integração específica deverá ser desativada;
4.  a loja não deverá quebrar;
5.  uma mensagem adequada poderá ser registrada no log.

------------------------------------------------------------------------

## 12. Compatibilidade com mods de veículos

O sistema deverá priorizar compatibilidade genérica.

Não deverão existir regras codificadas especificamente para um veículo
sempre que for possível interpretar a estrutura padrão do FS25.

O analisador deverá tolerar:

-   parâmetros opcionais;
-   configurações múltiplas;
-   referências externas;
-   valores ausentes;
-   veículos com XMLs extensos;
-   configurações personalizadas compatíveis com o sistema do jogo.

Valores ausentes não deverão provocar erro fatal.

------------------------------------------------------------------------

## 13. Infraestrutura open source de referência

### FS25_EnhancedVehicle

Repositório:

**https://github.com/ZhooL/FS25_EnhancedVehicle**

O projeto será utilizado como **referência técnica e possível base de
padrões de infraestrutura FS25**, especialmente para estudar:

-   bootstrap/loader de um mod script;
-   carregamento de arquivos Lua;
-   registro de specialization;
-   aplicação de specialization a veículos `Drivable`, `Enterable` e
    `Motorized`;
-   acesso a `spec_motorized`;
-   leitura de diferenciais em runtime;
-   estruturas de eventos;
-   UI/HUD;
-   configuração;
-   organização de scripts;
-   integração com veículos existentes sem editar individualmente seus
    XMLs.

O repositório demonstra, entre outros pontos, registro de uma
specialization própria e sua aplicação aos tipos de veículos motorizados
compatíveis. Também acessa `self.spec_motorized.differentials` para
trabalhar com informações como `torqueRatio` e `maxSpeedRatio`.

### Situação do projeto de referência

Na consulta realizada em 27/09/2026, o repositório estava
arquivado/read-only e o desenvolvimento havia sido encerrado pelo autor.

Portanto:

-   não deverá ser tratado como dependência externa ativa;
-   o Vehicle Performance deverá possuir seu próprio código e ciclo de
    manutenção;
-   padrões úteis poderão ser estudados e reimplementados quando
    apropriado;
-   qualquer reutilização direta de código deverá passar por revisão de
    licença.

### Licença

O FS25_EnhancedVehicle declara licença **Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)** e proíbe
monetização.

Consequentemente, antes de copiar ou derivar diretamente código do
projeto, deverá ser realizada uma decisão explícita sobre
compatibilidade de licença e distribuição.

**Diretriz inicial:** usar o repositório como referência de arquitetura
e infraestrutura; evitar copiar código até que a estratégia de
licenciamento do FS25 Vehicle Performance esteja definida.

------------------------------------------------------------------------

## 14. Independência entre projetos

Deverão permanecer separados:

``` text
FS25 Smart Shop Search
        │
        └── busca, interpretação e descoberta

FS25 Vehicle Performance
        │
        └── análise técnica e apresentação de desempenho
```

Nenhum dos dois deverá ser dependência obrigatória do outro.

No futuro, o Smart Shop Search poderá opcionalmente consultar uma API
pública do Vehicle Performance para buscas como:

-   "trator com maior capacidade de puxada";
-   "caminhão 6x4";
-   "trator acima de determinada relação de desempenho".

Essa interoperabilidade futura não deverá acoplar os núcleos dos
projetos.

------------------------------------------------------------------------

## 15. API interna e extensibilidade

O núcleo deverá ser projetado para permitir uma API pública futura.

Exemplo conceitual:

``` lua
VehiclePerformance:getPerformance(vehicle)
VehiclePerformance:getMetric(vehicle, metricId)
VehiclePerformance:getCurrentConfiguration(vehicle)
```

A assinatura definitiva dependerá da arquitetura real da API do FS25.

Outros mods não deverão precisar acessar diretamente detalhes internos
dos analyzers para obter métricas já calculadas.

------------------------------------------------------------------------

## 16. Cache e desempenho

A análise não deverá executar parsing/cálculos pesados a cada frame.

Deverão ser previstos:

-   cache por veículo;
-   invalidação quando configuração relevante mudar;
-   reaproveitamento de resultados;
-   cálculo sob demanda;
-   separação entre dados estáticos e dinâmicos;
-   proteção contra processamento repetitivo da mesma configuração.

A abertura e navegação da loja não deverão apresentar degradação
perceptível causada pelo mod.

------------------------------------------------------------------------

## 17. Logging e diagnóstico

O mod deverá possuir logging controlável.

Níveis conceituais:

-   ERROR;
-   WARNING;
-   INFO;
-   DEBUG.

Em modo normal, o mod não deverá poluir `log.txt`.

Em modo de diagnóstico, deverá ser possível identificar:

-   veículo analisado;
-   configuração;
-   parâmetros encontrados;
-   parâmetros ausentes;
-   métricas calculadas;
-   adapter de UI utilizado;
-   estado da integração com Additional Vehicle Info;
-   fallback aplicado.

------------------------------------------------------------------------

## 18. Localização

Todo texto visível ao usuário deverá utilizar o sistema de localização
do FS25.

O projeto deverá nascer preparado ao menos para:

-   português brasileiro;
-   inglês.

Nomes técnicos e unidades deverão respeitar as convenções do jogo e da
localização.

------------------------------------------------------------------------

## 19. Critérios de qualidade

Uma versão candidata a publicação deverá:

-   iniciar sem erros Lua;
-   não gerar erros XML;
-   não quebrar a loja padrão;
-   funcionar sem Additional Vehicle Info;
-   coexistir com Additional Vehicle Info;
-   funcionar com veículos nativos;
-   funcionar com uma amostra representativa de veículos de mods;
-   lidar com dados ausentes;
-   atualizar métricas quando configurações relevantes mudarem;
-   evitar cálculos por frame desnecessários;
-   possuir textos localizados;
-   não modificar arquivos de terceiros;
-   não alterar a física do veículo;
-   documentar as fórmulas das métricas derivadas.

------------------------------------------------------------------------

## 20. Testes mínimos

A suíte de validação deverá incluir, no mínimo:

### Veículos

-   trator 2WD;
-   trator 4WD;
-   trator com pneus duplos;
-   trator com esteiras;
-   caminhão 4x2;
-   caminhão 6x2;
-   caminhão 6x4;
-   veículo com múltiplas motorizações;
-   veículo com transmissão manual;
-   veículo com transmissão automática;
-   veículo com lastro configurável;
-   veículo com arquivos externos de rodas.

### Integração

-   jogo sem Additional Vehicle Info;
-   jogo com Additional Vehicle Info;
-   troca rápida entre veículos na loja;
-   mudança de configuração;
-   abertura/fechamento repetido da loja;
-   veículo com parâmetros incompletos;
-   veículo com XML válido porém não convencional.

------------------------------------------------------------------------

## 21. Casos reais iniciais de validação

Os primeiros veículos usados durante a modelagem serão os dois XMLs já
analisados no projeto:

### Volvo FH

Características úteis para validação:

-   potência declarada;
-   múltiplos componentes de massa;
-   curva de torque;
-   `torqueScale`;
-   transmissão;
-   configurações 6x2 e 6x4;
-   diferentes diferenciais;
-   rodas definidas por XML externo.

### Ford / JDP_Ford 8030

Características úteis para validação:

-   potência declarada;
-   múltiplos componentes de massa;
-   peso adicional configurável;
-   múltiplas configurações de rodas;
-   pneus duplos;
-   configurações especiais;
-   tração dianteira/traseira interligada;
-   motor automático;
-   motor/transmissão manual;
-   diferentes potências e `torqueScale`.

Esses casos não deverão gerar regras especiais. Eles servirão como
fixtures/casos de teste para validar a abordagem genérica.

------------------------------------------------------------------------

## 22. Decisões arquiteturais obrigatórias

1.  **Projeto independente do Smart Shop Search.**
2.  **Additional Vehicle Info é compatibilidade obrigatória, não
    dependência.**
3.  **Cálculo separado da UI.**
4.  **Configuração atual do veículo faz parte da identidade técnica
    analisada.**
5.  **Dados ausentes não podem quebrar o mod.**
6.  **Métricas objetivas e estimativas devem ser diferenciadas.**
7.  **Índices heurísticos devem possuir fórmula documentada.**
8.  **Nenhum cálculo pesado deverá ocorrer desnecessariamente por
    frame.**
9.  **Nenhum arquivo de outro mod será modificado.**
10. **FS25_EnhancedVehicle será referência de infraestrutura, sujeito às
    restrições de licença.**

------------------------------------------------------------------------

## 23. Próximas etapas de engenharia

Antes da implementação final, deverão ser produzidos:

1.  levantamento da API/specializations relevantes do FS25;
2.  estudo do fluxo da loja e pontos seguros de extensão;
3.  estudo técnico do Additional Vehicle Info;
4.  inventário dos campos físicos realmente disponíveis em runtime;
5.  modelo normalizado `VehiclePerformanceData`;
6.  definição matemática das métricas;
7.  estratégia para configurações da loja;
8.  arquitetura do adapter de UI;
9.  protótipo técnico de leitura sem interface;
10. testes com os XMLs reais;
11. protótipo da seção de desempenho na loja;
12. matriz de compatibilidade;
13. revisão para requisitos do ModHub.

------------------------------------------------------------------------

## 24. Referências técnicas

-   **FS25_EnhancedVehicle (open source):**
    https://github.com/ZhooL/FS25_EnhancedVehicle
-   **Licença declarada pelo FS25_EnhancedVehicle:** CC BY-NC-SA 4.0
-   **Documentação/API oficial do GIANTS Developer Network:** deverá ser
    a fonte primária para decisões dependentes da API do FS25.
-   **Additional Vehicle Info:** alvo explícito de interoperabilidade;
    sua implementação deverá ser estudada antes da definição final do
    adapter.

------------------------------------------------------------------------

## 25. Princípio do produto

> O FS25 Vehicle Performance não deve dizer apenas quantos cavalos um
> veículo possui. Ele deve explicar, usando os dados que o próprio FS25
> disponibiliza, como aquele conjunto está configurado para transformar
> motor, transmissão, massa e tração em desempenho útil.
