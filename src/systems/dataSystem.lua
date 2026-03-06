local DataSystem = {}

local SAVE_DIR   = "saves/"
local NUM_SLOTS  = 3

local function slotPath(slot)
    return SAVE_DIR .. "slot_" .. slot .. ".lua"
end

local function ensureDir()
    if not love.filesystem.getInfo(SAVE_DIR) then
        love.filesystem.createDirectory(SAVE_DIR)
    end
end

local function serialize(val, depth)
    depth = depth or 0
    local t = type(val)
    if t == "number" then return tostring(val) end
    if t == "boolean" then return tostring(val) end
    if t == "string" then return string.format("%q", val) end
    if t == "nil" then return "nil" end
    if t ~= "table" then return tostring(val) end

    local parts    = {}
    local pad      = string.rep("  ", depth + 1)
    local closePad = string.rep("  ", depth)

    if #val > 0 then
        for _, v in ipairs(val) do
            table.insert(parts, pad .. serialize(v, depth + 1))
        end
    else
        for k, v in pairs(val) do
            if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                table.insert(parts, pad .. k .. " = " .. serialize(v, depth + 1))
            else
                table.insert(parts, pad .. "[" .. serialize(k) .. "] = " .. serialize(v, depth + 1))
            end
        end
    end

    if #parts == 0 then return "{}" end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. closePad .. "}"
end

local function serializeFood(f)
    return {
        x        = f.x,
        y        = f.y,
        targetX  = f.targetX,
        targetY  = f.targetY,
        lifespan = f.lifespan,
        speed    = f.speed,
        moving   = f.moving,
    }
end

local function serializeCreature(c)
    return {
        x                    = c.x,
        y                    = c.y,
        targetX              = c.targetX,
        targetY              = c.targetY,
        lifespan             = c.lifespan,
        speed                = c.speed,
        visionRadius         = c.visionRadius,
        state                = c.state,
        reproductionCooldown = c.reproductionCooldown,
        socialCooldown       = c.socialCooldown,
        drives               = {
            hunger = c.drives.hunger,
            social = c.drives.social,
            fear   = c.drives.fear,
        },
        _baseSocial          = c._baseSocial,
    }
end

local function restoreFood(Food, d)
    local f    = Food:new(d.x, d.y)
    f.x        = d.x
    f.y        = d.y
    f.targetX  = d.targetX or d.x
    f.targetY  = d.targetY or d.y
    f.lifespan = d.lifespan
    f.speed    = d.speed
    f.moving   = d.moving
    return f
end

local function restoreCreature(Constructor, d)
    local c                = Constructor:new(d.x, d.y)
    c.x                    = d.x
    c.y                    = d.y
    c.targetX              = d.targetX or d.x
    c.targetY              = d.targetY or d.y
    c.lifespan             = d.lifespan
    c.speed                = d.speed
    c.visionRadius         = d.visionRadius
    c.state                = d.state or "idle"
    c.reproductionCooldown = d.reproductionCooldown or 0
    c.socialCooldown       = d.socialCooldown or 0
    c.drives.hunger        = d.drives.hunger
    c.drives.social        = d.drives.social
    c.drives.fear          = d.drives.fear
    c._baseSocial          = d._baseSocial or d.drives.social
    return c
end

function DataSystem.getSlots()
    local slots = {}
    for i = 1, NUM_SLOTS do
        local path = slotPath(i)
        if love.filesystem.getInfo(path) then
            local ok, chunk = pcall(love.filesystem.load, path)
            if ok then
                local ok2, tbl = pcall(chunk)
                if ok2 and tbl then
                    slots[i] = {
                        exists     = true,
                        timestamp  = tbl.timestamp or "???",
                        herbivores = tbl.herbivoreCount or 0,
                        predators  = tbl.predatorCount or 0,
                        food       = tbl.foodCount or 0,
                    }
                else
                    slots[i] = { exists = true, timestamp = "Пошкоджено" }
                end
            else
                slots[i] = { exists = true, timestamp = "Пошкоджено" }
            end
        else
            slots[i] = { exists = false }
        end
    end
    return slots
end

function DataSystem.save(slot, foodObjects, herbivoreObjects, predatorObjects)
    ensureDir()

    local foodData, herbData, predData = {}, {}, {}

    for _, f in ipairs(foodObjects) do table.insert(foodData, serializeFood(f)) end
    for _, h in ipairs(herbivoreObjects) do table.insert(herbData, serializeCreature(h)) end
    for _, p in ipairs(predatorObjects) do table.insert(predData, serializeCreature(p)) end

    local d         = os.date("*t")
    local ts        = string.format("%02d.%02d.%04d %02d:%02d",
        d.day, d.month, d.year, d.hour, d.min)

    local saveTable = {
        timestamp      = ts,
        herbivoreCount = #herbivoreObjects,
        predatorCount  = #predatorObjects,
        foodCount      = #foodObjects,
        food           = foodData,
        herbivores     = herbData,
        predators      = predData,
    }

    local content   = "return " .. serialize(saveTable)
    local ok, err   = love.filesystem.write(slotPath(slot), content)
    if not ok then
        print("[DataSystem] Помилка збереження:", err)
    else
        print(string.format("[DataSystem] Збережено слот %d (%d herb, %d pred, %d food)",
            slot, #herbivoreObjects, #predatorObjects, #foodObjects))
    end
    return ok
end

function DataSystem.load(slot)
    local path = slotPath(slot)
    if not love.filesystem.getInfo(path) then
        print("[DataSystem] Слот", slot, "порожній")
        return nil
    end

    local ok, chunk = pcall(love.filesystem.load, path)
    if not ok then
        print("[DataSystem] Помилка читання:", chunk)
        return nil
    end

    local ok2, data = pcall(chunk)
    if not ok2 then
        print("[DataSystem] Помилка виконання:", data)
        return nil
    end

    print(string.format("[DataSystem] Завантажено слот %d (%s)", slot, data.timestamp or "???"))
    return data
end

function DataSystem.delete(slot)
    love.filesystem.remove(slotPath(slot))
end

function DataSystem.restore(saveData, Food, Herbivore, Predator)
    local foods, herbs, preds = {}, {}, {}

    for _, d in ipairs(saveData.food or {}) do table.insert(foods, restoreFood(Food, d)) end
    for _, d in ipairs(saveData.herbivores or {}) do table.insert(herbs, restoreCreature(Herbivore, d)) end
    for _, d in ipairs(saveData.predators or {}) do table.insert(preds, restoreCreature(Predator, d)) end

    print(string.format("[DataSystem] Відновлено: %d food, %d herb, %d pred",
        #foods, #herbs, #preds))

    return foods, herbs, preds
end

return DataSystem
