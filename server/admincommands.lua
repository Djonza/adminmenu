lib.locale() 


RegisterCommand('admingoto', function(source, args)
    local adminId = source
    local targetPlayerId = tonumber(args[1])
    local isAdminOnDuty = exports['adminmenu']:IsPlayerAdminAndOnDuty(adminId)
    if isAdminOnDuty then
        if targetPlayerId then
            if targetPlayerId == adminId then
                TriggerClientEvent('ox_lib:notify', adminId, {
                    title = "Error",
                    description = locale('teleport_to_self'),
                    type = "error"
                })
                return
            end
            if GetPlayerPing(targetPlayerId) > 0 then
                local targetPed = GetPlayerPed(targetPlayerId)
                if targetPed and DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    if targetCoords and targetCoords.x ~= 0 and targetCoords.y ~= 0 and targetCoords.z ~= 0 then
                        TriggerClientEvent('djonza:client:goto', adminId, targetCoords)
                        local adminName = GetPlayerName(adminId)
                        local targetName = GetPlayerName(targetPlayerId)
                        TriggerClientEvent('ox_lib:notify', adminId, {
                            title = locale('title'),
                            description = locale('teleported_to_player', { targetName = targetName }),
                            type = "success"
                        })

                        TriggerClientEvent('ox_lib:notify', targetPlayerId, {
                            title = locale('title'),
                            description = locale('admin_teleported_to_you', { adminName = adminName }),
                            type = "success"
                        })
                    else
                        TriggerClientEvent('ox_lib:notify', adminId, {
                            title = locale('title'),
                            description = locale('invalid_coordinates'),
                            type = "error"
                        })
                    end
                else
                    TriggerClientEvent('ox_lib:notify', adminId, {
                        title = locale('title'),
                        description = locale('player_not_found', { id = targetPlayerId }),
                        type = "error"
                    })
                end
            else
                TriggerClientEvent('ox_lib:notify', adminId, {
                    title = locale('title'),
                    description = locale('player_not_found', { id = targetPlayerId }),
                    type = "error"
                })
            end
        else
            -- Notify the admin if the ID is invalid
            TriggerClientEvent('ox_lib:notify', adminId, {
                title = locale('title'),
                description = locale('invalid_command_usage'),
                type = "error"
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', adminId, {
            title = locale('title'),
            description = locale('no_access'),
            type = "error"
        })
    end
end)
RegisterCommand('adminbring', function(source, args)
    local adminId = source
    local targetPlayerId = tonumber(args[1])
    local isAdminOnDuty = exports['adminmenu']:IsPlayerAdminAndOnDuty(adminId)
    if isAdminOnDuty then
        if targetPlayerId then
            if targetPlayerId == adminId then
                TriggerClientEvent('ox_lib:notify', adminId, {
                    title = locale('title'),
                    description = locale('teleport_to_self'),
                    type = "error"
                })
                return
            end
            if GetPlayerPing(targetPlayerId) > 0 then
                local adminPed = GetPlayerPed(adminId)
                if adminPed and DoesEntityExist(adminPed) then
                    local adminCoords = GetEntityCoords(adminPed)
                    if adminCoords and adminCoords.x ~= 0 and adminCoords.y ~= 0 and adminCoords.z ~= 0 then
                        TriggerClientEvent('djonza:client:bring', targetPlayerId, adminCoords)
                        local adminName = GetPlayerName(adminId)
                        local targetName = GetPlayerName(targetPlayerId)
                        TriggerClientEvent('ox_lib:notify', adminId, {
                            title = locale('title'),
                            description = locale('teleported_to_player', { targetName = targetName }),
                            type = "success"
                        })
                        TriggerClientEvent('ox_lib:notify', targetPlayerId, {
                            title = locale('title'),
                            description = locale('admin_teleported_to_you', { adminName = adminName }),
                            type = "success"
                        })
                    else
                        TriggerClientEvent('ox_lib:notify', adminId, {
                            title = locale('title'),
                            description = locale('invalid_coordinates'),
                            type = "error"
                        })
                    end
                else
                    TriggerClientEvent('ox_lib:notify', adminId, {
                        title = locale('title'),
                        description = locale('admin_not_found'),
                        type = "error"
                    })
                end
            else
                TriggerClientEvent('ox_lib:notify', adminId, {
                    title = locale('title'),
                    description = locale('player_not_found', { id = targetPlayerId }),
                    type = "error"
                })
            end
        else
            TriggerClientEvent('ox_lib:notify', adminId, {
                title = locale('title'),
                description = locale('invalid_command_usage'),
                type = "error"
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', adminId, {
            title = locale('title'),
            description = locale('no_access'),
            type = "error"
        })
    end
end)

