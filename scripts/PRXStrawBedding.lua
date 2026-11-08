-- Alpaca PRX500: straw bedding (PropaineX)
-- Straw goes into the barn's storage and is used up per day like pigs use straw (no manure):
-- each alpaca uses what a pig of the same age uses per day (read from the game's PIG animal data at runtime).
-- Production follows the bedding level in a straight line: full = 110%, empty = 85%.
-- (e.g. half full = 97.5%)
-- The bonus is added to the hourly output step only; the husbandry's stored production factor stays <= 1
-- (it is streamed to clients as factor * 255 in one byte).

PRXStrawBedding = {}
PRXStrawBedding.SPEC = "spec_" .. g_currentModName .. ".prxStrawBedding"
-- production factor follows the bedding level in a straight line: empty = 85%, full = 110%
PRXStrawBedding.EMPTY_FACTOR = 0.85
PRXStrawBedding.FULL_FACTOR = 1.10

function PRXStrawBedding.getFactor(ratio)
    return PRXStrawBedding.EMPTY_FACTOR + (PRXStrawBedding.FULL_FACTOR - PRXStrawBedding.EMPTY_FACTOR) * ratio
end
PRXStrawBedding.CLIENT_UPDATE_MS = 2000

function PRXStrawBedding.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
end

function PRXStrawBedding.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PRXStrawBedding.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PRXStrawBedding.getConditionInfos)
end

function PRXStrawBedding.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PRXStrawBedding)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PRXStrawBedding)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PRXStrawBedding)
    SpecializationUtil.registerEventListener(placeableType, "onHusbandryAnimalsUpdate", PRXStrawBedding)
end

function PRXStrawBedding.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PRXStrawBedding")
    basePath = basePath .. ".prxStrawBedding"
    FillPlane.registerXMLPaths(schema, basePath .. ".strawPlane")
    schema:setXMLSpecializationType()
end

-- the pig's straw-per-day curve (by age), taken from the first PIG subtype that has one
function PRXStrawBedding.getPigStrawCurve()
    if PRXStrawBedding.pigStrawCurve ~= nil then
        return PRXStrawBedding.pigStrawCurve
    end
    local animalSystem = g_currentMission ~= nil and g_currentMission.animalSystem or nil
    if animalSystem == nil then
        return nil
    end
    local pigType = animalSystem:getTypeByName("PIG")
    if pigType ~= nil and pigType.subTypes ~= nil then
        for _, subTypeIndex in ipairs(pigType.subTypes) do
            local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
            if subType ~= nil and subType.input ~= nil and subType.input.straw ~= nil then
                PRXStrawBedding.pigStrawCurve = subType.input.straw
                return PRXStrawBedding.pigStrawCurve
            end
        end
    end
    if not PRXStrawBedding.warnedNoPig then
        PRXStrawBedding.warnedNoPig = true
        Logging.warning("[Alpaca PRX500] No pig straw usage found; straw bedding will not go down")
    end
    return nil
end

function PRXStrawBedding:onHusbandryAnimalsUpdate(clusters)
    local spec = self[PRXStrawBedding.SPEC]
    spec.litersPerDay = 0
    local curve = PRXStrawBedding.getPigStrawCurve()
    if curve == nil then
        return
    end
    for _, cluster in ipairs(clusters) do
        spec.litersPerDay = spec.litersPerDay + curve:get(cluster:getAge()) * cluster:getNumAnimals()
    end
end

function PRXStrawBedding:onLoad(savegame)
    local spec = self[PRXStrawBedding.SPEC]
    spec.fillType = FillType.STRAW
    spec.litersPerDay = 0
    spec.title = g_i18n:getText("prx_strawBedding", self.customEnvironment)

    spec.strawPlane = FillPlane.new()
    if spec.strawPlane:load(self.components, self.xmlFile, "placeable.prxStrawBedding.strawPlane", self.i3dMappings) then
        spec.strawPlane:setState(0)
    else
        spec.strawPlane:delete()
        spec.strawPlane = nil
    end
    spec.clientTimer = 0
end

