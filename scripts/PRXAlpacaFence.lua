-- Alpaca PRX500: use the Beans & Alpacas DLC's own alpaca fence (PropaineX)
-- The fence xml path and the i3d path written inside that fence xml are both resolved against the
-- placeable's baseDirectory (PlaceableHusbandryFence:onLoad, Utils.getFilename), and Utils.getFilename does not
-- understand $pdlcdir$. So for our barn only, while the fence loads, the baseDirectory points at the DLC's folder.

PRXAlpacaFence = {}
PRXAlpacaFence.MOD_NAME = g_currentModName
PRXAlpacaFence.DLC_NAME = "pdlc_beansAndAlpacasPack"
PRXAlpacaFence.FENCE_XML = "placeables/fences/alpacaFence/alpacaFence.xml"

local function withSlash(dir)
    if dir == nil or dir == "" then
        return nil
    end
    dir = dir:gsub("\\", "/")
    if dir:sub(-1) ~= "/" then
        dir = dir .. "/"
    end
    return dir
end

function PRXAlpacaFence.getDlcDirectory()
    if PRXAlpacaFence.dlcDirectory ~= nil then
        return PRXAlpacaFence.dlcDirectory
    end
    local dir
    if g_modManager ~= nil then
        local mod = g_modManager:getModByName(PRXAlpacaFence.DLC_NAME)
        if mod ~= nil then
            dir = withSlash(mod.modDir)
        end
    end
    if dir == nil and g_storeManager ~= nil then
        -- fallback: any shop item that comes from the DLC carries the DLC folder
        for _, item in pairs(g_storeManager:getItems()) do
            local filename = (item.xmlFilename or ""):gsub("\\", "/")
            if item.baseDir ~= nil and filename:find("/beansAndAlpacasPack/", 1, true) ~= nil then
                dir = withSlash(item.baseDir)
                break
            end
        end
    end
    PRXAlpacaFence.dlcDirectory = dir
    return dir
end

function PRXAlpacaFence.fenceOnLoad(self, superFunc, savegame)
    if self.customEnvironment ~= PRXAlpacaFence.MOD_NAME
        or self.xmlFile == nil
        or self.xmlFile:getValue("placeable.husbandry.fence#xmlFilename") ~= PRXAlpacaFence.FENCE_XML then
        return superFunc(self, savegame)
    end

    local dlcDir = PRXAlpacaFence.getDlcDirectory()
    if dlcDir == nil then
        Logging.xmlError(self.xmlFile, "[Alpaca PRX500] Beans & Alpacas DLC folder not found; the alpaca fence can't load")
        return superFunc(self, savegame)
    end

    local ownDir = self.baseDirectory
    self.baseDirectory = dlcDir
    local ok, err = pcall(superFunc, self, savegame)
    self.baseDirectory = ownDir
    if not ok then
        error(err, 0)
    end
end

PlaceableHusbandryFence.onLoad = Utils.overwrittenFunction(PlaceableHusbandryFence.onLoad, PRXAlpacaFence.fenceOnLoad)
