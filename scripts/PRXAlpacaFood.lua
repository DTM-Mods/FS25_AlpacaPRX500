-- Alpaca PRX500: alpacas eat whatever grass and hay sheep eat on this map (PropaineX)
-- Runs once per game load, on the server and on every client (each loads the map's food list itself).
-- For every SHEEP food group that holds grass (GRASS_WINDROW) its fill types go into the ALPACA grass group;
-- for every SHEEP group that holds hay (DRYGRASS_WINDROW) its fill types go into the ALPACA hay group.
-- So map crops like alfalfa or clover, or any custom forage a map puts with the sheep's grass/hay, also feed alpacas.
-- Meadow (pasture grazing) gets the same effectiveness as grass.

PRXAlpacaFood = {}
PRXAlpacaFood.done = false

local function groupHas(group, fillTypeIndex)
    for _, f in pairs(group.fillTypes) do
        if f == fillTypeIndex then
            return true
        end
    end
    return false
end

function PRXAlpacaFood.apply()
    if PRXAlpacaFood.done then
        return
    end
    local mission = g_currentMission
    if mission == nil or mission.animalFoodSystem == nil or mission.animalSystem == nil then
        return
    end
    local alpacaType = mission.animalSystem:getTypeByName("ALPACA")
    local sheepType = mission.animalSystem:getTypeByName("SHEEP")
    if alpacaType == nil or sheepType == nil then
        return
    end
    local alpacaFood = mission.animalFoodSystem:getAnimalFood(alpacaType.typeIndex)
    local sheepFood = mission.animalFoodSystem:getAnimalFood(sheepType.typeIndex)
    if alpacaFood == nil or sheepFood == nil or alpacaFood.groups == nil or sheepFood.groups == nil then
        return
    end
    PRXAlpacaFood.done = true

    local GRASS = FillType.GRASS_WINDROW
    local HAY = FillType.DRYGRASS_WINDROW

    local alpacaGrass, alpacaHay
    for _, group in pairs(alpacaFood.groups) do
        if alpacaGrass == nil and groupHas(group, GRASS) then alpacaGrass = group end
        if alpacaHay == nil and groupHas(group, HAY) then alpacaHay = group end
    end
    alpacaGrass = alpacaGrass or alpacaHay
    alpacaHay = alpacaHay or alpacaGrass
    if alpacaGrass == nil then
        Logging.warning("[Alpaca PRX500] Alpaca food list has no grass or hay group; food not changed")
        return
    end

    local added = {}
    for _, group in pairs(sheepFood.groups) do
        local targets = {}
        if groupHas(group, GRASS) then
            table.insert(targets, alpacaGrass)
        end
        if groupHas(group, HAY) and (#targets == 0 or targets[1] ~= alpacaHay) then
            table.insert(targets, alpacaHay)
        end
        for _, target in ipairs(targets) do
            for _, fillTypeIndex in pairs(group.fillTypes) do
                if not groupHas(target, fillTypeIndex) then
                    table.insert(target.fillTypes, fillTypeIndex)
                    table.insert(added, string.format("%s -> %s", tostring(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)), tostring(target.title)))
                end
            end
        end
    end

    -- meadow (pasture grazing) counts the same as grass: give every other alpaca food group the grass group's effectiveness
    if alpacaGrass ~= alpacaHay and alpacaGrass.productionWeight ~= nil then
        for _, group in pairs(alpacaFood.groups) do
            if group ~= alpacaGrass and group ~= alpacaHay and group.productionWeight ~= alpacaGrass.productionWeight then
                Logging.info("[Alpaca PRX500] Food group '%s' effectiveness %d%% -> %d%% (same as grass)",
                    tostring(group.title), math.floor((group.productionWeight or 0) * 100 + 0.5), math.floor(alpacaGrass.productionWeight * 100 + 0.5))
                group.productionWeight = alpacaGrass.productionWeight
            end
        end
    end

    if #added > 0 then
        Logging.info("[Alpaca PRX500] Alpacas now also eat (same as sheep): %s", table.concat(added, ", "))
    else
        Logging.info("[Alpaca PRX500] Alpaca grass/hay already matches sheep; nothing added")
    end
end

-- also run when the map has loaded, so it applies even before any Alpaca PRX500 is placed
local PRXAlpacaFoodListener = {}
function PRXAlpacaFoodListener:loadMap()
    PRXAlpacaFood.apply()
end
addModEventListener(PRXAlpacaFoodListener)
