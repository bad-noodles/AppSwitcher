local App = require("Custom/AppSwitcher/app")

---@class AppSwitcher
---@field apps table<string, App>
---@field hotkeys table<string, boolean>
---@field len integer
---@field visible boolean
---@field canvas hs.canvas | nil
---@field dismissBinding hs.hotkey
---@field dismissTimer hs.timer
local AppSwitcher = {
  hotkeys = {},
  apps = {},
  len = 0,
  visible = false,
}

function AppSwitcher:new(o)
  ---@type AppSwitcher
  local switcher = o or {} -- create object if user does not provide one
  setmetatable(switcher, self)
  self.__index = self

  switcher.dismissBinding = hs.hotkey.new(nil, 'escape', function()
    switcher:hide()
  end)

  local keys = "abcdefghijklmnopqrstuvwxyz"

  for key in keys:gmatch "." do
    switcher.hotkeys[key] = false
  end

  for _, app in pairs(hs.application.runningApplications()) do
    -- In dock
    if app:kind() == 1 then
      switcher:addApp(app)
    end
  end


  ---@param eventType integer
  ---@param app hs.application
  hs.application.watcher.new(function(_, eventType, app)
    if app:kind() ~= 1 then
      return
    elseif eventType == hs.application.watcher.launching then
      switcher:addApp(app)
    elseif eventType == hs.application.watcher.terminated then
      switcher:removeApp(app)
    end
  end):start()

  return switcher
end

---@param app hs.application
function AppSwitcher:addApp(app)
  local id = app:bundleID()

  if self.apps[id] ~= nil then
    return
  end

  local hotkey = self:getHotkey(app:title())

  self.apps[id] = App:new {
    hotkey = hotkey,
    hsApp = app,
    onTrigger = function()
      self:hide()
    end,
  }
  self.hotkeys[hotkey] = true
  self.len = self.len + 1
end

---@param app hs.application
function AppSwitcher:removeApp(app)
  local id = app:bundleID()

  if self.apps[id] == nil then
    return
  end

  self.apps[id]:destroy()
  self.hotkeys[self.apps[id].hotkey] = false
  self.apps[id] = nil
  self.len = self.len - 1
end

---@param appName string
function AppSwitcher:getHotkey(appName)
  local index = 1
  local hotkey = nil

  while (hotkey == nil) do
    hotkey = string.lower(string.sub(appName, index, index))

    if hotkey == "" then
      for key, used in pairs(self.hotkeys) do
        if ~used then
          return key
        end
      end
    end

    if self.hotkeys[hotkey] then
      hotkey = nil
      index = index + 1
    end
  end
  -- TODO: Make it possible to have user-defined hotkey per app name

  return hotkey
end

function AppSwitcher:show()
  if (self.visible) then
    self.dismissTimer:stop()
    self.dismissTimer:start()
    return
  end

  self.visible = true
  local frame = hs.screen.mainScreen():frame()
  local itemWidth = 110
  local width = itemWidth * self.len
  local height = 160
  self.canvas = hs.canvas.new {
    x = (frame.w / 2) - (width / 2),
    y = (frame.h / 2) - (height / 2),
    h = height,
    w = width
  }

  if (self.canvas == nil) then
    error("AppSwitcher: Could not create h.canvas")
  end

  self.dismissTimer = hs.timer.doAfter(3, function()
    self:hide()
  end)
  self.dismissBinding:enable()

  local x = 0
  for _, app in pairs(self.apps) do
    app:enableSingleKeyBinding()

    self.canvas:appendElements(app:getUI(x, 0, 110, 110))

    x = x + itemWidth
  end

  self.canvas:show()
end

function AppSwitcher:hide()
  self.canvas:delete(.1)
  self.dismissBinding:disable()
  self.dismissTimer:stop()
  for _, app in pairs(self.apps) do
    app:disableSingleKeyBinding()
  end
  self.visible = false
end

local as = AppSwitcher:new {}

hs.hotkey.bind(
  "option",
  "tab",
  function()
    as:show()
  end
)
