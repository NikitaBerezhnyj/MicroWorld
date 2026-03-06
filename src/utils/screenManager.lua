local ScreenManager = {}

local screens       = {}
local stack         = {}



function ScreenManager.register(name, screen)
    screens[name] = screen
end

function ScreenManager.switch(name, params)
    for i = #stack, 1, -1 do
        if stack[i].unload then stack[i]:unload() end
    end
    stack = {}

    local screen = screens[name]
    assert(screen, "ScreenManager: невідомий екран '" .. name .. "'")
    table.insert(stack, screen)
    if screen.load then screen:load(params) end
end

function ScreenManager.push(name, params)
    local screen = screens[name]
    assert(screen, "ScreenManager: невідомий екран '" .. name .. "'")

    local top = stack[#stack]
    if top and top.pause then top:pause() end

    table.insert(stack, screen)
    if screen.load then screen:load(params) end
end

function ScreenManager.pop(result)
    assert(#stack > 1, "ScreenManager.pop: стек має тільки один екран!")
    local top = table.remove(stack)
    if top.unload then top:unload() end


    local prev = stack[#stack]
    if prev and prev.resume then prev:resume(result) end
end

function ScreenManager.current()
    if #stack == 0 then
        return {
            update       = function() end,
            draw         = function() end,
            mousepressed = function() end,
            keypressed   = function() end,
        }
    end
    return stack[#stack]
end

return ScreenManager
