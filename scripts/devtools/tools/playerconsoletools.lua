----
-- Player console commands.
--
-- Extends `tools.Tools` and includes different functionality to send remote console commands for
-- both the player and the world.
--
-- Of course, the mod owner should have administrator rights on the server for most methods to work.
--
-- When available, all (or most) methods can be accessed within `DevTools` global class:
--
--    DevTools:...
--
-- Or the whole module can be accessed directly through the same global `DevTools`:
--
--    DevTools.player.console
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-dev-tools](https://github.com/victorpopkov/dst-mod-dev-tools)
--
-- @classmod tools.PlayerConsoleTools
-- @see DevTools
-- @see tools.PlayerTools
-- @see tools.Tools
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.7.0
----
local DevTools = require "devtools/tools/tools"
local SDK = require "devtools/sdk/sdk/sdk"

local _RemoteSend = SDK.Remote.Send

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam PlayerTools playertools
-- @tparam DevTools devtools
-- @usage local playerconsoletools = PlayerConsoleTools(playertools, devtools)
local PlayerConsoleTools = Class(DevTools, function(self, playertools, devtools)
    DevTools._ctor(self, "PlayerConsoleTools", devtools)

    -- asserts
    SDK.Utils.AssertRequiredField(self.name .. ".playertools", playertools)
    SDK.Utils.AssertRequiredField(self.name .. ".world", playertools.world)
    SDK.Utils.AssertRequiredField(self.name .. ".inst", playertools.inst)

    -- general
    self.inst = playertools.inst
    self.playertools = playertools
    self.worldtools = playertools.world

    -- tests
    if _G.MOD_DEV_TOOLS_TEST then
        _RemoteSend = _G.RemoteSend
    end

    -- other
    self:DoInit()
end)

--- Helpers
-- @section helpers

local function IsNumber(value)
    return type(value) == "number"
end

local function IsNumberBetweenZeroAndOne(value)
    return IsNumber(value) and value >= 0 and value <= 1
end

local function IsMoisture(value)
    return IsNumber(value) and value >= 0 and value <= 100
end

local function IsPercent(value)
    return IsNumber(value) and value >= 0 and value <= 100
end

local function IsPosition(value)
    return type(value) == "table" and value.x and value.y and value.z
end

local function IsTemperature(value)
    return IsNumber(value) and value >= -20 and value <= 90
end

local function IsSeason(value)
    return value == "autumn" or value == "spring" or value == "summer" or value == "winter"
end

local function IsString(value)
    return type(value) == "string" and string.len(value) > 0
end

local function PointToString(value)
    return IsPosition(value) and string.format(
        "Point(%0.2f, %0.2f, %0.2f)",
        value.x,
        value.y,
        value.z
    )
end

local function DebugPercent(value)
    return IsNumber(value) and string.format("%d", value) .. "%"
end

local function DebugPosition(value)
    return IsPosition(value) and string.format(
        "(%0.2f, %0.2f, %0.2f)",
        value.x,
        value.y,
        value.z
    )
end

local function IsValidValues(values, check_fns)
    if type(values) ~= "table" then
        if type(check_fns) == "function" then
            return check_fns(values)
        elseif check_fns == nil then
            return true
        end
    end

    if type(values) ~= "table" and type(check_fns) ~= "table" then
        return false
    end

    local check_fn, value
    for i = 1, #values, 1 do
        check_fn = check_fns[i]
        value = values[i]
        if type(check_fn) == "function" and not check_fns[i](value) then
            return false
        end
    end

    return true
end

local function DebugValues(values)
    if type(values) ~= "table" then
        return tostring(values)
    end

    if IsPosition(values) then
        return DebugPosition(values)
    end

    local result = {}

    for _, value in pairs(values) do
        if IsPosition(value) then
            value = DebugPosition(value)
        end

        table.insert(result, tostring(value))
    end

    return table.concat(result, ", ")
end

local function Remote(self, fn_name, console, values, check_values_fns, debug, debug_fn)
    local fn_full_name = self:GetFnFullName(fn_name)
    local debug_values = DebugValues(values)

    debug = debug ~= nil and debug or { fn_full_name .. ":", debug_values }
    debug_fn = debug_fn ~= nil and debug_fn or self.DebugString

    if not SDK.Player.IsAdmin() then
        self:DebugError(fn_full_name .. ":", "not an admin")
        return false
    end

    if console and debug and IsValidValues(values, check_values_fns) then
        if check_values_fns == IsPosition then
            local command = console[1]
            local args = console[2]
            local pos = args[1]
            if IsPosition(pos) then
                args[1] = PointToString(pos)
                console = { command, args }
            end
        end

        _RemoteSend(unpack(console))
        debug_fn(self, unpack(debug))
        return true
    end

    self:DebugError(
        fn_full_name .. ":",
        "invalid value",
        values ~= nil
            and string.format("(%s)", debug_values)
            or nil
    )

    return false
end

local function RemoteSelectedPlayer(self, fn_name, console, value, check, debug)
    return Remote(self, fn_name, console, value, check, debug)
end

--- Player
-- @section player

--- Sets player health value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetHealthPercent(value)
    local console = value ~= nil and { 'c_sethealth(%0.2f)', { value / 100 } }
    local debug = value ~= nil and { "Health:", DebugPercent(value) }
    return RemoteSelectedPlayer(self, "SetHealthPercent", console, value, IsPercent, debug)
end

--- Sets player hunger value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetHungerPercent(value)
    local console = value ~= nil and { 'c_sethunger(%0.2f)', { value / 100 } }
    local debug = value ~= nil and { "Hunger:", DebugPercent(value) }
    return RemoteSelectedPlayer(self, "SetHungerPercent", console, value, IsPercent, debug)
end

--- Sets player sanity value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetSanityPercent(value)
    local console = value ~= nil and { 'c_setsanity(%0.2f)', { value / 100 } }
    local debug = value ~= nil and { "Sanity:", DebugPercent(value) }
    return RemoteSelectedPlayer(self, "SetSanityPercent", console, value, IsPercent, debug)
end

--- Sets player max health value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetMaxHealthPercent(value)
    local debug = value ~= nil and { "Maximum Health:", DebugPercent(value) }
    return RemoteSelectedPlayer(self, "SetMaxHealthPercent", value ~= nil and {
        "ConsoleCommandPlayer().components.health:SetPenalty(%0.2f)",
        { 1 - (value / 100) },
    }, value, IsPercent, debug)
end

--- Sets player moisture value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetMoisturePercent(value)
    local console = value ~= nil and { 'c_setmoisture(%0.2f)', { value / 100 } }
    local debug = value ~= nil and { "Moisture:", DebugPercent(value) }
    return RemoteSelectedPlayer(self, "SetMoisturePercent", console, value, IsMoisture, debug)
end

--- Sets player temperature value.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetTemperature(value)
    local console = value ~= nil and { "c_settemperature(%0.2f)", { value } }
    local debug = value ~= nil and { "Temperature:", tostring(value) }
    return RemoteSelectedPlayer(self, "SetTemperature", console, value, IsTemperature, debug)
end

--- Sets player wereness level.
-- @tparam number value
-- @treturn boolean
function PlayerConsoleTools:SetWerenessPercent(value)
    local debug = value ~= nil and { "Wereness:", tostring(value) }
    return RemoteSelectedPlayer(self, "SetWerenessPercent", value ~= nil and {
        "ConsoleCommandPlayer().components.wereness:SetPercent(%0.2f)",
        { value }
    }, value, IsPercent, debug)
end

--- Teleport
-- @section teleport

--- Teleports to the specified entity.
-- @tparam string name Name of an entity
-- @tparam string value Entity (prefab)
-- @treturn boolean
function PlayerConsoleTools:GoNext(name, value)
    local console = value ~= nil and { 'c_gonext("%s")', { value } }
    local debug = name ~= nil and { "Teleported to", name }
    return RemoteSelectedPlayer(self, "GoNext", console, value, IsString, debug)
end

--- Gathers all players.
--
-- All players are teleported to the mouse pointer location.
--
-- @treturn boolean
function PlayerConsoleTools:GatherPlayers()
    local console = { "c_gatherplayers()" }
    local debug = { "Gathered players" }
    return Remote(self, "GatherPlayers", console, nil, nil, debug)
end

--- World
-- @section world

--- Sets world delta moisture.
-- @tparam number delta
-- @treturn boolean
function PlayerConsoleTools:DeltaMoisture(delta)
    local console = delta ~= nil and { 'TheWorld:PushEvent("ms_deltamoisture", %d)', { delta } }
    return Remote(self, "DeltaMoisture", console, delta, IsNumber)
end

--- Sets world delta wetness.
-- @tparam number delta
-- @treturn boolean
function PlayerConsoleTools:DeltaWetness(delta)
    local console = delta ~= nil and { 'TheWorld:PushEvent("ms_deltawetness", %d)', { delta } }
    return Remote(self, "DeltaWetness", console, delta, IsNumber)
end

--- Summons mini earthquake.
-- @tparam table|string target Player instance or his/her ID
-- @tparam number rad Radius
-- @tparam number num Amount
-- @tparam number time Duration
-- @treturn boolean
function PlayerConsoleTools:MiniQuake(target, rad, num, time)
    target = target ~= nil and target or self.inst
    rad = rad ~= nil and rad or 20
    num = num ~= nil and num or 20
    time = time ~= nil and time or 2.5

    local fn_name = "MiniQuake"

    if not SDK.World.IsCave() then
        self:DebugError(self:GetFnFullName(fn_name) .. ":", "not in the cave world")
        return false
    end

    local check_values_fns, command, console, values

    check_values_fns = { IsString, IsNumber, IsNumber, IsNumber }
    command = 'TheWorld:PushEvent("ms_miniquake", { target = LookupPlayerInstByUserID("%s"), rad = %d, num = %d, duration = %0.2f })' -- luacheck: only
    values = {
        (type(target) == "table" and target.userid) and target.userid or target,
        rad,
        num,
        time
    }

    console = { command, values }

    return Remote(self, fn_name, console, values, check_values_fns)
end

--- Pushes world event.
-- @tparam string event
-- @treturn boolean
function PlayerConsoleTools:PushWorldEvent(event)
    local console = event ~= nil and { 'TheWorld:PushEvent("%s")', { event } }
    return Remote(self, "PushWorldEvent", console, event, IsString)
end

--- Sends lightning strike.
-- @tparam Point pos Position
-- @treturn boolean
function PlayerConsoleTools:SendLightningStrike(pos)
    local fn_name = "SendLightningStrike"

    if SDK.World.IsCave() then
        self:DebugError(self:GetFnFullName(fn_name) .. ":", "not in the forest world")
        return false
    end

    local console = pos ~= nil and { 'TheWorld:PushEvent("ms_sendlightningstrike", %s)', { pos } }
    return Remote(self, fn_name, console, pos, IsPosition)
end

--- Sets season.
-- @tparam string season
-- @treturn boolean
function PlayerConsoleTools:SetSeason(season)
    local console = season ~= nil and { 'TheWorld:PushEvent("ms_setseason", "%s")', { season } }
    return Remote(self, "SetSeason", console, season, IsSeason)
end

--- Sets season length.
-- @tparam string season
-- @tparam number length
-- @treturn boolean
function PlayerConsoleTools:SetSeasonLength(season, length)
    return Remote(self, "SetSeasonLength", (season ~= nil and length ~= nil) and {
        'TheWorld:PushEvent("ms_setseasonlength", { season="%s", length=%d })',
        { season, length }
    }, { season, length }, { IsSeason, IsNumber })
end

--- Sets snow level.
-- @tparam number delta
-- @treturn boolean
function PlayerConsoleTools:SetSnowLevel(delta)
    local fn_name = "SetSnowLevel"

    if SDK.World.IsCave() then
        self:DebugError(self:GetFnFullName(fn_name) .. ":", "not in the forest world")
        return false
    end

    return Remote(self, fn_name, delta ~= nil and {
        'TheWorld:PushEvent("ms_setsnowlevel", %0.2f)',
        { delta }
    }, delta, IsNumberBetweenZeroAndOne)
end

--- Sets time scale.
-- @tparam string timescale
-- @treturn boolean
function PlayerConsoleTools:SetTimeScale(timescale)
    local fn_name = 'SetTimeScale'

    if self.devtools and #SDK.Player.GetClientTable(nil, true) > 1 then
        self:DebugError(fn_name .. ":", "There are other players on the server")
        return false
    end

    local console = timescale ~= nil and { 'TheSim:SetTimeScale(%0.2f)', { timescale } }
    return Remote(self, fn_name, console, timescale, IsNumber)
end

--- Crafting
-- @section crafting

--- Toggles free crafting mode.
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function PlayerConsoleTools:ToggleFreeCrafting(player)
    player = player ~= nil and player or self.inst

    local fn_name = "ToggleFreeCrafting"
    local check_values_fns, command, console, userid, values

    check_values_fns = { IsString }
    command = 'player = LookupPlayerInstByUserID("%s") player.components.builder:GiveAllRecipes() player:PushEvent("techlevelchange")' -- luacheck: only
    userid = (type(player) == "table" and player.userid) and player.userid or player
    values = { userid }
    console = { command, values }

    return Remote(self, fn_name, console, values, check_values_fns)
end

--- Unlocks provided recipe.
-- @tparam string recipe
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function PlayerConsoleTools:UnlockRecipe(recipe, player)
    player = player ~= nil and player or self.inst

    local fn_name = "UnlockRecipe"
    local check_values_fns, command, console, userid, values

    check_values_fns = { IsString, IsString, IsString }
    command = 'player = LookupPlayerInstByUserID("%s") player.components.builder:AddRecipe("%s") player:PushEvent("unlockrecipe", { recipe = "%s" })' -- luacheck: only
    userid = (type(player) == "table" and player.userid) and player.userid or player
    values = { userid, recipe, recipe }
    console = { command, values }

    return Remote(self, fn_name, console, values, check_values_fns)
end

--- Locks provided recipe.
-- @tparam string recipe
-- @tparam[opt] EntityScript player Player instance (the owner by default)
-- @treturn boolean
function PlayerConsoleTools:LockRecipe(recipe, player)
    player = player ~= nil and player or self.inst

    local fn_name = "LockRecipe"
    local check_values_fns, command, console, userid, values

    check_values_fns = { IsString, IsString, IsString }
    command = 'player = LookupPlayerInstByUserID("%s") for k, v in pairs(player.components.builder.recipes) do if v == "%s" then table.remove(player.components.builder.recipes, k) end end player.replica.builder:RemoveRecipe("%s")' -- luacheck: only
    userid = (type(player) == "table" and player.userid) and player.userid or player
    values = { userid, recipe, recipe }
    console = { command, values }

    return Remote(self, fn_name, console, values, check_values_fns)
end

--- Lifecycle
-- @section lifecycle

--- Initializes.
function PlayerConsoleTools:DoInit()
    DevTools.DoInit(self, self.playertools, "console", {
        -- player
        "SetHealthPercent",
        "SetHungerPercent",
        "SetSanityPercent",
        "SetMaxHealthPercent",
        "SetMoisturePercent",
        "SetTemperature",
        "SetWerenessPercent",

        -- teleport
        "GoNext",
        "GatherPlayers",

        -- world
        "DeltaMoisture",
        "DeltaWetness",
        "MiniQuake",
        "PushWorldEvent",
        "SendLightningStrike",
        "SetSeason",
        "SetSeasonLength",
        "SetSnowLevel",
        "SetTimeScale",

        -- crafting
        --"ToggleFreeCrafting",
        "UnlockRecipe",
        "LockRecipe",
    })
end

return PlayerConsoleTools
