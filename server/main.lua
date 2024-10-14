ESX = exports["es_extended"]:getSharedObject()


lib.callback.register('djonza:onlineigraci', function()
    local players = GetPlayers()
    local data = {}
    for _, src in ipairs(players) do
        data[#data + 1] = {
            source = tonumber(src),
            name = GetPlayerName(src)
        }
    end
    return data
end)

lib.callback.register('djonza:getPlayerDetails', function(source, targetPlayerId)
    local xPlayer = ESX.GetPlayerFromId(targetPlayerId)
    if xPlayer then
        return {
            steamName = GetPlayerName(targetPlayerId),
            serverId = targetPlayerId,
            bankMoney = xPlayer.getAccount('bank').money,
            cashMoney = xPlayer.getMoney()
        }
    else
        return nil
    end
end)

lib.callback.register('djonza:getJobs', function()
    local jobs = {}

    local result = MySQL.Sync.fetchAll('SELECT * FROM jobs')
    
    for i = 1, #result do
        table.insert(jobs, {
            name = result[i].name, 
            label = result[i].label 
        })
    end

    return jobs
end)


lib.callback.register('djonza:getOrganizationCounts', function()
    local counts = {}
    for _, org in ipairs(Config.StateOrganizations) do
        counts[org.name] = 0
    end
    for _, org in ipairs(Config.Organizations) do
        counts[org.name] = 0
    end
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        local jobName = xPlayer.job.name

        if counts[jobName] ~= nil then
            counts[jobName] = counts[jobName] + 1
        end
    end
    return counts
end)

lib.callback.register('djonza:getPlayersInOrganization', function(source, jobName)
    local players = {}
    local onlinePlayers = ESX.GetPlayers()
    for _, playerId in ipairs(onlinePlayers) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer.job.name == jobName then
            table.insert(players, {
                name = xPlayer.getName(),
                jobGrade = xPlayer.job.grade_label,
                id = playerId
            })
        end
    end

    return players
end)


lib.callback.register('djonza:goto', function(source, playerId)
    local sourcePlayer = source

    local isAdmin, errorMessage = IsPlayerAdminAndOnDuty(sourcePlayer)

    if isAdmin then
        print("Admin status confirmed for player: " .. sourcePlayer)
        local adminName = GetPlayerName(sourcePlayer)
        local playerName = GetPlayerName(playerId)
        local targetCoords = GetEntityCoords(GetPlayerPed(playerId))

        print("Teleporting to coordinates: " .. targetCoords.x .. ", " .. targetCoords.y .. ", " .. targetCoords.z)
        TriggerClientEvent('djonza:client:goto', sourcePlayer, targetCoords)
        SendToDiscord(
            Config.DiscordWebhook.teleport,
            "Player Teleported",
            GetPlayerName(source) .. " teleported to " .. GetPlayerName(playerId),
            65280 
        )
        TriggerClientEvent('lib:notify', sourcePlayer, {
            title = locale('title'),
            description = "teleported_success",
            type = "success"
        })

        return true
    else
        print("Admin status failed for player: " .. sourcePlayer .. " - " .. errorMessage)
        TriggerClientEvent('lib:notify', sourcePlayer, {
            title = locale('title'),
            description = errorMessage,
            type = "error"
        })

        return false, errorMessage
    end
end)


lib.callback.register('djonza:bring', function(sourcePlayer, targetPlayerId)
    local isAdmin, errorMessage = IsPlayerAdminAndOnDuty(sourcePlayer)

    if isAdmin then
        local adminCoords = GetEntityCoords(GetPlayerPed(sourcePlayer))
        TriggerClientEvent('djonza:client:goto', targetPlayerId, adminCoords)
        TriggerClientEvent('lib:notify', sourcePlayer, {
            title = locale('title'),
            description = string.format(locale('player_brought'), GetPlayerName(targetPlayerId)),
            type = "success"
        })

        TriggerClientEvent('lib:notify', targetPlayerId, {
            title = locale('title'),
            description = string.format(locale('player_brought_you'), GetPlayerName(sourcePlayer)),
            type = "inform"
        })
        return true
    else
        return false, errorMessage
    end
end)



