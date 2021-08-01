--[[
	This is just an empty script so we can do a global search for things to display on the overlay
]]--

local NUIOverlayTarget = {}

NUIOverlayTarget.Properties = {
	{ name = "show",					type = "boolean",	default = true,	tooltip = "Whether to show this entity on the User overlay" },
	{ name = "type",					type = "string",	options = { "primary", "secondary", "tertiary" }, default = "primary" },
	{ name = "showName",				type = "boolean",	default = false },
	{ name = "showDistance",			type = "boolean",	default = false },
	{ name = "targetPositionOffset",	type = "vector",	default = Vector.New(0, 0, 150),	tooltip = "A vector offset to combine with the targets position to adjust where it displays on-screen" },
}

return NUIOverlayTarget
