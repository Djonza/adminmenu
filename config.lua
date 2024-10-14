Config = {}

-- Paths and general settings
Config.DutyDataPath = "dutydata/"  -- Folder to store JSON files
Config.SaveMethod = "steam_name"  -- Options: "license" or "steam_name"

Config.GroupColors = {
    admin = {0, 255, 0},      -- Red for admin
    superadmin = {0, 255, 0}, -- Green for superadmin
    moderator = {0, 0, 255},  -- Blue for moderator (example if you have this role)
    default = {255, 255, 255} -- White if group is not defined
}

Config.AdminGroups = {
    'admin',         -- Default admin group
    'superadmin',    -- Superadmin group
    'moderator'      -- Add any other group you want to consider as admin
}

Config.VehicleModel = "phantom"
Config.DeleteEntityRadius = 2
Config.DeletePedRadius = 5

Config.StateOrganizations = {
    { name = "police", label = "Police Department" },
    { name = "ambulance", label = "Emergency Medical Services" },
    { name = "government", label = "Government" }
}

Config.Organizations = {
    { name = "mafia", label = "Mafia" },
    { name = "cartel", label = "Cartel" },
    { name = "gang", label = "Gang" }
}

Config.DiscordWebhook = {
    kick = "https://discord.com/api/webhooks/your_kick_webhook",
    ban = "https://discord.com/api/webhooks/your_ban_webhook",
    warn = "https://discord.com/api/webhooks/your_warn_webhook",
    teleport = "https://discord.com/api/webhooks/your_teleport_webhook",
    general = "https://discord.com/api/webhooks/1292999312741236746/_jxbVUrbGqXWZfC1zApoEoIiyzPgSCmpsGQPZts63160-eTEt4QRqboKitIR-NjIHjeq"
}