RegisterCommand("warn", function(source, args, rawCommand)
    local isAdmin = exports['adminmenu']:IsPlayerAdminAndOnDuty(source)

    if isAdmin then
        local xPlayer = ESX.GetPlayerFromId(source)
        local targetId = tonumber(args[1])
        local reason = table.concat(args, " ", 2)

        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if not targetPlayer then
            lib.notify({
                title = locale('title'),
                description = locale('player_not_found', { id = targetId }),
                type = 'error'
            })
            return
        end
        local targetIdentifier = targetPlayer.getIdentifier()
        MySQL.Async.fetchAll('SELECT warn_count, last_reason FROM warnings WHERE license = @license', {
            ['@license'] = targetIdentifier
        }, function(result)
            if result[1] then
                local warnCount = result[1].warn_count
                local updatedReasons = result[1].last_reason .. '\n' .. reason
                MySQL.Async.execute('UPDATE warnings SET warn_count = warn_count + 1, last_reason = @reason, last_admin_id = @admin_id, last_timestamp = NOW() WHERE license = @license', {
                    ['@license'] = targetIdentifier,
                    ['@admin_id'] = xPlayer.identifier,
                    ['@reason'] = updatedReasons
                }, function(affectedRows)
                    if affectedRows > 0 then
                        print("Warn updated for player: " .. targetPlayer.name)
                        TriggerClientEvent('chat:addMessage', source, { args = { '^2SYSTEM', 'Player ' .. targetPlayer.name .. ' has been warned for: ' .. reason .. '. Total warnings: ' .. (warnCount + 1) } })
                        TriggerClientEvent('chat:addMessage', targetId, { args = { '^1SYSTEM', 'You have been warned for: ' .. reason .. '. You have: ' .. (warnCount + 1) .. ' warns.' } })
                    else
                        TriggerClientEvent('ox_lib:notify', source, {
                            title = locale('title'),
                            description = locale('error'),
                            type = 'error'
                        })
                    end
                end)
            else
                -- Ubacivanje novog reda
                MySQL.Async.execute('INSERT INTO warnings (license, warn_count, last_reason, last_admin_id) VALUES (@license, 1, @reason, @admin_id)', {
                    ['@license'] = targetIdentifier,
                    ['@admin_id'] = xPlayer.identifier,
                    ['@reason'] = reason
                }, function(affectedRows)
                    if affectedRows > 0 then
                        print("New warn added for: " .. targetPlayer.name)
                        TriggerClientEvent('chat:addMessage', source, { args = { '^2SYSTEM', 'Player ' .. targetPlayer.name .. ' has been warned for: ' .. reason .. '. Total warnings: ' .. (warnCount + 1) } })
                        TriggerClientEvent('chat:addMessage', targetId, { args = { '^1SYSTEM', 'You have been warned for: ' .. reason .. '. You have: ' .. (warnCount + 1) .. ' warns.' } })
                    else
                        TriggerClientEvent('ox_lib:notify', source, {
                            title = locale('title'),
                            description = locale('error'),
                            type = 'error'
                        })
                    end
                end)
            end
        end)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = locale('title'),
            description = locale('no_access')
        })
    end
end)




RegisterCommand("checkwarns", function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = locale('title'),
            description = locale('player_not_found')
        })
        return
    end

    local isAdmin = exports['adminmenu']:IsPlayerAdminAndOnDuty(source)

    if not isAdmin then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = locale('title'),
            description = locale('no_access')
        })
            return
        end
        local targetPlayer = ESX.GetPlayerFromId(targetId)
        if not targetPlayer then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                title = locale('title'),
                description = locale('player_not_found')
            })
            return
        end
        local targetIdentifier = targetPlayer.getIdentifier() 
        MySQL.Async.fetchAll('SELECT * FROM warnings WHERE license = @license', {
            ['@license'] = targetIdentifier
        }, function(result)
            if result[1] then
                local warning = result[1]
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^2SYSTEM', 'Player has ' .. warning.warn_count .. ' warms. Reasons:\n' .. warning.last_reason .. '\nLast admin: ' .. warning.last_admin_id .. ' | last warn date: ' .. warning.last_timestamp }
                })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = locale('title'),
                    description = locale('no_warns'),
                    type = 'error',
                })
            end
        end)
    end)


    RegisterCommand('kick', function(source, args)
        local xPlayer = ESX.GetPlayerFromId(source)
        if exports['adminmenu']:IsPlayerAdminAndOnDuty(source) then
            local targetId = tonumber(args[1])
            local reason = table.concat(args, " ", 2)
            if targetId and reason ~= "" then
                local targetPlayer = ESX.GetPlayerFromId(targetId)
                if targetPlayer then
                    DropPlayer(targetId, "You have been kicked by " .. GetPlayerName(source) .. " for: " .. reason)
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Kick Success',
                        description = 'You have kicked player ' .. GetPlayerName(targetId) .. ' for: ' .. reason,
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Error',
                        title = locale('title'),
                        description = locale('player_not_found', {id = targetId}),
                        type = 'error'
                    })
                end
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Error',
                    title = locale('title'),
                    description = locale('kick_usage'),
                    type = 'error'
                })
            end
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Error',
                title = locale('title'),
                description = locale('no_access'),
                type = 'error'
            })
        end
    end)
    