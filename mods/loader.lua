local Focus = getfenv(0).FocusData
local Loader = CreateFrame("Frame")
Loader.addons = {}

local function debug(str)
	if false then
		DEFAULT_CHAT_FRAME:AddMessage(str)
	end
end

local EventHandler = function()
	if this[event] then
		return this[event](this, arg1)
	end
end

function Loader:FreeLoadedAddons()
	if not next(self.addons) then
		return debug("empty addon list")
	end

	for k, v in pairs(self.addons) do
		if not v.onDemand or (v.hasRan and not v.loaded) then
			self.addons[k] = nil
			debug("free " .. k)
		end
	end
end

function Loader:ADDON_LOADED(addonName)
	if self.addons[addonName] then
		local success = pcall(self.addons[addonName].init, Focus)
		self.addons[addonName].loaded = success
		self.addons[addonName].hasRan = true

		debug(addonName .. " = " .. (success and "1" or "0"))
	end
end

function Loader:PLAYER_ENTERING_WORLD()
	self:FreeLoadedAddons()

	-- All registered addons loaded, run cleanup
	if not next(self.addons) then
		self:UnregisterEvent("ADDON_LOADED")
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		self:SetScript("OnEvent", nil)

		for k, v in pairs(self) do
			self[k] = nil
		end

		debug("all free")
	end
end

--- Register callback to be ran when ADDON_LOADED event is fired for addonName
-- @tparam string addonName
-- @tparam func callback
-- @tparam[opt=false] bool - True if addon is loaded on demand, and not instantly on login.
function Loader:Register(addonName, callback, onDemand)
	if type(addonName) ~= "string" or type(callback) ~= "function" then
		return error('Usage: Register("name", callbackFunc, false)')
	end

	self.addons[addonName] = {
		init = callback,
		loaded = false,
		hasRan = false,
		onDemand = onDemand
	}

	debug("registered " .. addonName)

	-- Trigger event ourselves if addon is already loaded
	if IsAddOnLoaded(addonName) then
		self:ADDON_LOADED(addonName)
	end
end

Loader:RegisterEvent("ADDON_LOADED")
Loader:RegisterEvent("PLAYER_ENTERING_WORLD")
Loader:SetScript("OnEvent", EventHandler)
Loader:Hide()

-- add to global namespace
Focus_Loader = Loader