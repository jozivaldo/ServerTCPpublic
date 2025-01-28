local EventManager = {}
EventManager.__index = EventManager

EventManager.events = {}

function EventManager:CreateEvent(eventName)
    if not self.events[eventName] then
        self.events[eventName] = {}
    end
end

function EventManager:Connect(eventName, listener)
    if not self.events[eventName] then
        error("Evento não existe: " .. eventName)
    end
    table.insert(self.events[eventName], listener)
    return function()
        for i, l in ipairs(self.events[eventName]) do
            if l == listener then
                table.remove(self.events[eventName], i)
                break
            end
        end
    end
end

function EventManager:Fire(eventName, ...)
    if not self.events[eventName] then
        error("Evento não existe: " .. eventName)
    end
    for _, listener in ipairs(self.events[eventName]) do
        listener(...)
    end
end

function EventManager:Disconnect(eventName, listener)
    if not self.events[eventName] then
        error("Evento não existe: " .. eventName)
    end
    
    for i, connection in ipairs(self.events[eventName]) do
        if connection.listener == listener then
            table.remove(self.events[eventName], i)
            break
        end
    end
end

return EventManager
