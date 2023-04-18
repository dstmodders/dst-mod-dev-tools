----
-- Menu.
--
-- Includes menu functionality holding all existing submenus and some additional options.
--
-- **Source Code:** [https://github.com/dstmodders/mod-dev-tools](https://github.com/dstmodders/mod-dev-tools)
--
-- @classmod menu.Menu
-- @see menu.TextMenu
-- @see submenus.CharacterRecipesSubmenu
-- @see submenus.Debug
-- @see submenus.DumpSubmenu
-- @see submenus.Labels
-- @see submenus.Language
-- @see submenus.Map
-- @see submenus.PlayerBarsSubmenu
-- @see submenus.PlayerVision
-- @see submenus.SeasonControl
-- @see submenus.SelectSubmenu
-- @see submenus.TeleportSubmenu
-- @see submenus.TimeControl
-- @see submenus.WeatherControl
--
-- @author [Depressed DST Modders](https://github.com/dstmodders)
-- @copyright 2020
-- @license MIT
-- @release 0.8.0-alpha
----
require("consolecommands")

local SDK = require("devtools/sdk/sdk/sdk")
local TextMenu = require("devtools/menu/textmenu")

-- submenus
local CharacterRecipesSubmenu = require("devtools/submenus/characterrecipessubmenu")
local Debug = require("devtools/submenus/debug")
local DevTools = require("devtools/submenus/devtools")
local DumpSubmenu = require("devtools/submenus/dumpsubmenu")
local Labels = require("devtools/submenus/labels")
local Language = require("devtools/submenus/language")
local Map = require("devtools/submenus/map")
local PlayerBarsSubmenu = require("devtools/submenus/playerbarssubmenu")
local PlayerVision = require("devtools/submenus/playervision")
local SeasonControl = require("devtools/submenus/seasoncontrol")
local SelectSubmenu = require("devtools/submenus/selectsubmenu")
local TeleportSubmenu = require("devtools/submenus/teleportsubmenu")
local TimeControl = require("devtools/submenus/timecontrol")
local WeatherControl = require("devtools/submenus/weathercontrol")

-- options
local DividerOption = require("devtools/menu/option/divideroption")
local ActionOption = require("devtools/menu/option/actionoption")
local ToggleCheckboxOption = require("devtools/menu/option/togglecheckboxoption")

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam screen.DevToolsScreen screen
-- @tparam DevTools devtools
-- @usage local menu = Menu(screen, devtools)
local Menu = Class(function(self, screen, devtools)
    -- general
    self.devtools = devtools
    self.menu = nil
    self.options = {}
    self.screen = screen
    self.title = "Front-End Developer Tools"

    if SDK.IsInCharacterSelect() then
        self.title = "Character Selection Developer Tools"
    elseif InGamePlay() then
        self.title = "In-Game Developer Tools"
    end
end)

--- General
-- @section general

--- Gets menu.
-- @treturn TextMenu
function Menu:GetMenu()
    return self.menu
end

--- Gets menu index.
-- @treturn number
function Menu:GetMenuIndex()
    return self.menu:GetIndex()
end

--- Sets menu index.
-- @tparam number idx
function Menu:SetMenuIndex(idx)
    self.menu:SetIndex(idx)
end

--- Clears menu and options.
function Menu:Clear()
    self.menu = nil
    self.options = {}
end

--- Options
-- @section options

--- Adds divider option.
function Menu:AddDividerOption()
    table.insert(self.options, DividerOption())
end

--- Adds toggle option.
-- @tparam string label
-- @tparam table get
-- @tparam table set
-- @tparam number idx
function Menu:AddToggleOption(label, get, set, idx)
    if not get.src or not set.src then
        return
    end

    table.insert(
        self.options,
        ToggleCheckboxOption({
            label = label,
            get = get,
            set = set,
            on_accept_fn = function()
                return idx and self.screen:UpdateMenu(idx)
            end,
        })
    )
end

--- Adds grab profile option.
function Menu:AddGrabProfileOption()
    table.insert(
        self.options,
        ActionOption({
            label = "Grab Profile",
            on_accept_fn = function()
                TheSim:Profile()
                self.screen:Close()
            end,
        })
    )
end

--- Menu
-- @section menu

--- Adds submenu.
-- @tparam table|menu.Submenu submenu Data table or class (not an instance)
function Menu:AddSubmenu(submenu)
    if not self.devtools or not self.options then
        return
    end

    if submenu._ctor then
        return submenu(self.devtools, self.options)
    elseif type(submenu) == "table" then
        return self.devtools:CreateSubmenuInstFromData(submenu, self.options)
    end
end

--- Adds select submenus.
-- @see AddMenu
function Menu:AddSelectSubmenu()
    self:AddSubmenu(SelectSubmenu)
    self:AddDividerOption()
end

--- Adds selected player submenus.
-- @see AddMenu
function Menu:AddSelectedPlayerSubmenus()
    local devtools = self.devtools
    local playertools = devtools.player

    if SDK.Player.IsAdmin() then
        local player = playertools:GetSelected()
        local prefix = #AllPlayers > 1 and string.format("[ %s ]  ", player:GetDisplayName()) or ""

        self:AddToggleOption(
            { name = "God Mode", prefix = prefix },
            { src = playertools, name = "IsGodMode" },
            { src = playertools, name = "ToggleGodMode" }
        )

        self:AddToggleOption(
            { name = "Free Crafting", prefix = prefix },
            { src = SDK.Player.Craft, name = "HasFreeCrafting", args = { player } },
            { src = SDK.Player.Craft, name = "ToggleFreeCrafting", args = { player } },
            3
        )

        self:AddSubmenu(PlayerBarsSubmenu)
        self:AddSubmenu(TeleportSubmenu)
        self:AddDividerOption()
    end
end

--- Adds player submenus.
-- @see AddMenu
function Menu:AddPlayerSubmenus()
    if not SDK.World.IsMasterSim() then
        self:AddToggleOption(
            { name = "Movement Prediction" },
            { src = SDK.Player, name = "HasMovementPrediction", args = {} },
            { src = SDK.Player, name = "ToggleMovementPrediction", args = {} }
        )
    end

    self:AddSubmenu(CharacterRecipesSubmenu)
    self:AddSubmenu(Labels)
    self:AddSubmenu(Map)
    self:AddSubmenu(PlayerVision)
    self:AddDividerOption()
end

--- Adds world submenus.
-- @see AddMenu
function Menu:AddWorldSubmenus()
    self:AddSubmenu(SeasonControl)
    self:AddSubmenu(TimeControl)
    self:AddSubmenu(WeatherControl)
    self:AddDividerOption()
end

--- Adds mods submenus.
function Menu:AddModsSubmenus()
    self:AddSubmenu(DevTools)
    local submenus = self.devtools:GetSubmenusData()
    if #submenus > 0 then
        for _, submenu in pairs(submenus) do
            self:AddSubmenu(submenu)
        end
    end
    self:AddDividerOption()
end

--- Adds general submenus.
-- @see AddMenu
function Menu:AddGeneralSubmenus()
    self:AddSubmenu(Debug)
    self:AddSubmenu(DumpSubmenu)
    self:AddSubmenu(Language)
    self:AddDividerOption()
    self:AddGrabProfileOption()
end

--- Adds menu.
-- @see AddGeneralSubmenus
-- @see AddPlayerSubmenus
-- @see AddSelectedPlayerSubmenus
-- @see AddSelectSubmenu
-- @see AddWorldSubmenus
function Menu:AddMenu()
    self.menu = TextMenu(self.screen, self.title)

    local devtools = self.devtools
    local playertools = devtools.player
    local worldtools = devtools.world

    if devtools and worldtools and playertools then
        self:AddSelectSubmenu()
        self:AddSelectedPlayerSubmenus()
        self:AddPlayerSubmenus()
        if SDK.Player.IsAdmin() then
            self:AddWorldSubmenus()
        end
    end

    self:AddModsSubmenus()
    self:AddGeneralSubmenus()
end

--- Update
-- @section update

--- Updates menu.
--
-- Clears menu (`menu.TextMenu`) and recreates it.
--
-- @see AddMenu
-- @see menu.TextMenu
function Menu:Update()
    self:Clear()
    self:AddMenu()
    self.menu:PushOptions(self.options, "")
end

--- Other
-- @section other

--- __tostring
-- @treturn string
function Menu:__tostring()
    return tostring(self.menu)
end

return Menu
