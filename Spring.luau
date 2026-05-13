local RunService = game:GetService("RunService")

-- GoodSignal implementation by stravant
local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread()
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	self._connected = false

	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_handlerListHead = false,
	}, Signal)
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:DisconnectAll()
	self._handlerListHead = false
end

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				-- Get the freeRunnerThread to the first yield
				coroutine.resume(freeRunnerThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn;
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

function Signal:Once(fn)
	local cn;
	cn = self:Connect(function(...)
		if cn._connected then
			cn:Disconnect()
		end
		fn(...)
	end)
	return cn
end

setmetatable(Signal, {
	__index = function(tb, key)
		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

-- SPRING CLASS STARTS

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

function Spring.new(instace: Instance, response: number, damping: number, properties: {[string]: any})
	local self = setmetatable({}, Spring)

	self.Response = response
	self.Damping = damping

	self.Velocity = 0
	self.Target = properties
	self.Instance = instace

	self.Time = 0
	self.TimeLength = SpringDuration(0, 1, self.Velocity, self.Response, self.Damping)

	self._Connection = nil

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
	
	
	self.TimeLength += SpringDuration(0, 1, self.Velocity, self.Response, self.Damping)
end

function Spring:Play()
	local velocities = {}

	self._Connection = RunService.RenderStepped:Connect(function(deltaTime)
		self.Time += deltaTime

		if self.Time >= self.TimeLength then
			self._Connection:Disconnect()
			self._Connection = nil
			self.Time = 0
			self.Finished:Fire()
		end

		for property, targetValue in pairs(self.Target) do
			if self.Instance[property] == nil then
				continue
			end

			if self.Instance[property] == targetValue then
				continue
			end

			if property == "Position" or property == "Size" then
				local x1 = self.Instance[property].X.Scale
				local x2 = self.Instance[property].X.Offset
				local y1 = self.Instance[property].Y.Scale
				local y2 = self.Instance[property].Y.Offset

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

				self.Instance[property] = UDim2.new(s1, s2, s3, s4)
			end

			if property == "AnchorPoint" then
				local x = self.Instance.AnchorPoint.X
				local y = self.Instance.AnchorPoint.Y

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
				self.Instance.AnchorPoint = Vector2.new(s1, s2)
			end

			if property == "Rotation" then
				local rotation = self.Instance.Rotation
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
	end)
end

function Spring:PlayAndWait()
	self:Play()
	self.Finished:Wait()
end

function Spring:Stop()
	if self._Connection then
		self._Connection:Disconnect()
		self._Connection = nil

		self.Velocity = 0

		self.Stopped:Fire()
	end
end

return Spring