RegisterServerEvent('djonza:sendPrivateMessage')
AddEventHandler('djonza:sendPrivateMessage', function(targetPlayerId, message)
    local senderId = source
    local isAdmin, errorMessage = IsPlayerAdminAndOnDuty(senderId)
    if isAdmin then
        local senderName = GetPlayerName(senderId)
        local xPlayer = ESX.GetPlayerFromId(senderId)
        local grupa = xPlayer.getGroup()

        -- Send the message
        TriggerClientEvent('chat:addMessage', targetPlayerId, {
            args = {string.format(locale('private_message'), grupa, senderName)},
            color = {139, 0, 0}
        })
        TriggerClientEvent('chat:addMessage', targetPlayerId, { args = {message}, color = {255, 255, 255} })

        TriggerClientEvent('lib:notify', senderId, {
            title = locale('title'),
            description = string.format(locale('private_message_sent'), GetPlayerName(targetPlayerId)),
            type = 'success'
        })
    else
        TriggerClientEvent('lib:notify', senderId, {
            title = locale('title'),
            description = errorMessage,
            type = "error"
        })
    end
end)


RegisterServerEvent('djonza:revivePlayer')
AddEventHandler('djonza:revivePlayer', function(targetId, adminName)
    local targetPlayerName = GetPlayerName(targetId)
    TriggerClientEvent('esx_ambulancejob:revive', targetId)
end)

RegisterServerEvent('djonza:healPlayer')
AddEventHandler('djonza:healPlayer', function(targetId, adminName)
    TriggerClientEvent('esx_basicneeds:healPlayer', targetId)
end)


RegisterServerEvent('djonza:setPlayerJob')
AddEventHandler('djonza:setPlayerJob', function(playerId, job, grade)
    local xPlayer = ESX.GetPlayerFromId(playerId)

    if xPlayer then
        xPlayer.setJob(job, grade)

        TriggerClientEvent('ox_lib:notify', playerId, {
            title = locale('new_job_title'),
            description = string.format(locale('new_job_description'), job, grade),
            type = "info"
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('title'),
            description = locale('no_player_found'),
            type = "error"
        })
    end
end)



RegisterServerEvent('djonza:spectatePlayer')
AddEventHandler('djonza:spectatePlayer', function(targetId)
    local sourceId = source
    local targetPlayer = GetPlayerName(targetId)

    if targetPlayer then
        TriggerClientEvent('djonza:startSpectate', sourceId, targetId)
    else
        TriggerClientEvent('ox_lib:notify', sourceId, {
            title = locale('title'),
            description = locale('no_player_found'),
            type = 'error'
        })
    end
end)








RegisterServerEvent('djonza:kickPlayer')
AddEventHandler('djonza:kickPlayer', function(playerId, reason)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if exports['adminmenu']:IsPlayerAdminAndOnDuty(source) then
        local targetPlayer = ESX.GetPlayerFromId(playerId)
        if targetPlayer then
            DropPlayer(playerId, string.format(locale('player_kicked_message'), GetPlayerName(source), reason))
            TriggerClientEvent('ox_lib:notify', source, {
                title = locale('title'),
                description = string.format(locale('player_kicked_by_admin'), GetPlayerName(playerId), reason),
                type = 'success'
            })

            -- Slanje loga na Discord
            SendToDiscord(
                Config.DiscordWebhook.kick,
                locale('player_kicked_title'),
                string.format(locale('player_kicked_discord_message'), GetPlayerName(source), GetPlayerName(playerId), reason),
                16711680
            )            
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = locale('title'),
                description = locale('player_not_found', {id = playerId}),
                type = 'error'
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('title'),
            description = locale('no_access'),
            type = 'error'
        })
    end
end)



function SendToDiscord(webhook, title, message, color)
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["color"] = color, 
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S"), 
            },
        }
    }

    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Admin Logs", 
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

