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
    if player ~= nil and not player:getIsInVehicle() then
        local px, py, pz = player:getPosition()
        if px ~= nil then
            local sx, _, sz = PRXPalletSize.getSpot(self)
            inRange = MathUtil.vector2Length(px - sx, pz - sz) < PRXPalletSize.RANGE
        end
    end
    if inRange ~= spec.inRange then
        spec.inRange = inRange
        if inRange then
            spec.activatable:updateText()
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
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

-- the current size in the player's language ("5,000 l", "5.000 l", "5 000 l")
local function sizeText(big)
    if big then
        return text("prx_pallet5000", "5,000 l")
    end
    return text("prx_pallet2000", "2,000 l")
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
    self.activateText = string.format(text("prx_palletSizePrompt", "Fleece pallet size (now %s)"), sizeText(big))
end

-- register the key like the barn doors do (AnimatedObjectActivatable), but on ACTIVATE_OBJECT (R by default)
function PRXPalletSizeActivatable:registerCustomInput(inputContext)
    local _
    _, self.actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onInputToggle, false, true, false, true)
    if self.actionEventId ~= nil then
        g_inputBinding:setActionEventTextPriority(self.actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventTextVisibility(self.actionEventId, true)
        self:updateText()
        g_inputBinding:setActionEventText(self.actionEventId, self.activateText)
    end
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
    -- one press = one flip: the game can deliver the same key press twice (own key + prompt key)
    local now = g_time or 0
    if self.lastRun ~= nil and now - self.lastRun < 600 then
        return
    end
    self.lastRun = now
    local placeable = self.placeable
    local big = placeable[PRXPalletSize.SPEC].big
    local options = {sizeText(false), sizeText(true)}
    local function callback(index)
        if index == 1 or index == 2 then
            placeable:prxSetPalletSize(index == 2)
            self:updateText()
            if self.actionEventId ~= nil then
                g_inputBinding:setActionEventText(self.actionEventId, self.activateText)
            end
        end
    end
    OptionDialog.show(callback, text("prx_palletSizeTitle", "Fleece pallet size"),
        string.format(text("prx_palletSizeNow", "Now: %s. New fleece pallets spawn at the size you choose."), sizeText(big)), options)
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
