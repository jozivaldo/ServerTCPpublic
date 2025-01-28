local Data = {}

local json = require("dkjson")

function sha256_in_python(message)
    local escaped_message = string.format("%q", message)
    local handle = io.popen("pythonw Sha256.py " .. escaped_message)
    local result = handle:read("*a")
    handle:close()

    if not result or result == "" then
        return nil
    end

    return result:match("^%s*(.-)%s*$")
end


function Data.users()
    local file = io.open("DataFolder/users.json")

    if not file then
        return {}
    end

    local content = file:read("*a")
    file:close()

    return json.decode(content) or {}
end

function Data.authenticate(Email,Password)
    local Users = Data.users()

    local hashedPassword = sha256_in_python(Password)
    if not hashedPassword then
        return false, "Erro ao calcular o hash da senha!"
    end

    for _,user in ipairs(Users) do
        if user and user.email == Email and user.password == hashedPassword then
            return true
        end
    end

    return false
end

function Data.saveUsers(users)
    local file = io.open("DataFolder/users.json", "w")
    if not file then
        print("Erro ao salvar usuários: arquivo não pode ser aberto!")
        return
    end
    file:write(json.encode(users, {indent = true}))
    file:close()
end

function Data.RegisterUser(Email,Password)
    local users = Data.users()

    for _, user in ipairs(users) do
        if user.email == Email then
            return false, "Email já cadastrado!"
        end
    end

    local hashedPassword = sha256_in_python(Password)
    if not hashedPassword then
        return false, "Erro ao calcular o hash da senha!"
    end

    table.insert(users, {
        email = Email,
        password = hashedPassword,
        AccountName = "Nome padrão",
        friends = {},
        messages = {
            user = {},
            friends = {},
        },
        config = {},
    })

    Data.saveUsers(users)

    return true, "Usuário registrado com sucesso!"
end

return Data