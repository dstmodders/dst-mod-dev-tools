----
-- Divider option.
--
-- Extends `menu.option.Option`.
--
--    local divideroption = DividerOption()
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-dev-tools](https://github.com/victorpopkov/dst-mod-dev-tools)
--
-- @classmod menu.option.DividerOption
-- @see menu.option.Option
--
-- @author Victor Popkov
-- @copyright 2020
-- @license MIT
-- @release 0.1.0-alpha
----
require "class"

local Option = require "devtools/menu/option/option"

--- Constructor.
-- @function _ctor
-- @usage local divideroption = DividerOption()
local DividerOption = Class(Option, function(self)
    Option._ctor(self, { label = "" })
    self.is_divider = true
end)

return DividerOption
