local ScreenManager = require("utils.screenManager")
local Header        = require("ui.header")
local Button        = require("ui.button")
local MenuScreen    = {}
local characters    = {}
local buttons       = {}
local title

local IMAGE_POOL    = {
    "assets/images/food.png",
    "assets/images/predator.png",
    "assets/images/herbivore.png",
}

local function buildCharacters()
    local W, H = love.graphics.getDimensions()
    characters = {}
    for _ = 1, math.random(5, 15) do
        local url = IMAGE_POOL[math.random(#IMAGE_POOL)]
        local x, y, valid
        repeat
            valid = true
            x = math.random() < 0.5
                and math.random(50, math.floor(W * 0.25))
                or math.random(math.floor(W * 0.75), W - 50)
            y = math.random() < 0.5
                and math.random(50, math.floor(H * 0.30))
                or math.random(math.floor(H * 0.70), H - 50)
            for _, c in ipairs(characters) do
                if math.sqrt((c.x - x) ^ 2 + (c.y - y) ^ 2) < 100 then
                    valid = false; break
                end
            end
        until valid
        table.insert(characters, {
            imageUrl = url,
            x        = x,
            y        = y,
            rotate   = math.random(0, 360),
            size     = math.random(15, 50),
            opacity  = math.random(50, 100) / 100,
        })
    end
end

local function buildButtons()
    local W, H = love.graphics.getDimensions()
    local cx = W / 2
    local cy = H / 2
    local bw, bh, gap = 250, 50, 70
    buttons = {
        Button:new("Start Game", cx - bw / 2, cy - bh / 2 - gap, bw, bh, function()
            ScreenManager.switch("game")
        end),
        Button:new("Settings", cx - bw / 2, cy - bh / 2, bw, bh, function()
            ScreenManager.switch("settings")
        end),
        Button:new("Exit", cx - bw / 2, cy - bh / 2 + gap, bw, bh, love.event.quit),
    }
end

local function buildLayout()
    local H = love.graphics.getHeight()
    buildCharacters()
    buildButtons()
    title = Header:new("MicroWorld", 0, H * 0.25, "h1")
end

function MenuScreen:load()
    buildLayout()
end

function MenuScreen:resize(w, h)
    buildLayout()
end

function MenuScreen:update(dt) end

function MenuScreen:draw()
    for _, c in ipairs(characters) do
        love.graphics.setColor(1, 1, 1, c.opacity)
        local img = love.graphics.newImage(c.imageUrl)
        love.graphics.draw(img, c.x, c.y,
            math.rad(c.rotate),
            c.size / img:getWidth(),
            c.size / img:getHeight())
    end
    title:draw()
    for _, btn in ipairs(buttons) do btn:draw() end
end

function MenuScreen:mousepressed(x, y, b)
    for _, btn in ipairs(buttons) do btn:mousePressed(x, y) end
end

function MenuScreen:keypressed(key) end

return MenuScreen
