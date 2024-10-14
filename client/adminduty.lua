RegisterNetEvent('djonza:client:adminlist')
AddEventHandler('djonza:client:adminlist', function(adminList)
    local options = {}

    for _, admin in ipairs(adminList) do
        table.insert(options, {
            title = admin.name .. " - " .. admin.status,
            icon = admin.status == 'On Duty' and 'check-circle' or 'times-circle',
            iconColor = admin.status == 'On Duty' and 'green' or 'red'
        })
    end

    if #options == 0 then
        table.insert(options, {
            title = locale('no_admins_online'),
            icon = "exclamation-triangle",
            iconColor = "yellow"
        })
    end

    lib.registerContext({
        id = 'admin-list-menu',
        title = locale('admin_list'), 
        options = options
    })

    lib.showContext('admin-list-menu')
end)
