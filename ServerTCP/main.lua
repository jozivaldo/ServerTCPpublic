local socket = require("socket")
local Data = require("Data")
local Udp = require("Udp")
local loginController = require("loginController")
local json = require("dkjson")
local EventManager = require("EventManager")
local Event = require("Events")

local server = {}
local clients = {}
local messages = {}
local ipConnections = {}
local warnings = {}

local MAX_CONNECTIONS_PER_IP = 1
local MAX_TOTAL_CONNECTIONS = 100
local MAX_MESSAGE_SIZE = 1024
local MAX_MESSAGES = 60
local TIME_WINDOW = 1
local MAX_WARNINGS = 3
local clientRates = {}

_G.Login = {}

function love.load()
    server = assert(socket.bind("127.0.0.1", 12345))
    server:settimeout(0)
    print("Servidor iniciado em 127.0.0.1:12345")
    table.insert(messages, "Servidor iniciado em 127.0.0.1:12345")
end


local function logEvent(event)
    local file = io.open("ServerLog.log", "a")
    file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. tostring(event) .. "\n")
    file:close()
end

local function addConnection(client)
    local ip = client:getpeername()

    if not ip then
        return false
    end

    ipConnections[ip] = (ipConnections[ip] or 0) + 1
    if ipConnections[ip] > MAX_CONNECTIONS_PER_IP then
        client:send("Muitas conexões deste IP.\n")
        logEvent("Conexão recusada do IP: " .. ip)
        client:close()
        return false
    end
    return true
end

local function removeConnection(client)
    local ip = client:getpeername()
    if ip and ipConnections[ip] then
        ipConnections[ip] = ipConnections[ip] - 1
        if ipConnections[ip] <= 0 then
            ipConnections[ip] = nil
        end
    end
end

local function warnClient(client)
    if not client then return end

    warnings[client] = (warnings[client] or 0) + 1
    if warnings[client] >= MAX_WARNINGS then
        disconnectClient(client, "Comportamento suspeito")
        return true
    else
        client:send("Aviso: Você excedeu os limites permitidos.\n")
        return false
    end
end

local function rateLimit(client)
    local now = os.time()
    clientRates[client] = clientRates[client] or {count = 0, startTime = now}

    local rateData = clientRates[client]
    if now - rateData.startTime > TIME_WINDOW then
        rateData.count = 0
        rateData.startTime = now
    end

    rateData.count = rateData.count + 1
    if rateData.count > MAX_MESSAGES then
        if warnClient(client) then
            clientRates[client] = nil
        end
        return false
    end
    return true
end

function disconnectClient(client, reason)
    if not client then return end

    local ip, port = client:getpeername()
    reason = reason or "Desconhecido"
    logEvent("Desconectando cliente: " .. (ip or "IP desconhecido") .. ", razão: " .. reason)
    
    if clientRates[client] then
        clientRates[client] = nil
    end

    client:close()
    removeConnection(client)
    clientRates[client] = nil
    warnings[client] = nil

    for i, c in ipairs(clients) do
        if c == client then
            table.remove(clients, i)
            break
        end
    end
end

function TcpControl()
    local client = server:accept()
    if client then
        if #clients >= MAX_TOTAL_CONNECTIONS then
            client:send("Servidor cheio. Tente novamente mais tarde.\n")
            logEvent("Conexão recusada. Servidor cheio.")
            client:close()
        elseif addConnection(client) then
            client:settimeout(0)
            table.insert(clients, client)
            local welcomeMessage = "Bem-vindo ao servidor!"
            client:send(welcomeMessage .. "\n")
            table.insert(messages, "Novo User entrou! Total: " .. #clients)
            logEvent("Novo cliente conectado.")
        end
    end

    for i = #clients, 1, -1 do
        local client = clients[i]
        local message, err = client:receive("*l")
        
        if err == "closed" then
            disconnectClient(client, "Conexão fechada pelo cliente")
            table.remove(clients, i)
        elseif not err then
            message = message:match("^(.-)\n?$")

            if #message > MAX_MESSAGE_SIZE then
                client:send("Mensagem muito longa.\n")
                logEvent("Mensagem muito longa recebida. Cliente avisado.")
                disconnectClient(client, "Mensagem muito longa")
                table.remove(clients, i)
            elseif rateLimit(client) then

                local success, decodedData = pcall(function()
                    return json.decode(message)
                end)
            
                if success then
                    if decodedData and decodedData.action and decodedData.args then
                        _G.Login = "Chamando o ExecuteAction "..message
                        loginController.executeAction(decodedData,client)
                    else
                        _G.Login = "o json nao possui action ou retornou nil "..message
                    end
                else
                    _G.Login = "falha ao decodificar a mensagesm: "..message
                    return
                end

                table.insert(messages,"Recebido do client: "..message)
            else
                _G.Login = "Aguardando mais dados ou JSON incompleto: "..message
            end
            
        end
    end
end


function love.update(dt)
    TcpControl()
    Event.cleanupExpiredCodes()
end

function love.draw()
    if _G.Login then
        love.graphics.print(_G.Login, 10, 250 + 10)
    end

    for i, message in ipairs(messages) do
        love.graphics.print(message, 10, 10 + (i - 1) * 20)
    end
end