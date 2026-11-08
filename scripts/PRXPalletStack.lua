-- Alpaca PRX500: fleece pallets may stack 2 high (PropaineX)
-- Each pallet spawn place has a maximum height the spawner may build up to (place.maxHeight; the game sets it to
-- math.huge where it wants pallets to stack, e.g. unloading pallets from a vehicle). We set our spawn places to
-- MAX_HEIGHT: room for two fleece pallets (~1.8 m each) but not three.
-- Untested: the code that reads maxHeight (PlacementUtil) is not in the readable game source.

PRXPalletStack = {}
PRXPalletStack.MAX_HEIGHT = 4.0

function PRXPalletStack.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryPallets, specializations)
end

PRXPalletStack.RETRY_MS = 5000

-- shop option "Fleece pallet size": 1 = 2,000 l (the DLC's own pallet), 2 = 5,000 l (our pallet, set in the barn xml)
PRXPalletStack.MOD_NAME = g_currentModName

function PRXPalletStack.initSpecialization()
    if g_placeableConfigurationManager:getConfigurationDescByName("prxFleecePallet") == nil then
        local title = "Fleece pallet size"
        if g_i18n:hasText("prx_fleecePalletSize", PRXPalletStack.MOD_NAME) then
            title = g_i18n:getText("prx_fleecePalletSize", PRXPalletStack.MOD_NAME)
        end
        g_placeableConfigurationManager:addConfigurationType("prxFleecePallet", title, "prxFleecePallet", PlaceableConfigurationItem)
    end
end

function PRXPalletStack.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PRXPalletStack")
    PlaceableConfigurationItem.registerXMLPaths(schema, basePath .. ".prxFleecePallet", basePath .. ".prxFleecePallet.prxFleecePalletConfigurations.prxFleecePalletConfiguration(?)")
    schema:setXMLSpecializationType()
end

local function useDlcPallet(self)
    local spec = self.spec_husbandryPallets
    if spec == nil or spec.fillTypeIndexToPalletSpawner == nil then
        return
    end
    for fillTypeIndex, spawner in pairs(spec.fillTypeIndexToPalletSpawner) do
        local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
        if fillType ~= nil and fillType.palletFilename ~= nil then
            spawner:loadPalletFromFilename(fillType.palletFilename, fillTypeIndex)
        end
    end
end

function PRXPalletStack.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PRXPalletStack)
    SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PRXPalletStack)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PRXPalletStack)
end

local function hasWaitingFleece(self)
    local spec = self.spec_husbandryPallets
    if spec == nil or spec.pendingLiters == nil then
        return false
    end
    for _, liters in pairs(spec.pendingLiters) do
        if liters > 5 then
            return true
        end
    end
    return false
end

-- server: while fleece is waiting, try to spawn it every RETRY_MS (real time), so it comes out as soon as there's room
function PRXPalletStack:onFinalizePlacement()
    if not self.isServer then
        return
    end
    local placeable = self
    self.prxPalletRetry = {
        timer = 0,
        update = function(updateable, dt)
            updateable.timer = updateable.timer + dt
            if updateable.timer < PRXPalletStack.RETRY_MS then
                return
            end
            updateable.timer = 0
            local spec = placeable.spec_husbandryPallets
            if spec ~= nil and spec.numSpawnsPending == 0 and hasWaitingFleece(placeable) then
                placeable:updatePallets()
            end
        end
    }
    g_currentMission:addUpdateable(self.prxPalletRetry)
end

function PRXPalletStack:onDelete()
    if self.prxPalletRetry ~= nil then
        g_currentMission:removeUpdateable(self.prxPalletRetry)
        self.prxPalletRetry = nil
    end
end

function PRXPalletStack.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PRXPalletStack.updateOutput)
end

-- Fleece that couldn't be spawned (no room at shearing) waits in pendingLiters. The game only retries the spawn
-- in the hourly output step when the animals make fleece per hour (litersPerHour > 0), which alpacas don't:
-- their fleece comes from shearing. So retry every in-game hour ourselves while fleece is waiting.
function PRXPalletStack:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    superFunc(self, foodFactor, productionFactor, globalProductionFactor)
    local spec = self.spec_husbandryPallets
    if self.isServer and spec ~= nil and spec.pendingLiters ~= nil then
        for _, liters in pairs(spec.pendingLiters) do
            if liters > 5 then
                self:updatePallets()
                break
            end
        end
    end
end

function PRXPalletStack:onPostLoad(savegame)
    if self.configurations ~= nil and self.configurations["prxFleecePallet"] == 1 then
        useDlcPallet(self)
    end
    local spec = self.spec_husbandryPallets
    if spec == nil or spec.fillTypeIndexToPalletSpawner == nil then
        return
    end
    local done = {}
    local count = 0
    for _, spawner in pairs(spec.fillTypeIndexToPalletSpawner) do
        if not done[spawner] and spawner.spawnPlaces ~= nil then
            done[spawner] = true
            for _, place in ipairs(spawner.spawnPlaces) do
                place.maxHeight = PRXPalletStack.MAX_HEIGHT
                count = count + 1
            end
        end
    end
    if count > 0 then
        Logging.info("[Alpaca PRX500] Fleece pallet spawn places set to stack up to %.1f m (%d places)", PRXPalletStack.MAX_HEIGHT, count)
    end
end
