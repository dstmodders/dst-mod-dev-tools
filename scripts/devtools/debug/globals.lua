----
-- Debug globals.
--
-- Includes globals debugging functionality as a part of `Debug`. Shouldn't be used on its own.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-dev-tools](https://github.com/victorpopkov/dst-mod-dev-tools)
--
-- @classmod debug.Globals
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.7.0
----
require "class"

local SDK = require "devtools/sdk/sdk/sdk"

--- Lifecycle
-- @section lifecycle

--- Constructor.
-- @function _ctor
-- @tparam Debug debug
-- @usage local globals = Globals(debug)
local Globals = Class(function(self, debug)
    SDK.Debug.AddMethods(self)

    -- general
    self.debug = debug

    -- overrides
    self.OldSendRPCToServer = _G.SendRPCToServer
    _G.SendRPCToServer = function(...) -- luacheck: only
        self:SendRPCToServer(...)
        self.OldSendRPCToServer(...)
    end

    -- other
    self:DebugInit("Debug (Globals)")
end)

--- General
-- @section general

--- SendRPCToServer.
-- @tparam any ...
function Globals:SendRPCToServer(...)
    if SDK.Debug.IsDebug("rpc") then
        print(string.format("[debug] [rpc] %s", self.debug:SendRPCToServerString(...)))
    end
end

return Globals
