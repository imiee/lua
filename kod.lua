warn("wsg")

if not game:IsLoaded() then game.Loaded:Wait() end

function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId
local JobId = game.JobId

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local LoopConnection = true

local ORBIT_RADIUS = 5
local ORBIT_SPEED = 6
local ATTACK_RANGE = 80
local RETREAT_THRESHOLD = 50

local function createLoop(KnifeSpawn)
	local Conn;
	local angle = 0

	task.spawn(function()
		local lastTick = tick()

		while LoopConnection do
			local dt = tick() - lastTick
			lastTick = tick()
			task.wait()

			local Character = Player.Character

			pcall(function()
				if not Character:FindFirstChildOfClass("Tool") then
					Character:PivotTo(KnifeSpawn.CFrame * CFrame.new(0, -2, 0))
					angle = 0
					return
				end

				for _, v in Players:GetPlayers() do
					if v == Player then continue end
					if not v.Character then continue end

					local targetRoot = v.Character:FindFirstChild("HumanoidRootPart")
					local targetHumanoid = v.Character:FindFirstChild("Humanoid")
					if not targetRoot or not targetHumanoid then continue end

					if (targetRoot.Position - KnifeSpawn.Position).Magnitude <= ATTACK_RANGE then
						repeat
							local dt2 = task.wait()
							angle = angle + ORBIT_SPEED * dt2

							local offsetX = math.cos(angle) * ORBIT_RADIUS
							local offsetZ = math.sin(angle) * ORBIT_RADIUS
							local orbitPos = targetRoot.Position + Vector3.new(offsetX, 0, offsetZ)

							local lookCF = CFrame.lookAt(orbitPos, targetRoot.Position)
							Character:PivotTo(lookCF)

							pcall(function()
								Character:FindFirstChildOfClass("Tool"):Activate()
							end)
							ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("KnifeAttack"):FireServer()
						until not targetHumanoid or targetHumanoid.Health <= RETREAT_THRESHOLD
							or not Character:FindFirstChildOfClass("Tool")
					end
				end
			end)
		end
	end)

	Conn = KnifeSpawn:GetPropertyChangedSignal("Parent"):Connect(function()
		if KnifeSpawn.Parent == nil then
			Conn:Disconnect()
			LoopConnection = false
		end
	end)
end

workspace.DescendantAdded:Connect(function(i)
	if i.Name == "KnifeSpawn" then
		LoopConnection = true
		createLoop(i)
	end
end)

task.spawn(function()
	while task.wait(5) do
		if #game.Players:GetPlayers() < 3 then
			local servers = {}
			local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true")
			local body = HttpService:JSONDecode(req)

			if body and body.data then
				for i, v in next, body.data do
					if type(v) == "table" and tonumber(v.playing) and tonumber(v.maxPlayers) and v.playing < v.maxPlayers and v.id ~= JobId then
						table.insert(servers, 1, v.id)
					end
				end
			end

			if #servers > 0 then
				TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], Players.LocalPlayer)
			end
		end
	end
end)

local TeleportCheck = false
Players.LocalPlayer.OnTeleport:Connect(function(State)
	if (not TeleportCheck) and queueteleport then
		TeleportCheck = true
		queueteleport("loadstring(game:HttpGet(('https://raw.githubusercontent.com/imiee/lua/refs/heads/main/kod.lua')()")
	end
end)
