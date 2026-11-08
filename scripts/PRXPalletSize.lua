-- Alpaca PRX500: fleece pallet size switch at the control cabinet in the old milk room (PropaineX)
-- Stand at the cabinet, press the activate key: 5,000 l <-> 2,000 l. New pallets spawn at the chosen size.
-- Saved with the barn; changed on the server and sent to every player.

PRXPalletSize = {}
PRXPalletSize.MOD_NAME = g_currentModName
PRXPalletSize.SPEC = "spec_" .. g_currentModName .. ".prxPalletSize"
PRXPalletSize.OWN_PALLET = "placeables/alpacaPRX500/fleecePallet5000.xml"

function PRXPalletSize.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableHusbandryPallets, specializations)
end

function PRXPalletSize.registerFunctions(placeableType)
    SpecializationUtil.registerFunction(placeableType, "prxSetPalletSize", PRXPalletSize.setPalletSize)
    SpecializationUtil.registerFunction(placeableType, "prxPalletSizeTriggerCallback", PRXPalletSize.triggerCallback)
end

function PRXPalletSize.registerEventListeners(placeableType)
    SpecializationUtil.registerEventListener(placeableType, "onLoad", PRXPalletSize)
    SpecializationUtil.registerEventListener(placeableType, "onPostLoad", PRXPalletSize)
    SpecializationUtil.registerEventListener(placeableType, "onDelete", PRXPalletSize)
    SpecializationUtil.registerEventListener(placeableType, "onReadStream", PRXPalletSize)
    SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PRXPalletSize)
end

function PRXPalletSize.registerXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PRXPalletSize")
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".prxPalletSize#triggerNode", "Player trigger at the pallet size cabinet")
    schema:setXMLSpecializationType()
end

function PRXPalletSize.registerSavegameXMLPaths(schema, basePath)
    schema:setXMLSpecializationType("PRXPalletSize")
    schema:register(XMLValueType.BOOL, basePath .. "#big", "true = 5,000 l pallets, false = 2,000 l")
    schema:setXMLSpecializationType()
end

function PRXPalletSize:onLoad(savegame)
    local spec = self[PRXPalletSize.SPEC]
    spec.big = true
    spec.triggerNode = self.xmlFile:getValue("placeable.prxPalletSize#triggerNode", nil, self.components, self.i3dMappings)
    if spec.triggerNode ~= nil and self.isClient then
        addTrigger(spec.triggerNode, "prxPalletSizeTriggerCallback", self)
        spec.activatable = PRXPalletSizeActivatable.new(self)
    end
    -- TEMP diagnostics (switch prompt not showing)
    local wx, wy, wz = 0, 0, 0
    if spec.triggerNode ~= nil then wx, wy, wz = getWorldTranslation(spec.triggerNode) end
    Logging.info("[Alpaca PRX500] pallet switch: trigger %s at %.1f %.1f %.1f, client %s", tostring(spec.triggerNode), wx, wy, wz, tostring(self.isClient))
end

function PRXPalletSize:onPostLoad(savegame)
    PRXPalletSize.applyPallet(self)
end

function PRXPalletSize:onDelete()
    local spec = self[PRXPalletSize.SPEC]
    if spec == nil then
        return
    end
    if spec.triggerNode ~= nil and self.isClient then
        removeTrigger(spec.triggerNode)
    end
    if spec.activatable ~= nil then
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end

function PRXPalletSize:loadFromXMLFile(xmlFile, key)
    local big = xmlFile:getValue(key .. "#big")
    if big ~= nil then
        self[PRXPalletSize.SPEC].big = big
        PRXPalletSize.applyPallet(self)
    end
end

function PRXPalletSize:saveToXMLFile(xmlFile, key, usedModNames)
    xmlFile:setValue(key .. "#big", self[PRXPalletSize.SPEC].big)
end

function PRXPalletSize:onReadStream(streamId, connection)
    self[PRXPalletSize.SPEC].big = streamReadBool(streamId)
end

function PRXPalletSize:onWriteStream(streamId, connection)
    streamWriteBool(streamId, self[PRXPalletSize.SPEC].big)
end

