local logQueue, isProcessingQueue, logCount = {}, false, 0
local lastRequestTime, requestDelay = 0, 0

---@enum Colors
local Colors = { -- https://www.spycolor.com/
    default = 14423100,
    blue = 255,
    red = 16711680,
    green = 65280,
    white = 16777215,
    black = 0,
    orange = 16744192,
    yellow = 16776960,
    pink = 16761035,
    lightgreen = 65309,
}

---Logs using ox_lib logger regardless of Config.EnableOxLogging value
---@see https://overextended.github.io/docs/ox_lib/Logger/Server
local function OxLog(source, event, message, ...)
    lib.logger(source, event, message, ...)
end

exports('OxLog', OxLog)

---Log Queue
local function applyRequestDelay()
    local currentTime = GetGameTimer()
    local timeDiff = currentTime - lastRequestTime

    if timeDiff < requestDelay then
        local remainingDelay = requestDelay - timeDiff

        Wait(remainingDelay)
    end

    lastRequestTime = GetGameTimer()
end

local allowedErr = {
    [200] = true,
    [201] = true,
    [204] = true,
    [304] = true
}

---Log Queue
---@param payload Log Queue
local function logPayload(payload)
    local tags

    for i = 1, #payload.tags do
        if not tags then tags = '' end
        tags = tags .. payload.tags[i]
    end

    PerformHttpRequest(payload.webhook, function(err, _, headers)
        if err and not allowedErr[err] then
            print('^1Error occurred while attempting to send log to discord: ' .. err .. '^7')
            return
        end

        local remainingRequests = tonumber(headers["X-RateLimit-Remaining"])
        local resetTime = tonumber(headers["X-RateLimit-Reset"])

        if remainingRequests and resetTime and remainingRequests == 0 then
            local currentTime = os.time()
            local resetDelay = resetTime - currentTime

            if resetDelay > 0 then
                requestDelay = resetDelay * 1000 / 10
            end
        end
    end, 'POST', json.encode({content = tags, embeds = payload.embed}), { ['Content-Type'] = 'application/json' })
end

---Log Queue
local function processLogQueue()
    if #logQueue > 0 then
        local payload = table.remove(logQueue, 1)

        logPayload(payload)

        logCount += 1

        if logCount % 5 == 0 then
            Wait(60000)
        else
            applyRequestDelay()
        end

        processLogQueue()
    else
        isProcessingQueue = false
    end
end

---@class DiscordLog
---@field source string source of the log. Usually a playerId or name of a resource.
---@field event string the action or 'event' being logged. Usually a verb describing what the name is doing. Example: SpawnVehicle
---@field message string the message attached to the log
---@field webhook string url of the webhook this log should send to
---@field color? string what color the message should be
---@field tags? string[] tags in discord. Example: ['@admin', '@everyone']

---Creates a discord log
---@param log DiscordLog
local function discordLog(log)
    local embedData = {
        {
            title = log.event,
            color = Colors[log.color] or Colors.default,
            footer = {
                text = os.date('%H:%M:%S %m-%d-%Y'),
            },
            description = log.message,
            author = {
                name = 'QBX Logs',
            },
        }
    }

    logQueue[#logQueue + 1] = {
        webhook = log.webhook,
        tags = log.tags,
        embed = embedData
    }

    if not isProcessingQueue then
        isProcessingQueue = true
        CreateThread(processLogQueue)
    end
end

exports('DiscordLog', discordLog)

---@class Log
---@field source string source of the log. Usually a playerId or name of a resource.
---@field event string the action or 'event' being logged. Usually a verb describing what the name is doing. Example: SpawnVehicle
---@field message string the message attached to the log
---@field webhook? string Discord logs only. url of the webhook this log should send to
---@field color? string Discord logs only. what color the message should be
---@field tags? string[] Discord logs only. tags in discord. Example: ['@admin', '@everyone']

---Creates a log using either ox_lib logger, discord webhooks, or both depending on config.
---@param log Log
local function createLog(log)
    if Config.EnableOxLogging then
        OxLog(log.source, log.event, log.message)
    end

    if Config.EnableDiscordLogging then
        if log.webhook then
            ---@diagnostic disable-next-line: param-type-mismatch
            discordLog(log)
        else
            lib.print.error('webhook is required for discord logs')
        end
    end
end

exports('CreateLog', createLog)

---@deprecated use the CreateLog export instead for discord logging, or OxLog for other logging.
RegisterNetEvent('qb-log:server:CreateLog', function()
    lib.print.warn('qb-log:server:CreateLog is unsupported and has no effect. Use CreateLog() after installing qbx_core\'s logger module instead.')
end)