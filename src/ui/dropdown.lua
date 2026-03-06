local Dropdown = {}
Dropdown.__index = Dropdown
local hexToRGB = require("utils.hexToRGB")

function Dropdown:new(x, y, width, height, options, selectedIndex, onChange)
    local self              = setmetatable({}, Dropdown)
    self.x, self.y          = x, y
    self.width, self.height = width, height
    self.options            = options -- { { label="1280×720", ... }, ... }
    self.selected           = selectedIndex or 1
    self.isOpen             = false
    self.onChange           = onChange -- callback(index, option)
    self.bgColor            = { hexToRGB.convert("#6db1bf") }
    self.hoverColor         = { hexToRGB.convert("#52a1b2") }
    self.textColor          = { hexToRGB.convert("#fffcfb") }
    self.dropBgColor        = { hexToRGB.convert("#0d3b45") }
    return self
end

function Dropdown:draw(drawList)
    local mx, my = love.mouse.getPosition()

    local isHover = mx >= self.x and mx <= self.x + self.width
        and my >= self.y and my <= self.y + self.height

    love.graphics.setColor(isHover and self.hoverColor or self.bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

    love.graphics.setColor(self.textColor)
    love.graphics.printf(
        self.options[self.selected].label .. "  ▼",
        self.x, self.y + self.height / 4,
        self.width, "center"
    )
end

function Dropdown:drawList()
    local mx, my = love.mouse.getPosition()

    for i, opt in ipairs(self.options) do
        local oy = self.y + self.height * i

        local itemHover = mx >= self.x and mx <= self.x + self.width
            and my >= oy and my <= oy + self.height

        love.graphics.setColor(itemHover and self.hoverColor or self.dropBgColor)
        love.graphics.rectangle("fill", self.x, oy, self.width, self.height, 8, 8)

        love.graphics.setColor(self.textColor)
        love.graphics.printf(opt.label, self.x, oy + self.height / 4, self.width, "center")
    end
end

function Dropdown:mousepressed(mx, my)
    if mx >= self.x and mx <= self.x + self.width
        and my >= self.y and my <= self.y + self.height then
        self.isOpen = not self.isOpen
        return
    end
    if self.isOpen then
        for i, _ in ipairs(self.options) do
            local oy = self.y + self.height * i
            if mx >= self.x and mx <= self.x + self.width
                and my >= oy and my <= oy + self.height then
                self.selected = i
                self.isOpen = false
                if self.onChange then self.onChange(i, self.options[i]) end
                return
            end
        end
        self.isOpen = false
    end
end

return Dropdown
