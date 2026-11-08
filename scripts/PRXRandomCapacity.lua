-- Alpaca PRX500: random animal capacity (PropaineX)
-- The server picks a capacity between MIN and MAX when the barn is first built.
-- It is saved with the savegame and sent to multiplayer clients, so it stays the same afterwards.

PRXRandomCapacity = {}
PRXRandomCapacity.MIN = 100
PRXRandomCapacity.MAX = 125
PRXRandomCapacity.SPEC = "spec_" .. g_currentModName .. ".prxRandomCapacity"

function PRXRandomCapacity.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryAnimals, specializations)
end

function PRXRandomCapacity.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getMaxNumOfAnimals", PRXRandomCapacity.getMaxNumOfAnimals)
end

function PRXRandomCapacity.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PRXRandomCapacity)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PRXRandomCapacity)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PRXRandomCapacity)
end

function PRXRandomCapacity.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PRXRandomCapacity")
    schema:register(XMLValueType.INT, basePath .. "#maxNumAnimals", "Randomly picked animal capacity")
    schema:setXMLSpecializationType()
end

function PRXRandomCapacity:onLoad(savegame)
    local spec = self[PRXRandomCapacity.SPEC]
    -- make sure alpacas take the sheep's grass/hay before the barn builds its food list (onPostLoad)
    if PRXAlpacaFood ~= nil then
        PRXAlpacaFood.apply()
    end
    -- new barn: pick now; a saved barn overwrites this in loadFromXMLFile, a client gets it in onReadStream
    spec.maxNumAnimals = math.random(PRXRandomCapacity.MIN, PRXRandomCapacity.MAX)
end

function PRXRandomCapacity:loadFromXMLFile(xmlFile, key)
    local spec = self[PRXRandomCapacity.SPEC]
    local value = xmlFile:getValue(key .. "#maxNumAnimals")
    if value ~= nil then
        spec.maxNumAnimals = math.max(1, value)
    end
end

function PRXRandomCapacity:saveToXMLFile(xmlFile, key, usedModNames)
    local spec = self[PRXRandomCapacity.SPEC]
    xmlFile:setValue(key .. "#maxNumAnimals", spec.maxNumAnimals)
end

function PRXRandomCapacity:onReadStream(streamId, connection)
    local spec = self[PRXRandomCapacity.SPEC]
    spec.maxNumAnimals = streamReadUInt16(streamId)
end

function PRXRandomCapacity:onWriteStream(streamId, connection)
    local spec = self[PRXRandomCapacity.SPEC]
    streamWriteUInt16(streamId, spec.maxNumAnimals)
end

function PRXRandomCapacity:getMaxNumOfAnimals(superFunc)
    local spec = self[PRXRandomCapacity.SPEC]
    if spec ~= nil and spec.maxNumAnimals ~= nil then
        return spec.maxNumAnimals
    end
    return superFunc(self)
end
