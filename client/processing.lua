local RSGCore = exports['rsg-core']:GetCoreObject()

-- Helper to process action (must be defined BEFORE the event that calls it)
local function ProcessAction(type)
    local duration = Config.ProcessTime[type]
    local label = ''
    
    if type == 'wash' then 
        label = 'Processing (Wash)' 
    elseif type == 'dry' then 
        label = 'Processing (Dry)' 
    elseif type == 'trim' then 
        label = 'Processing (Trim)' 
    elseif type == 'roll' then 
        label = 'Rolling Joint' 
    end

    RSGCore.Functions.TriggerCallback('rsg-weed:server:canProcess', function(can, msg)
        if can then
            local weedProp = nil
            local toolProp = nil
            local weedProps = {}
            
            if type ~= 'wash' then
                 local wpHash = GetHashKey('prop_weed_05') -- Reverted to standard weed prop
                 RequestModel(wpHash)
                 while not HasModelLoaded(wpHash) do Wait(0) end
                 
                 local pCoords = GetEntityCoords(PlayerPedId())
                 local tableHash = GetHashKey(Config.ProcessingProps.dry)
                 local tableObj = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, 5.0, tableHash, false, false, false) -- Increased search distance
                 
                 if DoesEntityExist(tableObj) then
                     if type == 'dry' or type == 'trim' then
                         -- Spawn 3 props hanging downwards for both Drying and Trimming
                         local offsets = {-0.6, 0.0, 0.6}
                         for _, xOff in ipairs(offsets) do
                             local wProp = CreateObject(wpHash, 0, 0, 0, true, true, false)
                             SetEntityCollision(wProp, false, false)
                             -- Attach with 180 rotation on X to hang upside down
                             AttachEntityToEntity(wProp, tableObj, 0, xOff, 0.0, 2.2, 180.0, 0.0, 0.0, true, true, false, true, 1, true)
                             
                             table.insert(weedProps, wProp)
                         end
                     end
                 end
            end
            
            if type == 'wash' then
                TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_BUCKET_POUR_LOW'), -1, true, false, false, false)
            elseif type == 'dry' then
                TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CLIPBOARD'), -1, true, false, false, false)
            elseif type == 'trim' then
                 -- Using Stand Impatient to keep player standing without extra props (like clipboard)
                 TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_STAND_IMPATIENT'), -1, true, false, false, false)
                 
                 local toolHash = GetHashKey('w_melee_knife01')
                 RequestModel(toolHash)
                 local timeout = 0
                 while not HasModelLoaded(toolHash) and timeout < 50 do 
                     Wait(10) 
                     timeout = timeout + 1
                 end
                 
                 if HasModelLoaded(toolHash) then
                     local ped = PlayerPedId()
                     local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Hand")
                     toolProp = CreateObject(toolHash, 0, 0, 0, true, true, false)
                     SetEntityCollision(toolProp, false, false) -- Disable collision on scissors too
                     AttachEntityToEntity(toolProp, ped, boneIndex, 0.1, 0.05, -0.05, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
                     SetModelAsNoLongerNeeded(toolHash)
                 else
                     print('[RSG-WEED] Failed to load tool model: ' .. toolHash)
                 end
            elseif type == 'roll' then
                -- Roll Joint: Use writing/crafting animation (hands working)
                TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_WRITE_NOTEBOOK'), -1, true, false, false, false)
            end
            
            if lib.progressBar({
                duration = duration,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    move = true,
                    car = true
                },
                label = label
            }) then
                TriggerServerEvent('rsg-weed:server:finishProcess', type)
                -- Server notifies result
            end
            
            ClearPedTasksImmediately(PlayerPedId())
            FreezeEntityPosition(PlayerPedId(), false)
            if weedProps then
                for _, prop in ipairs(weedProps) do
                    if DoesEntityExist(prop) then DeleteObject(prop) end
                end
            elseif weedProp and DoesEntityExist(weedProp) then 
                DeleteObject(weedProp) 
            end
            if toolProp and DoesEntityExist(toolProp) then DeleteObject(toolProp) end
        else
            lib.notify({ title = 'Error', description = msg or 'Missing required items!', type = 'error' })
        end
    end, { type = type })
end

-- Processing Action Event (triggered from placement.lua targets)
RegisterNetEvent('rsg-weed:client:processAction', function(type)
    ProcessAction(type)
end)

-- Roll Joint from Inventory (triggered when using trimmed bud)
RegisterNetEvent('rsg-weed:client:rollJoint', function(strainKey)
    local duration = Config.ProcessTime.roll or 5000
    
    -- Play rolling animation
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_WRITE_NOTEBOOK'), -1, true, false, false, false)
    
    if lib.progressBar({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true
        },
        label = 'Rolling Joint...'
    }) then
        TriggerServerEvent('rsg-weed:server:finishRollJoint', strainKey)
    end
    
    ClearPedTasksImmediately(PlayerPedId())
    FreezeEntityPosition(PlayerPedId(), false)
end)