-- point the fleece pallet spawner at the chosen pallet (our 5,000 l one, or the fill type's own DLC pallet)
function PRXPalletSize.applyPallet(self)
    local spec = self[PRXPalletSize.SPEC]
    local pallets = self.spec_husbandryPallets
    if spec == nil or pallets == nil or pallets.fillTypeIndexToPalletSpawner == nil then
        return
    end
    for fillTypeIndex, spawner in pairs(pallets.fillTypeIndexToPalletSpawner) do
        local filename
        if spec.big then
            filename = Utils.getFilename(PRXPalletSize.OWN_PALLET, self.baseDirectory)
        else
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            filename = fillType ~= nil and fillType.palletFilename or nil
        end
        if filename ~= nil then
            spawner:loadPalletFromFilename(filename, fillTypeIndex)
        end
    end
end

function PRXPalletSize:setPalletSize(big, noEventSend)
    local spec = self[PRXPalletSize.SPEC]
    if spec.big == big then
        return
    end
    spec.big = big
    PRXPalletSize.applyPallet(self)
    PRXPalletSizeEvent.sendEvent(self, big, noEventSend)
    if spec.activatable ~= nil then
        spec.activatable:updateText()
    end
end

function PRXPalletSize:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
    local spec = self[PRXPalletSize.SPEC]
    local player = g_localPlayer
    Logging.info("[Alpaca PRX500] pallet switch trigger: other %s (%s), player %s, enter %s leave %s", tostring(otherId), otherId ~= nil and getName(otherId) or "?", player ~= nil and tostring(player.rootNode) or "nil", tostring(onEnter), tostring(onLeave))
    if spec.activatable == nil or player == nil or otherId ~= player.rootNode then
        return
    end
    if onEnter then
        spec.activatable:updateText()
        g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
    elseif onLeave then
        g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
    end
end

local function text(key, fallback)
    if g_i18n:hasText(key, PRXPalletSize.MOD_NAME) then
        return g_i18n:getText(key, PRXPalletSize.MOD_NAME)
    end
    return fallback
end

----------------------------------------------------------------------------------------------------
PRXPalletSizeActivatable = {}
local PRXPalletSizeActivatable_mt = Class(PRXPalletSizeActivatable)

function PRXPalletSizeActivatable.new(placeable)
    local self = setmetatable({}, PRXPalletSizeActivatable_mt)
    self.placeable = placeable
    self.activateText = ""
    return self
end

function PRXPalletSizeActivatable:updateText()
    local big = self.placeable[PRXPalletSize.SPEC].big
    if big then
        self.activateText = text("prx_palletSizeTo2000", "Fleece pallets 5,000 l: switch to 2,000 l")
    else
        self.activateText = text("prx_palletSizeTo5000", "Fleece pallets 2,000 l: switch to 5,000 l")
    end
end

function PRXPalletSizeActivatable:run()
    local big = self.placeable[PRXPalletSize.SPEC].big
    self.placeable:prxSetPalletSize(not big)
    self:updateText()
end

function PRXPalletSizeActivatable:getDistance(x, y, z)
    local node = self.placeable[PRXPalletSize.SPEC].triggerNode
    if node ~= nil then
        local tx, ty, tz = getWorldTranslation(node)
        return MathUtil.vector3Length(x - tx, y - ty, z - tz)
    end
    return math.huge
end

----------------------------------------------------------------------------------------------------
PRXPalletSizeEvent = {}
local PRXPalletSizeEvent_mt = Class(PRXPalletSizeEvent, Event)
InitEventClass(PRXPalletSizeEvent, "PRXPalletSizeEvent")

function PRXPalletSizeEvent.emptyNew()
    return Event.new(PRXPalletSizeEvent_mt)
end

function PRXPalletSizeEvent.new(placeable, big)
    local self = PRXPalletSizeEvent.emptyNew()
    self.placeable = placeable
    self.big = big
    return self
end

function PRXPalletSizeEvent:readStream(streamId, connection)
    self.placeable = NetworkUtil.readNodeObject(streamId)
    self.big = streamReadBool(streamId)
    self:run(connection)
end

function PRXPalletSizeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.placeable)
    streamWriteBool(streamId, self.big)
end

function PRXPalletSizeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, false, connection, self.placeable)
    end
    if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.prxSetPalletSize ~= nil then
        self.placeable:prxSetPalletSize(self.big, true)
    end
end

function PRXPalletSizeEvent.sendEvent(placeable, big, noEventSend)
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(PRXPalletSizeEvent.new(placeable, big), nil, nil, placeable)
        else
            g_client:getServerConnection():sendEvent(PRXPalletSizeEvent.new(placeable, big))
        end
    end
end
