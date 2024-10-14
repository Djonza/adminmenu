ESX = exports["es_extended"]:getSharedObject()

local resourceName = GetCurrentResourceName()
local dutyFilePath = GetResourcePath(resourceName) .. "/" .. Config.DutyDataPath

lib.locale()

local adminDutyPlayers = {}


function IsPlayerAdminAndOnDuty(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then
        local playerGroup = xPlayer.getGroup()
        for _, group in ipairs(Config.AdminGroups) do
            if playerGroup == group then
                if adminDutyPlayers[source] then
                    return true
                end
            end
        end
    end
    return false
end


exports('IsPlayerAdminAndOnDuty', function(source)
    return IsPlayerAdminAndOnDuty(source)
end)


local function getDayColumn()
    local daysOfWeek = {"sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"}
    return daysOfWeek[tonumber(os.date("%w")) + 1]
end

local function getCurrentWeek()
    return os.date("%V") 
end

local function getFileName(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    return identifiers[1] .. ".json" 
end

local function resetDutyData()
    return {
        monday = 0, tuesday = 0, wednesday = 0, thursday = 0,
        friday = 0, saturday = 0, sunday = 0, total_time_overall = 0,
        week_number = getCurrentWeek()
    }
end

local function loadAdminDutyData(playerId)
    local fileName = getFileName(playerId)
    local file = LoadResourceFile(resourceName, Config.DutyDataPath .. fileName)

    if file then
        local dutyData = json.decode(file)
        local currentWeek = getCurrentWeek()

        if dutyData.week_number ~= currentWeek then
            dutyData = resetDutyData() 
        end
        return dutyData
    else
        return resetDutyData()
    end
end

local function saveAdminDutyData(playerId, dutyData)
    local fileName = getFileName(playerId)
    SaveResourceFile(resourceName, Config.DutyDataPath .. fileName, json.encode(dutyData, { indent = true }), -1)
end

local function logAdminDutyStart(playerId)
    local timeStart = os.time()
    adminDutyPlayers[playerId] = { startTime = timeStart }

    local xPlayer = ESX.GetPlayerFromId(playerId)
    local adminGroup = xPlayer.getGroup()
    local steamName = GetPlayerName(playerId)

    local messageTemplate = locale('enter_duty_message_players')
    local message = string.gsub(messageTemplate, "{adminGroup}", adminGroup)
    message = string.gsub(message, "{steamName}", steamName)
    TriggerClientEvent('chat:addMessage', -1, { args = {locale('server_name'), message}})
    TriggerClientEvent('djonza:client:setAdminDutyStatus', playerId, true)

    TriggerClientEvent('ox_lib:notify', playerId, {
        title = "Admin Duty",
        description = locale('enter_duty_message'),
        type = "success"
    })
end
local function logAdminDutyEnd(playerId)
    if not adminDutyPlayers[playerId] then return end

    local timeEnd = os.time()
    local timeStart = adminDutyPlayers[playerId].startTime
    local totalTime = math.floor((timeEnd - timeStart) / 60)
    local dayColumn = getDayColumn()
    local dutyData = loadAdminDutyData(playerId)
    dutyData[dayColumn] = (dutyData[dayColumn] or 0) + totalTime
    dutyData.total_time_overall = (dutyData.total_time_overall or 0) + totalTime
    
    saveAdminDutyData(playerId, dutyData)

    local xPlayer = ESX.GetPlayerFromId(playerId)
    local adminGroup = xPlayer.getGroup()
    local steamName = GetPlayerName(playerId)
    local message = string.format(locale('exit_duty_message_players'), adminGroup, steamName)
    TriggerClientEvent('chat:addMessage', -1, { args = {locale('server_name'), message}})
    
    TriggerClientEvent('djonza:client:setAdminDutyStatus', playerId, false)
    TriggerClientEvent('ox_lib:notify', playerId, {
        description = locale('exit_duty_message'),
        type = "error"
    })
    adminDutyPlayers[playerId] = nil
end
 
RegisterCommand('aduty', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            if adminDutyPlayers[source] then
                logAdminDutyEnd(source)
            else
                logAdminDutyStart(source)
            end
            return
        end
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = "Access Denied",
        description = locale('no_access'),
        type = "error"
    })
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    if adminDutyPlayers[playerId] then
        logAdminDutyEnd(playerId)
    end
end)

RegisterCommand('admindutytime', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)

    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            local targetPlayerId = tonumber(args[1])
            local dutyData = loadAdminDutyData(targetPlayerId)

            if dutyData then
                lib.notify({
                    title = "Admin Duty Time",
                    description = string.format("Duty time (in minutes):\nMonday: %d\nTuesday: %d\nWednesday: %d\nThursday: %d\nFriday: %d\nSaturday: %d\nSunday: %d\nTotal: %d", 
                        dutyData.monday, dutyData.tuesday, dutyData.wednesday, dutyData.thursday, dutyData.friday, dutyData.saturday, dutyData.sunday, dutyData.total_time_overall),
                    type = "inform",
                    position = "top-right",
                    duration = 8000
                })
            else
                lib.notify({
                    title = "Admin Duty",
                    description = locale('no_duty_data'),
                    type = "warning",
                    position = "top-right",
                    duration = 5000
                })
            end
            return
        end
    end

    lib.notify({
        description = locale('no_access'),
        type = "error",
        position = "top-right",
        duration = 5000
    })
end)

RegisterCommand('adminlista', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)

    for _, group in ipairs(Config.AdminGroups) do
        if xPlayer.getGroup() == group then
            local adminList = {}
            local players = ESX.GetExtendedPlayers()

            for _, xTarget in ipairs(players) do
                if xTarget.getGroup() == "admin" or xTarget.getGroup() == "superadmin" then
                    local playerId = xTarget.source
                    local onDuty = IsPlayerAdminAndOnDuty(playerId) and 'On Duty' or 'Off Duty'
                    table.insert(adminList, {
                        name = GetPlayerName(playerId),
                        status = onDuty
                    })
                end
            end
            TriggerClientEvent('djonza:client:adminlist', source, adminList)
            return
        end
    end

    lib.notify({
        description = locale('no_access'),
        type = "error",
        position = "top-right",
        duration = 5000
    })
end)
