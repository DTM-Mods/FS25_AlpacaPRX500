-- Alpaca PRX500: alpacas eat whatever grass and hay sheep eat on this map (PropaineX)
-- Runs once per game load, on the server and on every client (each loads the map's food list itself).
-- Every fill type in the SHEEP grass/hay groups is added to the matching ALPACA group, one type at a time.
-- So map crops like alfalfa or clover, or any custom forage a map puts with the sheep's grass/hay, also feed alpacas.
-- Fill types are sorted one by one (dry = hay, fresh = grass), so pasture grass counts as Grass, not Hay.

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
    -- remember the hay group for PRXHayBonus
    PRXAlpacaFood.hayGroup = alpacaHay
    if alpacaGrass == nil then
        Logging.warning("[Alpaca PRX500] Alpaca food list has no grass or hay group; food not changed")
        return
    end

    -- Sort every fill type one by one, never a whole group: a map may keep the sheep's grass and hay in ONE group,
    -- and copying that whole group put fresh grass into the alpaca Hay group. The pasture (meadow) supplies fresh grass,
    -- so the alpacas then grazed "hay" at 100% and never ate from the trough.
    --   in a sheep group with hay but no grass       -> Hay
    --   in a sheep group with grass but no hay       -> Grass
    --   in a combined group: name starting "DRY"     -> Hay, anything else -> Grass
    local function targetFor(group, fillTypeIndex)
        local hasGrass, hasHay = groupHas(group, GRASS), groupHas(group, HAY)
        if hasHay and not hasGrass then return alpacaHay end
        if hasGrass and not hasHay then return alpacaGrass end
        if hasGrass and hasHay then
            local name = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex) or ""
            if string.sub(name, 1, 3) == "DRY" then return alpacaHay end
            return alpacaGrass
        end
        return nil
    end

    local added = {}
    for _, group in pairs(sheepFood.groups) do
        for _, fillTypeIndex in pairs(group.fillTypes) do
            local target = targetFor(group, fillTypeIndex)
            if target ~= nil then
                -- one fill type belongs to one alpaca group only
                local inOther = false
                for _, g in pairs(alpacaFood.groups) do
                    if g ~= target and groupHas(g, fillTypeIndex) then inOther = true end
                end
                if not inOther and not groupHas(target, fillTypeIndex) then
                    table.insert(target.fillTypes, fillTypeIndex)
                    table.insert(added, string.format("%s -> %s", tostring(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)), tostring(target.title)))
                end
            end
        end
    end

    -- effectiveness (%) the same as for sheep on this map: grass like the sheep's grass, hay like the sheep's hay.
    -- The meadow (pasture) row uses the grass group's %, so it follows too.
    local function sheepWeight(fillTypeIndex)
        for _, group in pairs(sheepFood.groups) do
            if groupHas(group, fillTypeIndex) and group.productionWeight ~= nil then
                return group.productionWeight
            end
        end
        return nil
    end
    for _, pair in ipairs({{alpacaGrass, GRASS}, {alpacaHay, HAY}}) do
        local group, weight = pair[1], sheepWeight(pair[2])
        if weight ~= nil and group.productionWeight ~= weight then
            Logging.info("[Alpaca PRX500] Alpaca '%s' effectiveness %d%% -> %d%% (same as sheep)",
                tostring(group.title), math.floor((group.productionWeight or 0) * 100 + 0.5), math.floor(weight * 100 + 0.5))
            group.productionWeight = weight
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
