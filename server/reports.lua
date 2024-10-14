local adminHelpRequests = {}


RegisterServerEvent('djonza:sendAdminHelpRequest')
AddEventHandler('djonza:sendAdminHelpRequest', function(reason)
    local playerId = source
    local playerName = GetPlayerName(playerId)
    
    table.insert(adminHelpRequests, {
        playerId = playerId,
        playerName = playerName,
        reason = reason,
        timestamp = os.date('%Y-%m-%d %H:%M:%S')
    })
    
    TriggerClientEvent('djonza:notifyAdminsNewHelpRequest', -1, playerName, reason)
end)

lib.callback.register('djonza:getAdminHelpRequests', function(source)
    return adminHelpRequests
end)

RegisterServerEvent('djonza:adminRespondToHelp')
AddEventHandler('djonza:adminRespondToHelp', function(requestIndex)
    local adminId = source
    local xAdmin = ESX.GetPlayerFromId(adminId)
    local helpRequest = adminHelpRequests[requestIndex]

    if helpRequest then
        table.remove(adminHelpRequests, requestIndex)
        MySQL.Async.fetchScalar('SELECT resolved_reports FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xAdmin.identifier
        }, function(currentReports)
            local newReportCount = (currentReports or 0) + 1
            MySQL.Async.execute('UPDATE users SET resolved_reports = @resolved_reports WHERE identifier = @identifier', {
                ['@resolved_reports'] = newReportCount,
                ['@identifier'] = xAdmin.identifier
            }, function(affectedRows)
                if affectedRows > 0 then
                    TriggerClientEvent('ox_lib:notify', adminId, {
                        title = locale('report_resolved_title'),
                        description = string.format(locale('report_resolved_description'), newReportCount),
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', adminId, {
                        title = locale('title'),
                        description = locale('report_update_failed'),
                        type = 'error'
                    })
                end
            end)
        end)
    else
        TriggerClientEvent('ox_lib:notify', adminId, {
            title = locale('title'),
            description = locale('help_request_not_found'),
            type = 'error'
        })        
    end
end)
RegisterServerEvent('djonza:deleteHelpRequest')
AddEventHandler('djonza:deleteHelpRequest', function(requestIndex)
    local adminId = source
    local helpRequest = adminHelpRequests[requestIndex]

    if helpRequest then
        table.remove(adminHelpRequests, requestIndex)
        TriggerClientEvent('ox_lib:notify', adminId, {
            title = locale('report_deleted_title'),
            description = locale('report_deleted_description'),
            type = 'success'
        })        
    else
        TriggerClientEvent('ox_lib:notify', adminId, {
            title = locale('title'),
            description = locale('help_request_not_found'),
            type = 'error'
        })
    end
end)



lib.callback.register('djonza:getResolvedReports', function(source, identifier)
    local resolvedReports = MySQL.Sync.fetchScalar('SELECT resolved_reports FROM users WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    return resolvedReports or 0
end)


RegisterCommand('checkreports', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if exports['adminmenu']:IsPlayerAdminAndOnDuty(source) then
        MySQL.Async.fetchScalar('SELECT resolved_reports FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(resolvedReports)
            if resolvedReports then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = locale('resolved_reports_title'),
                    description = string.format(locale('resolved_reports_description'), resolvedReports),
                    type = 'success'
                })                
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Broj rešavanih reportova',
                    description = locale('no_resolved_reports_data'),
                    type = 'error'
                })
            end
        end)
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = locale('title'),
            description = locale('no_access'),
            type = 'error'
        })
    end
end, false) 