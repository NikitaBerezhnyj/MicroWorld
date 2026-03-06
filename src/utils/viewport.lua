local Viewport      = {}

Viewport.baseWidth  = 1200
Viewport.baseHeight = 720


local function transform()
    local sw     = love.graphics.getWidth()
    local sh     = love.graphics.getHeight()
    local scaleX = sw / Viewport.baseWidth
    local scaleY = sh / Viewport.baseHeight
    local scale  = math.min(scaleX, scaleY)
    local ox     = (sw - Viewport.baseWidth * scale) / 2
    local oy     = (sh - Viewport.baseHeight * scale) / 2
    return scale, ox, oy
end


function Viewport.apply()
    local scale, ox, oy = transform()
    love.graphics.push()
    love.graphics.translate(ox, oy)
    love.graphics.scale(scale, scale)
end

function Viewport.release()
    love.graphics.pop()
end

function Viewport.toSim(sx, sy)
    local scale, ox, oy = transform()
    return (sx - ox) / scale, (sy - oy) / scale
end

return Viewport
