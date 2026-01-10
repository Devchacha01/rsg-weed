local RSGCore = exports['rsg-core']:GetCoreObject()
local inPlacing = false
local placedObjects = {} -- Track placed objects for cleanup

local function DrawPlacementHelp(x, y, z)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        local str = CreateVarString(10, "LITERAL_STRING", "[WASD] Move | [Q/E] Rotate | [ENTER] Place | [BACKSPACE] Cancel")
        SetTextCentre(1)
        DisplayText(str, _x, _y)
    end
end

-- Initialize Targets for Models (Robustness)
CreateThread(function()
    for type, data in pairs(Config.PlaceableProps) do
        local options = {}
        
        if type == 'wash_barrel' then
            table.insert(options, {
                type = "client",
                action = function()
                    TriggerEvent('rsg-weed:client:processAction', 'wash')
                end,
                icon = "fas fa-water",
                label = "Wash Weed",
            })
        elseif type == 'processing_table' then
            table.insert(options, {
                type = "client",
                action = function()
                    TriggerEvent('rsg-weed:client:processAction', 'dry')
                end,
                icon = "fas fa-wind",
                label = "Dry Weed",
            })
            table.insert(options, {
                type = "client",
                action = function()
                    TriggerEvent('rsg-weed:client:processAction', 'trim')
                end,
                icon = "fas fa-cut",
                label = "Trim Weed",
            })
        end
        
        -- Pick Up Option (Checks placedObjects)
        table.insert(options, {
            type = "client",
            action = function(entity)
                for i, pData in ipairs(placedObjects) do
                    if pData.entity == entity then
                        exports['rsg-target']:RemoveTargetEntity(entity) -- Just in case
                        DeleteObject(entity)
                        table.remove(placedObjects, i)
                        TriggerServerEvent('rsg-weed:server:givePlaceable', pData.type)
                        lib.notify({ title = 'Success', description = 'Picked up!', type = 'success' })
                        break
                    end
                end
            end,
            icon = "fas fa-hand-paper",
            label = "Pick Up",
            canInteract = function(entity)
                for _, pData in ipairs(placedObjects) do
                    if pData.entity == entity then return true end
                end
                return false
            end
        })

        exports['rsg-target']:AddTargetModel(GetHashKey(data.model), {
            options = options,
            distance = 5.0,
        })
    end
end)

RegisterNetEvent('rsg-weed:client:startPlacing', function(type)
    if inPlacing then return end
    
    local propData = Config.PlaceableProps[type]
    if not propData then return end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local model = GetHashKey(propData.model)
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 100 do 
        Wait(50) 
        timeout = timeout + 1
    end
    
    if not HasModelLoaded(model) then
        lib.notify({ title = 'Error', description = 'Failed to load model', type = 'error' })
        return
    end
    
    inPlacing = true
    
    -- Create Ghost
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + forward * 2.0
    local ghost = CreateObject(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, true, false)
    local ghostHeading = GetEntityHeading(ped)
    
    SetEntityAlpha(ghost, 200, false)
    SetEntityCollision(ghost, false, false)
    PlaceObjectOnGroundProperly(ghost)
    
    CreateThread(function()
        while inPlacing do
            Wait(0)
            local pCoords = GetEntityCoords(ped)
            local pForward = GetEntityForwardVector(ped)
            
            local newCoords = pCoords + pForward * 2.0
            
            SetEntityCoords(ghost, newCoords.x, newCoords.y, newCoords.z, false, false, false, false)
            SetEntityHeading(ghost, ghostHeading)
            PlaceObjectOnGroundProperly(ghost)
            
            DrawPlacementHelp(newCoords.x, newCoords.y, newCoords.z + 1.0)
            
            -- Rotate with Q/E (same hashes as rsg-farming)
            if IsControlPressed(0, 0xDE794E3E) then -- Q
                ghostHeading = ghostHeading + 1.0
            end
            if IsControlPressed(0, 0xCEFD9220) then -- E
                ghostHeading = ghostHeading - 1.0
            end
            
            -- ENTER to place
            if IsControlJustPressed(0, 0xC7B5340A) then
                local finalCoords = GetEntityCoords(ghost)
                local finalHeading = GetEntityHeading(ghost)
                DeleteObject(ghost)
                
                -- Spawn Real Object
                local obj = CreateObject(model, finalCoords.x, finalCoords.y, finalCoords.z, true, true, false)
                SetEntityAsMissionEntity(obj, true, true)
                SetEntityHeading(obj, finalHeading)
                PlaceObjectOnGroundProperly(obj)
                FreezeEntityPosition(obj, true)
                SetEntityCollision(obj, true, true)
                
                -- Track the object
                table.insert(placedObjects, { entity = obj, type = type })
                
                -- Remove Item
                TriggerServerEvent('rsg-weed:server:removeItem', type, 1)
                
                lib.notify({ title = 'Placed', description = propData.label .. ' placed!', type = 'success' })
                
                inPlacing = false
                break
            end
            
            -- Backspace to cancel
            if IsControlJustPressed(0, 0x156F7119) then
                DeleteObject(ghost)
                lib.notify({ title = 'Cancelled', description = 'Placement cancelled', type = 'error' })
                inPlacing = false
                break
            end
        end
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, data in ipairs(placedObjects) do
            if DoesEntityExist(data.entity) then
                exports['rsg-target']:RemoveTargetEntity(data.entity)
                DeleteObject(data.entity)
            end
        end
    end
end)
