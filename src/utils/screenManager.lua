local ScreenManager = {}

local screens       = {}
local active        = nil

function ScreenManager.register(name, screen)
    screens[name] = screen
end

function ScreenManager.switch(name, ...)
    if active and active.unload then active:unload() end
    active = screens[name]
    assert(active, "ScreenManager: невідомий екран '" .. name .. "'")
    if active.load then active:load(...) end
end

function ScreenManager.current()
    if not active then
        return {
            update       = function() end,
            draw         = function() end,
            mousepressed = function() end,
            keypressed   = function() end,
        }
    end
    return active
end

return ScreenManager