function PRXStrawBedding:onFinalizePlacement()
    local spec = self[PRXStrawBedding.SPEC]
    PRXStrawBedding.updateStrawPlane(self)
    -- clients don't run the hourly output step, so they refresh the straw plane from the synced storage themselves
    if not self.isServer and spec.strawPlane ~= nil then
        spec.updateable = {
            update = function(_, dt)
                spec.clientTimer = spec.clientTimer + dt
                if spec.clientTimer >= PRXStrawBedding.CLIENT_UPDATE_MS then
                    spec.clientTimer = 0
                    PRXStrawBedding.updateStrawPlane(self)
                end
            end
        }
        g_currentMission:addUpdateable(spec.updateable)
    end
end

function PRXStrawBedding:onDelete()
    local spec = self[PRXStrawBedding.SPEC]
    if spec == nil then
        return
    end
    if spec.updateable ~= nil then
        g_currentMission:removeUpdateable(spec.updateable)
        spec.updateable = nil
    end
    if spec.strawPlane ~= nil then
        spec.strawPlane:delete()
        spec.strawPlane = nil
    end
end

function PRXStrawBedding.getRatio(self)
    local spec = self[PRXStrawBedding.SPEC]
    local capacity = self:getHusbandryCapacity(spec.fillType)
    if capacity == nil or capacity <= 0 then
        return 0, 0, 0
    end
    local fillLevel = self:getHusbandryFillLevel(spec.fillType) or 0
    return math.clamp(fillLevel / capacity, 0, 1), fillLevel, capacity
end

function PRXStrawBedding.updateStrawPlane(self)
    local spec = self[PRXStrawBedding.SPEC]
    if spec.strawPlane ~= nil then
        local ratio = PRXStrawBedding.getRatio(self)
        spec.strawPlane:setState(ratio)
    end
end

function PRXStrawBedding:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    local spec = self[PRXStrawBedding.SPEC]
    local ratio, fillLevel, capacity = PRXStrawBedding.getRatio(self)

    if self.isServer then
        -- bonus from the bedding as it was this hour, then use some up
        local adj = g_currentMission.environment.timeAdjustment
        local amount = (spec.litersPerDay / 24) * adj
        -- take it straight from the barn's storage: removeHusbandryFillLevel only works through a loading station,
        -- and this barn has none (it was removed with milk and slurry)
        local storage = self.spec_husbandry ~= nil and self.spec_husbandry.storage or nil
        if storage ~= nil and fillLevel > 0 and spec.litersPerDay > 0 then
            local current = storage:getFillLevel(spec.fillType) or 0
            storage:setFillLevel(current - math.min(amount, current), spec.fillType)
        end
        -- TEMP diagnostics (straw not going down in test): one line per in-game hour
        Logging.info("[Alpaca PRX500] straw hourly: before %.1f, after %.1f, wanted %.2f (l/day %.0f, timeAdjustment %s)",
            fillLevel, self:getHusbandryFillLevel(spec.fillType) or -1, amount, spec.litersPerDay, tostring(adj))
        PRXStrawBedding.updateStrawPlane(self)
    end

    superFunc(self, foodFactor, productionFactor * PRXStrawBedding.getFactor(ratio), globalProductionFactor)
end

function PRXStrawBedding:getConditionInfos(superFunc)
    local infos = superFunc(self)
    local spec = self[PRXStrawBedding.SPEC]
    local ratio, fillLevel = PRXStrawBedding.getRatio(self)

    -- the game's Productivity row is capped at 100%; show the real total with our bonuses (display only)
    local animals = self.spec_husbandryAnimals
    if animals ~= nil and animals.info ~= nil and animals.info.value ~= nil then
        local hay = self[PRXHayBonus ~= nil and PRXHayBonus.SPEC or ""]
        local total = animals.info.value * PRXStrawBedding.getFactor(ratio) * ((hay ~= nil and hay.lastBonus) or 1)
        for _, row in ipairs(infos) do
            if row == animals.info then
                row.valueText = string.format("%s %%", g_i18n:formatNumber(total * 100, 0))
            end
        end
    end

    local info = {}
    info.title = string.format("%s (%s%% production, %s l/day)", spec.title, g_i18n:formatNumber(PRXStrawBedding.getFactor(ratio) * 100, 1), g_i18n:formatNumber(spec.litersPerDay or 0, 0))
    info.value = fillLevel
    info.ratio = ratio
    info.invertedBar = false
    table.insert(infos, info)

    return infos
end
