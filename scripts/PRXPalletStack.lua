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

function PRXPalletStack.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PRXPalletStack)
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
