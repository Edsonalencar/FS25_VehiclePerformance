-- Índice dos dumps golden da Fase 3 (ids, invariantes de consistência entre
-- veículos). Os arquivos .xml correspondentes (tests/fixtures/dumps/<id>.xml,
-- um por id abaixo) AINDA NÃO EXISTEM neste ambiente de desenvolvimento: não
-- há Farming Simulator 25 instalado aqui para rodar `vpDump` de verdade (ver
-- specs/plans/2026-09-27-fs25-vehicle-performance-1.0.md, Fase 3, seção
-- "Coleta in-game"). A estrutura abaixo é a mesma do spec, pronta para quando
-- alguém com o jogo gerar os dumps reais, copiá-los para
-- tests/fixtures/dumps/<id>.xml e rodar `make golden-update`. Ver também
-- docs/api-findings/2026-09-28-runtime.md.
return {
    ids = {
        "ford_auto_largo",
        "ford_auto_largo_ballast",
        "ford_manual_dual",
        "valtra_145",
        "valtra_180",
        "valtra_205",
        "volvo_ferro",
        "volvo_alcoa",
        "base_2wd",
        "base_crawler",
        "base_truck",
    },
    greater = { -- {métrica, maior, menor}
        { "tractionForceKn", "valtra_205", "valtra_145" },
        { "tractionForceKn", "volvo_alcoa", "volvo_ferro" },
        { "massT", "ford_auto_largo_ballast", "ford_auto_largo" },
        { "adhesionForceKn", "ford_auto_largo_ballast", "ford_auto_largo" },
        { "peakPowerKw", "valtra_180", "valtra_145" },
    },
    drivetrain = { volvo_ferro = "6x2", volvo_alcoa = "6x4", ford_auto_largo = "4x4", base_2wd = "4x2" },
}
