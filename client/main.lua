ESX = exports["es_extended"]:getSharedObject()

lib.locale()

local isAdminOnDuty = false


RegisterNetEvent('djonza:client:setAdminDutyStatus')
AddEventHandler('djonza:client:setAdminDutyStatus', function(status)
    isAdminOnDuty = status
end)


exports('IsPlayerAdminAndOnDuty', function()
    return isAdminOnDuty
end)

RegisterNetEvent('djonza:adminDutyStatus')
AddEventHandler('djonza:adminDutyStatus', function(status)
    isAdminOnDuty = status
    if isAdminOnDuty then
        lib.notify({
            title = locale('title'),
            description = locale('enter_duty_message'),
            type = "info"
        })
    else
        lib.notify({
            title = locale('title'),
            description = locale('exit_duty_message'),
            type = "info"
        })
    end
end)

lib.registerContext({
    id = 'admin-meni',
    title = locale('admin_menu_title'),
    options = {
        {
            title = locale('player_list_title'),
            icon = 'user',
            arrow = true,
            onSelect = function()
                UpdatePlayerList() 
            end
        },
        {
            title = locale('organization_list'),
            icon = 'list',
            arrow = true,
            onSelect = function()
                ShowOrganizationMenu()
            end,
        },
        {
            title = locale('server_settings_title'),
            icon = 'wrench',
            menu = 'serversettings',
        },
        {
            title = locale('vehicle_menu_title'),
            icon = 'car',
            menu = 'menivozila',
        },
    }
})

lib.registerContext({
    id = 'menivozila',
    title = locale('vehicle_menu_title'),
    menu = 'admin-meni',
    options = {
        {
            title = locale('repair_vehicle_title'),
            icon = 'wrench',
            onSelect = function()
                local ped = PlayerPedId()
                local vehicle = GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleFixed(vehicle)
                    lib.notify
                    ({title = locale('title'), description = locale('vehicle_repaired_message'), type = 'success'})
                else
                    lib.notify({title = locale('title'), description = locale('no_vehicles_nearby'), type = 'error'})
                end
            end,
        },
        {
            title = locale('fill_fuel_title'),
            icon = 'gas-pump',
            onSelect = function()
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false) or GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71)
                if vehicle and DoesEntityExist(vehicle) then
                    SetVehicleFuelLevel(vehicle, 100.0)
                    lib.notify({title = locale('title'), description = locale('fuel_refilled'), type = 'success'})
                else
                    lib.notify({title = locale('title'), description = locale('no_vehicles_nearby'),  type = 'error'})
                end
            end,
        },
        {
            title = locale('spawn_admin_vehicle'),
            icon = 'truck',
            onSelect = function()
                local ped = PlayerPedId()
                local vehicleModel = GetHashKey(Config.VehicleModel)
                RequestModel(vehicleModel)
                while not HasModelLoaded(vehicleModel) do Wait(500) end
                local vehicle = CreateVehicle(vehicleModel, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
                SetPedIntoVehicle(ped, vehicle, -1)
                SetVehicleFuelLevel(vehicle, 100.0)
                lib.notify({title = locale('title'), description = locale('vehicle_spawned'), type = 'success'})
                SetModelAsNoLongerNeeded(vehicleModel)
            end,
        },
        {
            title = locale('delete_vehicle_title'),
            icon = 'trash',
            onSelect = function()
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false) or GetClosestVehicle(GetEntityCoords(ped), 5.0, 0, 71)
                if vehicle and DoesEntityExist(vehicle) then
                    DeleteVehicle(vehicle)
                    lib.notify({title = locale('title'), description = locale('delete_vehicle_message'), type = 'success'})
                else
                    lib.notify({title = locale('title'), description = locale('no_vehicles_nearby'), type = 'error'})
                end
            end,
        }
    }
})


