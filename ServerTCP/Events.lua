local Event = {}
Event.__index = Event

local EventManager = require("EventManager")

local json = require("dkjson")
local Data = require("Data")
local http = require("socket.http")
local ltn12 = require("ltn12")

local codeTable = {}

local function send_email(to_email, subject, body)
    local payload = json.encode({
        to_email = to_email,
        subject = subject,
        body = body
    })

    local response_body = {}

    local res, code, headers, status = http.request{
        url = "http://127.0.0.1:5000/send_email",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#payload)
        },
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(response_body)
    }

    if code == 200 then
        return true, table.concat(response_body)
    else
        return false, table.concat(response_body)
    end
end

local function storeCode(code)
    codeTable[code] = os.time() + 600
end

local function validateCode(inputCode)
    local currentTime = os.time()
    if codeTable[inputCode] and codeTable[inputCode] > currentTime then
        codeTable[inputCode] = nil
        return true
    else
        return false
    end
end

function Event.cleanupExpiredCodes()
    local currentTime = os.time()
    for code, expiry in pairs(codeTable) do
        if expiry <= currentTime then
            codeTable[code] = nil
        end
    end
end

function Event.generateCode()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local code = ""
    for i = 1, 6 do
        local randomIndex = math.random(1, #charset)
        code = code .. charset:sub(randomIndex, randomIndex)
    end
    return code
end

EventManager:Connect("Login",function(Email)
    local Code = Event.generateCode()
    storeCode(Code)
    local Sucesso,Result = send_email(Email, "Código de Confirmação", "Seu código de confirmação é: " .. Code)

    if not Sucesso then
        _G.Login = "Nenhuma conta encontrada. email nao enviado Error: ",err
    else
        _G.Login = "Codigo enviado: ",Sucesso," ",Result
    end
end)

return Event