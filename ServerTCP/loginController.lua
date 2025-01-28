local loginController = {}
local json = require("dkjson")
local Data = require("Data")
local EventManager = require("EventManager")

EventManager:CreateEvent("Login")

local Events = require("Events")

local Actions = {
    ["login"] = function(args,Client)
        local Auth = Data.authenticate(args.Email,args.Password)
        if not Auth then
            _G.Login = "Conta não encontrada na Data, ou possivel erro de credências."
        else
            EventManager:Fire("Login",args.Email)
        end

        -- Client:send("true\n")
    end;

    ["Reset_Password"] = function(args,Client)
        print("Senha resetada de", OldPassword, "para", NewPassword)
    end;

    ["Register"] = function(args,Client)
        print("Conta criada com:", Email, NickName)
    end;
}

function loginController.executeAction(content,Client)
    if content and type(content) == "table" and content.args and content.action then
        local actionName = content.action
        local actionArgs = content.args
    
        local FindAction = Actions[actionName]
    
        if FindAction then
            FindAction(actionArgs,Client)
        end
    end
end


return loginController