lib.registerContext({
    id = 'serversettings',
    title = locale('vehicle_menu_title'),
    menu = 'admin-meni',
    options = {
        {
            title = locale('delete_entity'),
            icon = 'trash',
            onSelect = function()
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local closestObject = GetClosestEntityOfAnyType(coords, Config.DeleteEntityRadius)
                if DoesEntityExist(closestObject) and not IsEntityAMissionEntity(closestObject) then
                    SetEntityAsMissionEntity(closestObject, true, true)
                    DeleteEntity(closestObject)
                    lib.notify({
                        title = locale('title'),
                        description = locale('closest_entity_deleted'),
                        type = 'success'
                    })
                else
                    lib.notify({
                        title = locale('title'),
                        description = locale('no_entities_nearby'),
                        type = 'error'
                    })
                end
            end,
        },  
        {  
                title = locale('delete_ped'),
                icon = 'wrench',
                onSelect = function()
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local success, closestPed = GetClosestPed(coords.x, coords.y, coords.z, Config.DeletePedRadius, 1, 0, 0, 0, -1)
                    if success and DoesEntityExist(closestPed) and not IsPedAPlayer(closestPed) then
                        SetEntityAsMissionEntity(closestPed, true, true)
                        DeleteEntity(closestPed)
                        lib.notify({
                            title = locale('title'),
                            description = locale('ped_deleted'),
                            type = 'success'
                        })
                    else
                        lib.notify({
                            title = locale('title'),
                            description = locale('no_ped_nearby_or_player'),
                            type = 'error'
                        })
                    end
                end,
            }
        },
})

function UpdatePlayerList()
    local onlinePlayers = lib.callback.await('djonza:onlineigraci', false)
    local options = {}

    for _, player in ipairs(onlinePlayers) do
        table.insert(options, {
            title = player.name or "Unknown",
            icon = 'user',
            onSelect = function()
                ShowPlayerDetails(player.source)
            end
        })
    end

    lib.registerContext({
        id = 'playerlist',
        title = locale('player_list_title'),
        menu = 'admin-meni',
        options = options
    })

    lib.showContext('playerlist')
end

function ShowPlayerDetails(playerId)
    local playerData = lib.callback.await('djonza:getPlayerDetails', false, playerId)
    local adminName = GetPlayerName(PlayerId())
    local sessionTime = lib.callback.await('djonza:getSessionTime', false, playerId)
    local totalPlaytime = lib.callback.await('djonza:getTotalPlaytime', false, playerId)
    lib.registerContext({
        id = 'playerdetails',
        title = locale('player_details_title'),
        menu = 'playerlist',
        options = {
                {
                    title = string.format(locale('steam_name'), playerData.steamName or "N/A"),
                    icon = 'user',
                    disabled = true
                },
                {
                    title = string.format(locale('server_id'), playerData.serverId),
                    icon = 'id-card',
                    disabled = true
                },
                {
                    title = string.format(locale('current_session'), sessionTime),
                    icon = 'clock',
                    disabled = true
                },
                {
                    title = string.format(locale('total_playtime'), totalPlaytime),
                    icon = 'hourglass-end',
                    disabled = true
                },
                {
                    title = string.format(locale('bank_money'), playerData.bankMoney),
                    icon = 'money-bill',
                    disabled = true
                },
                {
                    title = string.format(locale('cash_money'), playerData.cashMoney),
                    icon = 'money-bill',
                    disabled = true
                },
                {
                    title = locale('change_job'),
                    icon = 'briefcase',
                    onSelect = function()
                        ShowJobMenu(playerId)
                    end
                },
                {
                    title = locale('spectate'),
                    icon = 'eye',
                    onSelect = function()
                        TriggerServerEvent('djonza:spectatePlayer', playerId)
                    end
                },
                {
                    title = locale('goto'),
                    icon = 'location-arrow',
                    onSelect = function()
                        local success, errorMessage = lib.callback.await('djonza:goto', false, playerId)
                        if success then
                            lib.notify({
                                title = locale('title'),
                                description = locale('teleported_success'),
                                type = 'success'
                            })
                        else
                            lib.notify({
                                title = locale('title'),
                                description = errorMessage,
                                type = 'error'
                            })
                        end
                    end
                },    
                {
                    title = locale('bring'),
                    icon = 'location-arrow',
                    onSelect = function()
                        local success, errorMessage = lib.callback.await('djonza:bring', false, playerId)
                
                        if success then
                            lib.notify({
                                title = locale('title'),
                                description = locale('teleported_success'),
                                type = 'success'
                            })
                        else
                            lib.notify({
                                title = locale('title'),
                                description = errorMessage,
                                type = 'error'
                            })
                        end
                    end
                },                    
            {
                title = locale('kick_player'),
                icon = 'gavel',
                onSelect = function()
                    local input = lib.inputDialog('Kick Player', {locale('reason')})
                    if input and input[1] then
                        TriggerServerEvent('djonza:kickPlayer', playerId, input[1])
                    else
                        lib.notify({
                            title = locale('title'),
                            description = locale('kick_reason_missing'),
                            type = 'error'
                        })
                    end
                end
            },
        }
    })

    lib.showContext('playerdetails')
