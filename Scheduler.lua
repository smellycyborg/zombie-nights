local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
	local scheduler = setmetatable({}, Scheduler)

	scheduler._shutdown = false
	scheduler._canShutDownSafely = true

	return scheduler
end

function Scheduler:interval(intervalSec,startImmediately, callback)
	if self._shutdown then
		warn("MESSAGE/Warn:  Attempt to run scheduler that has been shutdown.")
	end

	if not startImmediately then
		task.wait(intervalSec)
	end

	task.spawn(function()
		while not self._shutdown do
			callback()

			task.wait(intervalSec)
		end
	end)
end

function Scheduler:shutdown()
	self._shutdown = true
end

return Scheduler
