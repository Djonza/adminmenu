local playerSessionTimes = {}

-- Event za praćenje prijave igrača
AddEventHandler('esx:playerLoaded', function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        playerSessionTimes[playerId] = {
            loginTime = os.time(),
            totalPlaytime = 0 
        }
        
        MySQL.Async.fetchScalar('SELECT playtime FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
        end)
    end
end)

AddEventHandler('esx:playerDropped', function(reason)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer and playerSessionTimes[playerId] then
        local sessionTime = os.time() - playerSessionTimes[playerId].loginTime
        local newTotalPlaytime = playerSessionTimes[playerId].totalPlaytime + sessionTime

        -- Ažuriranje ukupnog vremena u bazi
        MySQL.Async.execute('UPDATE users SET playtime = @playtime WHERE identifier = @identifier', {
            ['@playtime'] = newTotalPlaytime,
            ['@identifier'] = xPlayer.identifier
        }, function(affectedRows)
        end)
        playerSessionTimes[playerId] = nil
    end
end)

local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, remainingSeconds)
end


lib.callback.register('djonza:getSessionTime', function(source, playerId)
    if playerSessionTimes[playerId] then
        local sessionTime = os.time() - playerSessionTimes[playerId].loginTime
        return formatTime(sessionTime)
    end
    return formatTime(0) 
end)


lib.callback.register('djonza:getTotalPlaytime', function(source, playerId)
    if playerSessionTimes[playerId] then
        local totalPlaytime = playerSessionTimes[playerId].totalPlaytime
        return formatTime(totalPlaytime)
    end
    return formatTime(0)
end)



AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local players = ESX.GetPlayers()

        for _, playerId in ipairs(players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                MySQL.Async.fetchScalar('SELECT playtime FROM users WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                }, function(result)
                    if result then
                        playerSessionTimes[playerId] = {
                            loginTime = os.time(),
                            totalPlaytime = tonumber(result)
                        }
                        print("Session restored for player: " .. xPlayer.identifier)
                    end
                end)
            end
        end
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for playerId, data in pairs(playerSessionTimes) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                local sessionTime = os.time() - data.loginTime
                local newTotalPlaytime = data.totalPlaytime + sessionTime
                MySQL.Async.execute('UPDATE users SET playtime = @playtime WHERE identifier = @identifier', {
                    ['@playtime'] = newTotalPlaytime,
                    ['@identifier'] = xPlayer.identifier
                }, function(affectedRows)
                    if affectedRows > 0 then
                        print("Playtime saved for player: " .. xPlayer.identifier)
                    end
                end)
            end
        end
    end
end)
