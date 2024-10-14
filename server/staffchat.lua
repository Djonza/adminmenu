local function isAdminGroup(group)
    for _, allowedGroup in ipairs(Config.AdminGroups) do
        if group == allowedGroup then
            return true
        end
    end
    return false
end


local function getGroupColor(group)
    return Config.GroupColors[group] or Config.GroupColors.default
end

local function sendStaffMessage(source, message)
    local players = ESX.GetPlayers()
    local xPlayerSender = ESX.GetPlayerFromId(source)
    local groupSender = xPlayerSender.getGroup()
    local playerNameSender = GetPlayerName(source)
    local groupColor = getGroupColor(groupSender)

    -- Loop through all players and send the message to allowed groups
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        local group = xPlayer.getGroup()

        if isAdminGroup(group) then
            TriggerClientEvent('chat:addMessage', playerId, {
                args = {string.format("[%s] %s: %s", groupSender, playerNameSender, message)},
                color = groupColor
            })
        end
    end
end


-- /a command for staff chat
RegisterCommand('a', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    local group = xPlayer.getGroup()

    if isAdminGroup(group) then
        local message = table.concat(args, " ")
        if message and message ~= "" then
            sendStaffMessage(source, message)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = locale('title'),
                description = locale('message_input_error'),
                type = "error"
            })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('title'),
            description = locale('no_access'),
            type = "error"
        })
    end
end, false)

