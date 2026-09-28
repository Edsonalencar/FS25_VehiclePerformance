# ADR-0007: Mod só de cliente, sem specialization própria, sem rede

## Status
Aceito

## Contexto
O mod só lê dados já resolvidos pelo jogo para exibi-los na tela de
configuração da loja — não altera física, preço, configuração nem estado de
mundo (requisitos §3, "Fora de escopo"). A loja (`ShopConfigScreen`) e o seu
veículo de preview existem só no cliente. Diferenciais só existem
`if self.isServer` (`Motorized.lua`), mas o preview da loja é montado com
`setForceServer(true)` (ADR-0004), então tem dados completos mesmo rodando no
cliente de uma partida multiplayer. Não há necessidade de sincronizar nada
entre cliente e servidor, nem de persistir nada no savegame. Em dedicated
server não existe tela de loja nem jogador local — instalar qualquer GUI ali
seria trabalho sem efeito e risco desnecessário de erro no processo do
servidor.

## Decisão
- O mod não registra specialization própria (`g_specializationManager`) nem
  se anexa a nenhum tipo de veículo — não precisa, porque toda a leitura
  acontece sobre o veículo de preview já instanciado pela `ShopConfigScreen`,
  não sobre veículos no mundo.
- Não há eventos de rede (`Event`, `EventIDs`) nem estado sincronizado — o
  mod não escreve nada, só lê e formata para exibição local.
- Nenhum dado é gravado no savegame; `modSettings/FS25_VehiclePerformance/`
  guarda só preferências do jogador (`ui#*`, `metrics#*`, `debug#*`).
- Em `GameBootstrap:loadMap`, se `g_dedicatedServer ~= nil`, o estado vai
  direto para `"disabled-dedicated"` e nenhum hook é instalado — o mod fica
  completamente inerte no processo do servidor.
- A API pública (`app/PublicApi.lua`) lê sob demanda a partir de um veículo
  passado pelo chamador; não abre conexão nem depende de estado de rede.

## Consequências
- Não há necessidade de lidar com autoridade cliente/servidor, dessincronia
  ou replicação — reduz drasticamente a superfície de bugs possíveis.
- Um cliente MP puro (sem ser host) ainda consegue ver as linhas na loja,
  porque o preview da própria loja já força dados de servidor (ADR-0004);
  fora da loja, um veículo do mundo (ex.: consultado pela API pública por
  outro mod) pode ter `drivetrain` (F6) `"unknown"` num cliente puro, porque
  os diferenciais não seriam replicados para exibição in-world — isso está
  documentado em `docs/FORMULAS.md`/API pública, não é um bug.
- Em dedicated server, o mod não consome memória além do bootstrap mínimo
  (settings + logger + state) e não aparece em nenhum log de erro.
- Esta decisão nunca foi executada dentro do jogo real neste ambiente de
  desenvolvimento; a verificação "MP host/cliente" e "dedicated server" fica
  pendente de teste manual (`docs/release-checklist.md`).
