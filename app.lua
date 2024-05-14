local defaultMod = { "option", "shift" }

---@class App
---@field hotkey string
---@field icon hs.image
---@field hsApp hs.application
---@field directBinding hs.hotkey
---@field singleKeyBinding hs.hotkey
---@field onTrigger function
local App = {
  hotkey = "",
}

function App:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.directBinding = hs.hotkey.bind(defaultMod, o.hotkey, function()
    o:activate()
  end)

  -- .new doesn't enable the binding
  o.singleKeyBinding = hs.hotkey.new(nil, o.hotkey, function()
    o:activate()
    o.onTrigger()
  end)

  local id = o.hsApp:bundleID()
  -- TODO: fix fallback image

  if id == nil then
    o.icon = hs.image.imageFromName("ApplicationIcon")
  else
    o.icon = hs.image.imageFromAppBundle(id)
    if o.icon == nil then
      o.icon = hs.image.imageFromName("ApplicationIcon")
    end
  end

  return o
end

function App:enableSingleKeyBinding()
  self.singleKeyBinding:enable()
end

function App:disableSingleKeyBinding()
  self.singleKeyBinding:disable()
end

function App:activate()
  hs.application.launchOrFocusByBundleID(self.hsApp:bundleID())
end

function App:destroy()
  self.singleKeyBinding:delete()
  self.directBinding:delete()
end

---Gets the elements to render on hs.canvas
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@return table[]
function App:getUI(x, y, w, h)
  return { {
    type = "rectangle",
    frame = { h = 50, w = 50, x = x + 30, y = y + 5 },
    action = "fill",
    radius = ".5",
    fillColor = { alpha = 0.5, red = .3, green = .3, blue = .3 },
  }, {
    type = "text",
    frame = { h = 50, w = 50, x = x + 30, y = y },
    text = hs.styledtext.new(string.upper(self.hotkey), {
      font = { name = ".AppleSystemUIFont", size = 50 },
      paragraphStyle = { alignment = "center" },
      color = { alpha = 1, red = 1, green = 1, blue = 1 },
    })
  }, {
    type = "image",
    frame = { h = h, w = w, x = x, y = y + 50 },
    image = self.icon,
  } }
end

return App
