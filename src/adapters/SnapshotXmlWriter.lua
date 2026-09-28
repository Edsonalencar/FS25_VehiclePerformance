-- Grava um Snapshot (RuntimeVehicleReader.read) em XML, em
-- modSettings/FS25_VehiclePerformance/dumps/. Vira fixture golden depois de
-- copiado para tests/fixtures/dumps/ (ver tests/support/dump_loader.lua e
-- tools/golden.lua). Usa NS.core.Flatten.flatten (Fase 2) e NS.core.Hash.djb2
-- e NS.app.ConfigurationResolver.key (Fase 3) só em runtime: este arquivo
-- resolve os nomes em tempo de execução, então compila mesmo que o core ainda
-- não exista neste checkout (ver nota da Fase 3 no spec).
local NS = VehiclePerformance
local SnapshotXmlWriter = {}

--- Grava snapshot em XML e devolve o caminho gravado, ou nil em falha (com
--- log DEBUG). Nunca lança erro: uma falha de escrita não deve derrubar
--- vpDump para os demais veículos do preview.
function SnapshotXmlWriter.write(snapshot, logger)
    local ok, result = pcall(function()
        local dir = (g_modSettingsDirectory or "") .. "FS25_VehiclePerformance/dumps/"
        local xmlFilename = (snapshot.identity and snapshot.identity.xmlFilename) or "unknown"
        local base = xmlFilename:match("([^/\\]+)%.xml$") or "unknown"
        local key = NS.app.ConfigurationResolver.key(snapshot)
        local hash = NS.core.Hash.djb2(key)
        local path = string.format("%s%s_%s.xml", dir, base, hash)

        pcall(createFolder, dir)

        local xmlFile = XMLFile.create("VPSnapshot", path, "vpSnapshot")
        if not xmlFile then
            error("XMLFile.create falhou para " .. path)
        end
        xmlFile:setInt("vpSnapshot#schema", 1)
        for i, e in ipairs(NS.core.Flatten.flatten(snapshot)) do
            local entryKey = string.format("vpSnapshot.v(%d)", i - 1)
            xmlFile:setString(entryKey .. "#k", e.k)
            xmlFile:setString(entryKey .. "#t", e.t)
            xmlFile:setString(entryKey .. "#v", e.t == "n" and string.format("%.17g", e.v) or tostring(e.v))
        end
        xmlFile:save()
        xmlFile:delete()
        return path
    end)
    if not ok then
        if logger then
            logger:debug("writer", "falha ao gravar snapshot: %s", tostring(result))
        end
        return nil
    end
    return result
end

NS.adapters.SnapshotXmlWriter = SnapshotXmlWriter
