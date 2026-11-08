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
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".prxPalletSize#cabinetNode", "The control cabinet used as the switch")
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
    -- the switch is the control cabinet; show the prompt when the player stands within RANGE of SPOT (in front of it)
    spec.cabinetNode = self.xmlFile:getValue("placeable.prxPalletSize#cabinetNode", nil, self.components, self.i3dMappings)
    if spec.cabinetNode ~= nil and self.isClient then
        spec.activatable = PRXPalletSizeActivatable.new(self)
        spec.inRange = false
        local placeable = self
        spec.updateable = {
            timer = 0,
            update = function(u, dt)
                u.timer = u.timer + dt
                if u.timer < 250 then
                    return
                end
                u.timer = 0
                PRXPalletSize.checkRange(placeable)
            end
        }
        g_currentMission:addUpdateable(spec.updateable)
    end
    Logging.info("[Alpaca PRX500] pallet size switch: cabinet %s", tostring(spec.cabinetNode))
end

PRXPalletSize.RANGE = 2.0
PRXPalletSize.FRONT = 0.8 -- metres in front of the cabinet (its local +z)

function PRXPalletSize.getSpot(self)
    local spec = self[PRXPalletSize.SPEC]
    local x, y, z = getWorldTranslation(spec.cabinetNode)
    return x, y + 1.0, z
end

function PRXPalletSize.checkRange(self)
    local spec = self[PRXPalletSize.SPEC]
    local player = g_localPlayer
    local inRange = false
    local dist = -1
    if player ~= nil and not player:getIsInVehicle() then
        local px, py, pz = player:getPosition()
        if px ~= nil then
            local sx, _, sz = PRXPalletSize.getSpot(self)
            dist = MathUtil.vector2Length(px - sx, pz - sz)
            inRange = dist < PRXPalletSize.RANGE
        end
    end
    -- TEMP diagnostics: distance to the cabinet every ~5 s while within 15 m
    spec.logTimer = (spec.logTimer or 0) + 1
    if dist >= 0 and dist < 15 and spec.logTimer >= 20 then
        spec.logTimer = 0
        Logging.info("[Alpaca PRX500] pallet switch: player %.1f m from cabinet (in range %s)", dist, tostring(inRange))
    end
    if inRange ~= spec.inRange then
        spec.inRange = inRange
        if inRange then
            spec.activatable:updateText()
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
            Logging.info("[Alpaca PRX500] pallet switch: prompt added")
        else
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end

function PRXPalletSize:onPostLoad(savegame)
    PRXPalletSize.applyPallet(self)
end

function PRXPalletSize:onDelete()
    local spec = self[PRXPalletSize.SPEC]
    if spec == nil then
        return
    end
    if spec.updateable ~= nil then
        g_currentMission:removeUpdateable(spec.updateable)
        spec.updateable = nil
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

-- register the key the same way the barn's doors do (AnimatedObjectActivatable): ACTIVATE_HANDTOOL, very high priority
function PRXPalletSizeActivatable:registerCustomInput(inputContext)
    local _
    _, self.actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_HANDTOOL, self, self.onInputToggle, false, true, false, true)
    if self.actionEventId ~= nil then
        g_inputBinding:setActionEventTextPriority(self.actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventTextVisibility(self.actionEventId, true)
        self:updateText()
        g_inputBinding:setActionEventText(self.actionEventId, self.activateText)
    end
    Logging.info("[Alpaca PRX500] pallet switch: key registered %s", tostring(self.actionEventId))
end

function PRXPalletSizeActivatable:removeCustomInput(inputContext)
    g_inputBinding:removeActionEventsByTarget(self)
    self.actionEventId = nil
end

function PRXPalletSizeActivatable:onInputToggle()
    self:run()
    if self.actionEventId ~= nil then
        g_inputBinding:setActionEventText(self.actionEventId, self.activateText)
    end
end

function PRXPalletSizeActivatable:getIsActivatable()
    local player = g_localPlayer
    return player ~= nil and not player:getIsInVehicle()
end

function PRXPalletSizeActivatable:run()
    local big = self.placeable[PRXPalletSize.SPEC].big
    Logging.info("[Alpaca PRX500] pallet switch pressed: now %s", big and "2,000 l" or "5,000 l")
    self.placeable:prxSetPalletSize(not big)
    self:updateText()
end

function PRXPalletSizeActivatable:getDistance(x, y, z)
    if self.placeable[PRXPalletSize.SPEC].cabinetNode ~= nil then
        local tx, ty, tz = PRXPalletSize.getSpot(self.placeable)
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