end



function ShowJobMenu(playerId)
    local jobs = lib.callback.await('djonza:getJobs', false)
    local jobOptions = {}
    for i = 1, #jobs do
        table.insert(jobOptions, {
            title = jobs[i].label,
            onSelect = function()
                local input = lib.inputDialog(locale('job_grade'), {'(0-5)'})
                if input and tonumber(input[1]) then
                    local grade = tonumber(input[1])
                    TriggerServerEvent('djonza:setPlayerJob', playerId, jobs[i].name, grade)
                else
                    lib.notify({
                        title = locale('title'),
                        description = locale('job_grade_error'),
                        type = 'error'
                    })
                end
            end
        })
    end
    lib.registerContext({
        id = 'jobMenu',
        title = locale('choose_job_title'),
        menu = 'playerdetails',
        options = jobOptions
    })

    lib.showContext('jobMenu')
end



function ShowOrganizationMenu()
    local organizationCounts = lib.callback.await('djonza:getOrganizationCounts', false)
    local stateOrgOptions = {}
    for _, org in ipairs(Config.StateOrganizations) do
        local count = organizationCounts[org.name] or 0
        table.insert(stateOrgOptions, {
            title = string.format(locale('organization_active_players'), org.label, count),
            icon = 'building',
            onSelect = function()
                ShowPlayersInOrganization(org.name, org.label)
            end
        })
    end

    local orgOptions = {}
    for _, org in ipairs(Config.Organizations) do
        local count = organizationCounts[org.name] or 0
        table.insert(orgOptions, {
            title = string.format(locale('organization_active_players'), org.label, count),
            icon = 'users',
            onSelect = function()
                ShowPlayersInOrganization(org.name, org.label)
            end
        })
    end

    lib.registerContext({
        id = 'organization_main_menu',
        title = locale('organization_list'),
        menu = 'admin-meni',
        options = {
            {
                title = locale('state_organizations'),
                menu = 'state_organization_menu'
            },
            {
                title = locale('organizations'),
                menu = 'organization_menu'
            }
        }
    })
    lib.registerContext({
        id = 'state_organization_menu',
        title = locale('state_organizations'),
        menu = 'organization_main_menu',
        options = stateOrgOptions
    })
    lib.registerContext({
        id = 'organization_menu',
        title = locale('organizations'),
        menu = 'organization_main_menu',
        options = orgOptions
    })

    lib.showContext('organization_main_menu')
end

function ShowPlayersInOrganization(jobName, jobLabel)
    local players = lib.callback.await('djonza:getPlayersInOrganization', false, jobName)
    local playerOptions = {}
    for _, player in ipairs(players) do
        table.insert(playerOptions, {
            title = player.name .. " (" .. player.jobGrade .. ")",
            description = "ID: " .. player.id,
            icon = 'user',
            onSelect = function()
                lib.notify({
                    title = player.name,
                    description = locale('player_selected', {name = player.name}),
                    type = 'info'
                })
            end
        })
    end
    lib.registerContext({
        id = 'players_in_organization_menu',
        title = jobLabel .. " Players",
        menu = 'organization_main_menu',
        options = playerOptions
    })
    lib.showContext('players_in_organization_menu')
