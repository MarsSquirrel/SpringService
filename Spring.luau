local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)

local Spring = {}
Spring.__index = Spring

local function SpringDuration(start, target, velocity, response, damping)
	local epsilon = 0.001

	local displacement = start - target

	local omega = 2 * math.pi / response

	if damping >= 1 then
		return math.log(math.abs(displacement) / epsilon) / omega
	end

	local dampedOmega = omega * math.sqrt(1 - damping^2)
	local peakAmp = math.sqrt(displacement^2 + ((velocity + damping * omega * displacement) / dampedOmega)^2)

	return math.log(peakAmp / epsilon) / (damping * omega)
end

local function SpringAnimation(start, target, velocity, response, damping, dt)
	local displacement = start - target

	local omega = 2 * math.pi / response

	local expTerm = math.exp(-damping * omega * dt)

	local cosTerm, sinTerm
	if damping < 1 then
		local dampedOmega = omega * math.sqrt(1 - damping^2)
		cosTerm = math.cos(dampedOmega * dt)
		sinTerm = math.sin(dampedOmega * dt)

		local coeff = (velocity + damping * omega * displacement) / dampedOmega

		displacement = expTerm * (displacement * cosTerm + coeff * sinTerm)
		velocity = expTerm * (velocity * (cosTerm - damping * omega * sinTerm/dampedOmega) - displacement * omega * sinTerm * dampedOmega)
	else
		displacement = expTerm * (displacement + (velocity + omega * displacement) * dt)
		velocity = expTerm * (velocity - omega * (velocity + omega * displacement) * dt)
	end

	return target + displacement, velocity
end

function Spring.new(object: GuiObject, response: number, damping: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)

	self.Response = response
	self.Damping = damping

	self.Velocity = 0
	self.Target = properties
	self.Object = object

	self.Time = 0
	self.TimeLength = SpringDuration(0, 1, self.Velocity, self.Response, self.Damping)

	self.Connection = nil

	self.Finished = Signal.new()
	self.Stopped = Signal.new()
	
	return self
end

function Spring:SetTarget(properties:{[string]: any})
	for property, targetValue in pairs(properties) do
		for property2, _ in pairs(self.Target) do
			if property == property2 then
				self.Target[property2] = targetValue
				continue
			end
		end

		self.Target[property] = targetValue
	end
end

function Spring:Play(graph: Frame?)
	local velocities = {}
	local graphY = 0
	local graphV = 0

	self.Connection = RunService.RenderStepped:Connect(function(deltaTime)
		self.Time += deltaTime

		if self.Time >= self.TimeLength then
			self.Connection:Disconnect()
			self.Connection = nil
			self.Time = 0
			self.Finished:Fire()
		end
		
		for property, targetValue in pairs(self.Target) do
			if self.Object[property] == nil then
				continue
			end

			if self.Object[property] == targetValue then
				continue
			end

			if property == "Position" or property == "Size" then
				local x1 = self.Object[property].X.Scale
				local x2 = self.Object[property].X.Offset
				local y1 = self.Object[property].Y.Scale
				local y2 = self.Object[property].Y.Offset

				local s1, s2, s3, s4 = 0, 0, 0, 0
				local v1, v2, v3, v4 = 0, 0, 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1, v2, v3, v4 = unpack(v)
						break
					end
				end

				s1, v1 = SpringAnimation(x1, targetValue.X.Scale, v1, self.Response, self.Damping, deltaTime)
				s2, v2 = SpringAnimation(x2, targetValue.X.Offset, v2, self.Response, self.Damping, deltaTime)
				s3, v3 = SpringAnimation(y1, targetValue.Y.Scale, v3, self.Response, self.Damping, deltaTime)
				s4, v4 = SpringAnimation(y2, targetValue.Y.Offset, v4, self.Response, self.Damping, deltaTime)

				velocities[property] = {v1,v2,v3,v4}

				self.Object[property] = UDim2.new(s1, s2, s3, s4)
			end

			if property == "AnchorPoint" then
				local x = self.Object.AnchorPoint.X
				local y = self.Object.AnchorPoint.Y

				local s1, s2 = 0, 0
				local v1, v2 = 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1, v2 = unpack(v)
						break
					end
				end

				s1, v1 = SpringAnimation(x, targetValue.X, v1, self.Response, self.Damping, deltaTime)
				s2, v2 = SpringAnimation(y, targetValue.Y, v2, self.Response, self.Damping, deltaTime)
				
				velocities[property] = {v1, v2}
				self.Object.AnchorPoint = Vector2.new(s1, s2)
			end

			if property == "Rotation" then
				local rotation = self.Object.Rotation
				local s1, v1 = 0, 0

				for i, v in pairs(velocities) do
					if i == property then
						v1 = v[1]
						break
					end
				end
				
				s1, v1 = SpringAnimation(rotation, targetValue, v1, self.Response, self.Damping, deltaTime)
				velocities[property] = {v1}
				self.Object.Rotation = s1
			end
		end

		graphY, graphV = SpringAnimation(graphY, 1, graphV, self.Response, self.Damping, deltaTime)

		if graph then
			local dot = Instance.new("Frame", graph)
			dot.BackgroundColor3 = Color3.new(1, 0, 0)
			dot.BorderSizePixel = 0
			dot.Size = UDim2.new(.025, 0, 0.05, 0)
			dot.AnchorPoint = Vector2.new(0.5, 0.5)

			local corner = Instance.new("UICorner", dot)
			corner.CornerRadius = UDim.new(0.5, 0)

			local ratio = Instance.new("UIAspectRatioConstraint", dot)
			ratio.AspectRatio = 1

			dot.Position = UDim2.new(self.Time/self.TimeLength, 0, 1-graphY, 0)
		end
	end)
end

function Spring:PlayAndWait()
	self:Play()
	self.Finished:Wait()
end

function Spring:Stop()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil

		self.Velocity = 0

		self.Stopped:Fire()
	end
end

return Spring
