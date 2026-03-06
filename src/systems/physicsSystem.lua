local PhysicsSystem = {}

local SIM_X_MIN = 50
local SIM_X_MAX = 750
local SIM_Y_MIN = 50
local SIM_Y_MAX = 550


local ITERATIONS = 3


local CORRECTION_PERCENT = 0.8


local SLOP = 0.5

local function resolveOverlap(a, b)
    local dx   = b.x - a.x
    local dy   = b.y - a.y
    local dist = math.sqrt(dx * dx + dy * dy)
    local minD = a:getRadius() + b:getRadius()

    if dist >= minD then return end

    local overlap = minD - dist


    local nx, ny
    if dist < 0.001 then
        local angle = math.random() * math.pi * 2
        nx, ny = math.cos(angle), math.sin(angle)
    else
        nx, ny = dx / dist, dy / dist
    end


    local correction = math.max(overlap - SLOP, 0) * CORRECTION_PERCENT


    if a.speed == 0 and b.speed == 0 then
        return
    elseif a.speed == 0 then
        b.x = b.x + nx * correction
        b.y = b.y + ny * correction
    elseif b.speed == 0 then
        a.x = a.x - nx * correction
        a.y = a.y - ny * correction
    else
        local half = correction * 0.5
        a.x = a.x - nx * half
        a.y = a.y - ny * half
        b.x = b.x + nx * half
        b.y = b.y + ny * half
    end


    a.x = math.max(SIM_X_MIN, math.min(SIM_X_MAX, a.x))
    a.y = math.max(SIM_Y_MIN, math.min(SIM_Y_MAX, a.y))
    b.x = math.max(SIM_X_MIN, math.min(SIM_X_MAX, b.x))
    b.y = math.max(SIM_Y_MIN, math.min(SIM_Y_MAX, b.y))
end


function PhysicsSystem.resolve(groups)
    for _ = 1, ITERATIONS do
        for _, group in ipairs(groups) do
            for i = 1, #group do
                for j = i + 1, #group do
                    resolveOverlap(group[i], group[j])
                end
            end
        end


        for gi = 1, #groups do
            for gj = gi + 1, #groups do
                for _, a in ipairs(groups[gi]) do
                    for _, b in ipairs(groups[gj]) do
                        resolveOverlap(a, b)
                    end
                end
            end
        end
    end
end

return PhysicsSystem