end



function ShowAdminHelpMenu()
    local helpRequests = lib.callback.await('djonza:getAdminHelpRequests', false)
    local helpOptions = {}
    for i = 1, #helpRequests do
        table.insert(helpOptions, {
            title = locale('player'), "" .. helpRequests[i].playerName,
            description = string.format(locale('help_request_description'), helpRequests[i].reason, helpRequests[i].timestamp),
            onSelect = function()
                TriggerServerEvent('djonza:adminRespondToHelp', i)
                TriggerServerEvent('djonza:goto', helpRequests[i].playerId)
                lib.notify({
                    title = locale('title'),
                    description = locale('report_answered') .. helpRequests[i].playerName,
                    type = 'success'
                })
            end
        })
    end
    lib.registerContext({
        id = 'adminHelpMenu',
        title = locale('reports_request'),
        options = helpOptions
    })

    lib.showContext('adminHelpMenu')
end

RegisterNetEvent('djonza:notifyAdminsNewHelpRequest')
AddEventHandler('djonza:notifyAdminsNewHelpRequest', function(playerName, reason)
    local isAdmin = exports['adminmenu']:IsPlayerAdminAndOnDuty()
    if isAdmin then
        lib.notify({
            title = locale('new_help_request'),
            description = string.format(locale('help_request_details'), playerName, reason),
            type = 'info'
        })
    end
end)


RegisterCommand('showreports', function(source)
    if exports['adminmenu']:IsPlayerAdminAndOnDuty(source) then
        ShowAdminHelpMenu()
    else
        lib.notify({
            title = locale('title'),
            description = locale('no_access'),
            type = 'error'
        })
    end
end, false)
function ShowAdminHelpMenu()
    local helpRequests = lib.callback.await('djonza:getAdminHelpRequests', false)
    local helpOptions = {}
    for i = 1, #helpRequests do
        table.insert(helpOptions, {
            title = string.format(locale('player_request_title'), helpRequests[i].playerName),
            description = string.format(locale('player_request_description'), helpRequests[i].reason, helpRequests[i].timestamp),       
            onSelect = function()
                ShowHelpOptionsForPlayer(helpRequests[i])
            end
        })
    end
    lib.registerContext({
        id = 'adminHelpMenu',
        title = locale('reports_request'),
        options = helpOptions
    })

    lib.showContext('adminHelpMenu')
end

function ShowHelpOptionsForPlayer(requestIndex, helpRequest)
    lib.registerContext({
        id = 'helpOptionsMenu',
        title = 'Opcije za ' .. helpRequest.playerName,
        menu = 'adminHelpMenu',
        options = {
            {
                title = locale('bring'),
                icon = 'hand-paper',
                onSelect = function()
                    TriggerServerEvent('djonza:adminRespondToHelp', requestIndex)
                    lib.callback('djonza:bring', false, function(success, errorMessage)
                        if success then
                            return true
                        else
                            return false
                        end
                    end, helpRequest.playerId)
                end
            },
            {
                title = locale('goto'),
                icon = 'location-arrow',
                onSelect = function()
                    TriggerServerEvent('djonza:adminRespondToHelp', requestIndex)
                    lib.callback('djonza:goto', false, function(success, errorMessage)
                        if success then
                            return true
                        else
                            return false
                        end
                    end, helpRequest.playerId)
                end
            },
            {
                title = locale('private_message_title'),
                icon = 'envelope',
                onSelect = function()
                    local input = lib.inputDialog(locale('private_message_title'), {locale('enter_message')})
                    if input and input[1] then
                        TriggerServerEvent('djonza:adminRespondToHelp', requestIndex)
                        TriggerServerEvent('djonza:sendPrivateMessage', helpRequest.playerId, input[1])
                    else
                        lib.notify({
                            title = locale('title'),
                            description = locale('message_input_error'),
                            type = 'error'
                        })
                    end
                end
            },
            {
                title = locale('heal_player_title'),
                icon = 'medkit',
                onSelect = function()
                    TriggerServerEvent('djonza:adminRespondToHelp', requestIndex)
                    TriggerServerEvent('djonza:healPlayer', helpRequest.playerId)
                end
            },
            {
                title = locale('revive_player_title'),
                icon = 'heartbeat',
                onSelect = function()
                    TriggerServerEvent('djonza:adminRespondToHelp', requestIndex)
                    TriggerServerEvent('djonza:revivePlayer', helpRequest.playerId)
                end
            },
            {
                description = locale('delete_report'),
                icon = 'circle',
                onSelect = function()
                    TriggerServerEvent('djonza:deleteHelpRequest', requestIndex)
                end
            }
        }
    })

    lib.showContext('helpOptionsMenu')
