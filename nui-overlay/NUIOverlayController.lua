local NUIOverlayController = {}

NUIOverlayController.Properties = {
	{ name = "scanIntervalTime",		type = "number",	default = 3,						tooltip = "The frequency in seconds to scan for overlay targets" },
}

-- what is this massive gap for Shaun


function NUIOverlayController:LocalInit()	
	self.overlayTargets = {}
	
	self:Schedule(function() while true do
		self:SearchForTargets()
		Wait(self.properties.scanIntervalTime)
	end end)
end


function NUIOverlayController:SearchForTargets()
	if IsServer() then
		self:SendToLocal("SearchForTargets")
		return
	end	
	
	local targets = GetWorld():FindAllScripts("NUIOverlayTarget")
	
	self.overlayTargets = {}
	
	for _, target in ipairs(targets) do
		if target:GetEntity():FindScriptProperty("show") == true then
			table.insert(self.overlayTargets, target:GetEntity())
		end
	end
end


function NUIOverlayController:LocalOnTick(dt)
	-- Check we actually have a list of overlay targets
	if self.overlayTargets == nil then return end
	
	local targetUIPositions = {}
	
	-- Loop through each target..
	for _, target in ipairs(self.overlayTargets) do
		
		-- Make sure the target is valid (not removed from the game or anything)
		if target == nil or target:IsValid() == false then return end
		
		local targetPos = target:GetPosition()
		local playerPos = self:GetEntity():GetPlayer():GetPosition()
		
		local distance = -1
		if target:FindScriptProperty("showDistance") then
			local rawDistance = math.sqrt((targetPos.x - playerPos.x) ^ 2 + (targetPos.y - playerPos.y) ^ 2 + (targetPos.z - playerPos.z) ^ 2)
			distance = math.floor(rawDistance / 100)
		end
		
		-- Get the target's projected screen coordinates
		-- Combine with a user-defined offset to adjust where on the screen it displays
		-- e.g. GetPosition() on some meshes will return the bottom center, you might want to raise it a bit off the ground
		local screenPos = self:GetEntity():ProjectPositionToScreen(targetPos + target:FindScriptProperty("targetPositionOffset"))
		local onScreen = true
		
		-- If the target is not nil, that means it is on screen, so grab the coordinates
		if screenPos == nil then
			onScreen = false
			-- Off screen, so calculate where it should go based on position
			local camPos, lookPos = self:GetEntity():GetCameraLookAt()
			local lookVector = (lookPos - camPos):Normalize()
			local targetVector = camPos - targetPos
			local targetOffset = 2 * Vector.Dot(lookVector, targetVector) * lookVector
			local mirroredTargetPos = targetPos + targetOffset
			screenPos = self:GetEntity():ProjectPositionToScreen(mirroredTargetPos)
			
			-- Still sometimes returns nil, unsure why but skipping these is hardly noticeable
			if not screenPos then return end
		end
		
		-- Work out if it's pushed against an edge
		if not onScreen or screenPos.x < 0 or screenPos.x > 1
			or screenPos.y < 0 or screenPos.y > 1 then
			onScreen = false
			
			-- As this is now behind us, push indicator to a screen edge
			local xFromCenter = screenPos.x - 0.5
			local yFromCenter = screenPos.y - 0.5
			local largerVal = math.abs(math.abs(xFromCenter) > math.abs(yFromCenter)
				and xFromCenter or yFromCenter)
			xFromCenter = xFromCenter / largerVal
			yFromCenter = yFromCenter / largerVal
			screenPos.x = (xFromCenter + 1) / 2
			screenPos.y = (yFromCenter + 1) / 2
		end
		
		screenPos.x = math.clamp(screenPos.x, 0, 1)
		screenPos.y = math.clamp(screenPos.y, 0, 1)
		
		local rotation = 0
			if not onScreen then
			if screenPos.x == 0 then
				rotation = 90
			elseif screenPos.x == 1 then
				rotation = -90
			elseif screenPos.y == 0 then
				rotation = 180
			end
		end
		
		-- Use the entity name to refer to it
		local targetName = target:FindScriptProperty("showName") and target:GetName() or ""
		
		-- ProjectPositionToScreen returns a value between 0 (top left) and 1 (bottom right), so *100 for UI positioning 
		table.insert(targetUIPositions, 
			{ 
				name = targetName,
				distance = distance,
				posX = screenPos.x * 100,
				posY = screenPos.y * 100,
				onScreen = onScreen,
				rotation = rotation,
				overlayType = target:FindScriptProperty("type")
			})
	end
	
	-- If the overlay UI is available, and we have targets to show..
	if self:GetEntity().NUIOverlayUI ~= nil then
	
		if targetUIPositions ~= nil and #targetUIPositions > 0 then
			-- Update the data and show the UI
			self:GetEntity().NUIOverlayUI.js:CallFunction("UpdateData", targetUIPositions)
			self:GetEntity().NUIOverlayUI:Show()
		else
			-- Otherwise, hide the UI
			self:GetEntity().NUIOverlayUI:Hide()
		end
	end
end

return NUIOverlayController
