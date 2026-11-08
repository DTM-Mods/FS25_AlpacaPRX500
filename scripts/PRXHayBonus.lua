-- Alpaca PRX500: hay counts 5% more than the sheep's hay value (PropaineX)
-- The food group's own value is not raised above 100%, because the husbandry's production factor is sent to
-- multiplayer clients as factor * 255 in one byte. Instead: the share of the hour's food that was hay gives up to
-- +5% on the hourly output (fleece), and the info screen shows the hay row 5% higher.

PRXHayBonus = {}
PRXHayBonus.SPEC = "spec_" .. g_currentModName .. ".prxHayBonus"
PRXHayBonus.BONUS = 0.05

function PRXHayBonus.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryFood, specializations)
end

function PRXHayBonus.registerOverwrittenFunctions(placeableType)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "removeFood", PRXHayBonus.removeFood)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PRXHayBonus.updateOutput)
    SpecializationUtil.registerOverwrittenFunction(placeableType, "getFoodInfos", PRXHayBonus.getFoodInfos)
end

function PRXHayBonus.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PRXHayBonus)
end

function PRXHayBonus:onLoad(savegame)
    local spec = self[PRXHayBonus.SPEC]
    spec.eatenHay = 0
    spec.eatenTotal = 0
end

local function isHay(fillTypeIndex)
    local group = PRXAlpacaFood ~= nil and PRXAlpacaFood.hayGroup or nil
    if group == nil then
        return false
    end
    for _, f in pairs(group.fillTypes) do
        if f == fillTypeIndex then
            return true
        end
    end
    return false
end

function PRXHayBonus:removeFood(superFunc, absDeltaFillLevel, fillTypeIndex)
    local removed = superFunc(self, absDeltaFillLevel, fillTypeIndex) or 0
    local spec = self[PRXHayBonus.SPEC]
    if self.isServer and spec ~= nil and removed > 0 then
        spec.eatenTotal = spec.eatenTotal + removed
        if isHay(fillTypeIndex) then
            spec.eatenHay = spec.eatenHay + removed
        end
    end
    return removed
end

function PRXHayBonus:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
    local spec = self[PRXHayBonus.SPEC]
    local bonus = 1
    if spec ~= nil and spec.eatenTotal > 0 then
        bonus = 1 + PRXHayBonus.BONUS * math.clamp(spec.eatenHay / spec.eatenTotal, 0, 1)
    end
    if spec ~= nil then
        spec.lastBonus = bonus
        spec.eatenHay = 0
        spec.eatenTotal = 0
    end
    superFunc(self, foodFactor, productionFactor * bonus, globalProductionFactor)
end

function PRXHayBonus:getFoodInfos(superFunc)
    local infos = superFunc(self)
    local group = PRXAlpacaFood ~= nil and PRXAlpacaFood.hayGroup or nil
    if group ~= nil and group.title ~= nil and group.productionWeight ~= nil then
        local prefix = group.title .. " ("
        for _, info in ipairs(infos) do
            if info.title ~= nil and string.sub(info.title, 1, #prefix) == prefix then
                info.title = string.format("%s (%d%%)", group.title, MathUtil.round((group.productionWeight + PRXHayBonus.BONUS) * 100))
            end
        end
    end
    return infos
end