end
function ShowAdminHelpMenu()
    local helpRequests = lib.callback.await('djonza:getAdminHelpRequests', false)
    
    local helpOptions = {}
    for i = 1, #helpRequests do
        table.insert(helpOptions, {
            title = string.format(locale('player'), helpRequests[i].playerName),
            description = string.format(locale('help_request_description'), helpRequests[i].reason, helpRequests[i].timestamp),           
            onSelect = function()
                ShowHelpOptionsForPlayer(i, helpRequests[i])
            end
        })
    end

    lib.registerContext({
        id = 'adminHelpMenu',
        title = locale('reports_request'),
        options = helpOptions
    })

    lib.showContext('adminHelpMenu')
end


RegisterNetEvent('djonza:client:goto')
AddEventHandler('djonza:client:goto', function(coords)
    local playerPed = PlayerPedId() 
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Citizen.Wait(0)
    end
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
end)


local isSpectating = false 

RegisterNetEvent('djonza:startSpectate')
AddEventHandler('djonza:startSpectate', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    local playerPed = PlayerPedId()

    NetworkSetInSpectatorMode(true, targetPed)
    isSpectating = true

    SetEntityInvincible(playerPed, true)
    SetEntityVisible(playerPed, false, false)
    SetEntityAlpha(playerPed, 0, false)

    lib.notify({
        title = locale('spectate_started'),
        description = string.format(locale('spectating_player'), GetPlayerName(GetPlayerFromServerId(targetId))),
        type = 'success'
    })


    Citizen.CreateThread(function()
        while isSpectating do
            Citizen.Wait(0)
            if IsControlJustReleased(0, 177) then 
                NetworkSetInSpectatorMode(false, targetPed)
                SetEntityInvincible(playerPed, false)
                SetEntityVisible(playerPed, true, true)
                ResetEntityAlpha(playerPed)
                isSpectating = false
            end
        end
    end)
end)







RegisterCommand('adminhelp', function()
    local input = lib.inputDialog(locale('request_help'), {locale('report_reason')})

    if input and input[1] then
        TriggerServerEvent('djonza:sendAdminHelpRequest', input[1])
        lib.notify({
            title = locale('new_report_title'),
            description = locale('report_sent'),
            type = 'success'
        })
    else
        lib.notify({
            title = locale('title'),
            description = locale('no_reason'),
            type = 'error'
        })
    end
end)

function GetClosestEntityOfAnyType(coords, radius)
    local closestDistance = radius
    local closestEntity = nil
    for obj in EnumerateObjects() do
        local objCoords = GetEntityCoords(obj)
        local distance = #(coords - objCoords)

        if distance < closestDistance then
            closestDistance = distance
            closestEntity = obj
        end
    end

    return closestEntity
end

function EnumerateObjects()
    return coroutine.wrap(function()
        local handle, object = FindFirstObject()
        if handle then
            local success
            repeat
                coroutine.yield(object)
                success, object = FindNextObject(handle)
            until not success
            EndFindObject(handle)
        end
    end)
end

RegisterCommand("adminmenu", function()
    local isAdminOnDuty = exports['adminmenu']:IsPlayerAdminAndOnDuty()
    if isAdminOnDuty then
        lib.showContext('admin-meni')
    else
        lib.notify({
            title = locale('title'),
            description = locale('no_access'),
            type = "error"
        })
    end
end)

