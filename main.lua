-- Fov
local FOV_Circle = Drawing.new("Circle")
-- Fov setins
FOV_Circle.Color = Color3.fromRGB(255, 255, 255) -- White color
FOV_Circle.Transparency = 1 -- Fully visible
FOV_Circle.Radius = 45 -- Adjust size for FOV (45 degrees)
FOV_Circle.NumSides = 100 -- Smooth circle edges
FOV_Circle.Thickness = 1.5 -- Circle border thickness
FOV_Circle.Filled = false -- Ensure it's a circle outline
FOV_Circle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2,
	workspace.CurrentCamera.ViewportSize.Y / 2)


game:GetService("RunService").RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	FOV_Circle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	FOV_Circle.Visible = true -- Always ensure it's visible
end)


game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
	FOV_Circle:Remove()
end)
function getplrsname()
	for i,v in pairs(game:GetChildren()) do
		if v.ClassName == "Players" then
			return v.Name
		end
	end
end
local players = getplrsname()
local plr = game[players].LocalPlayer
coroutine.resume(coroutine.create(function()
	while  wait(1) do
		coroutine.resume(coroutine.create(function()
			for _,v in pairs(game[players]:GetPlayers()) do
				if v.Name ~= plr.Name and v.Character then
					v.Character.RightUpperLeg.CanCollide = false
					v.Character.RightUpperLeg.Transparency = 10
					v.Character.RightUpperLeg.Size = Vector3.new(13,13,13)

					v.Character.LeftUpperLeg.CanCollide = false
					v.Character.LeftUpperLeg.Transparency = 10
					v.Character.LeftUpperLeg.Size = Vector3.new(13,13,13)

					v.Character.HeadHB.CanCollide = false
					v.Character.HeadHB.Transparency = 10
					v.Character.HeadHB.Size = Vector3.new(13,13,13)

					v.Character.HumanoidRootPart.CanCollide = false
					v.Character.HumanoidRootPart.Transparency = 10
					v.Character.HumanoidRootPart.Size = Vector3.new(13,13,13)

				end
			end
		end))
	end
end))

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlaceId = game.PlaceId

local ASSIST_RADIUS = 1000
local ASSIST_STRENGTH = 1
local MAX_DISTANCE = 1000
local isAiming = false
local FOV_DEGREES = 22.5
local FOV_RADIUS = math.cos(math.rad(FOV_DEGREES / 2))

local BOX_COLOR = Color3.new(1, 0, 0)
local BOX_TRANSPARENCY = 0.45
local BOX_SIZE = UDim2.new(4, 0, 6, 0)
local REFRESH_INTERVAL = 0.4

local infiniteJumpEnabled = true

local Configuration = {
	TeamCheck = true,
}

local Configuration = {
	TeamCheck = true,
}

local LocalPlayer = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Create a ScreenGui to display the status
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = ScreenGui
StatusLabel.AnchorPoint = Vector2.new(0.5, 0) -- Centered horizontally
StatusLabel.Position = UDim2.new(0.5, 0, 0, 10) -- Top-center position
StatusLabel.Size = UDim2.new(0, 200, 0, 50)
StatusLabel.BackgroundTransparency = 1 -- Make background transparent
StatusLabel.TextColor3 = Color3.new(1, 1, 1) -- White text
StatusLabel.TextSize = 24
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.Text = "Team Check: ON"

local function UpdateStatusLabel()
	if Configuration.TeamCheck then
		StatusLabel.Text = "Team Check: ON"
	else
		StatusLabel.Text = "Team Check: OFF"
	end
end

-- Function to toggle TeamCheck
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore if the input is processed by the game

	if input.KeyCode == Enum.KeyCode.T then
		Configuration.TeamCheck = not Configuration.TeamCheck
		UpdateStatusLabel()
	end
end)

-- Function to check if a player is an enemy
local function IsEnemy(Player)
	if Configuration.TeamCheck then
		return Player.Team ~= LocalPlayer.Team
	end
	return true
end


local function joinDifferentServer()
	local success, serverList = pcall(function()
		return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
	end)

	if success and serverList then
		for _, server in pairs(serverList.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
				return
			end
		end
	else
		warn("Failed to retrieve server list.")
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		joinDifferentServer()
	end
end)

local function isWithinFOV(targetPosition)
	local directionToTarget = (targetPosition - Camera.CFrame.Position).unit
	local cameraDirection = Camera.CFrame.LookVector
	return directionToTarget:Dot(cameraDirection) >= FOV_RADIUS
end

local function getClosestPlayerToCursor()
	local closest = nil
	local shortestDistance = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and
			player.Character and
			player.Character:FindFirstChild("Head") and
			player.Character:FindFirstChild("Humanoid") and
			player.Character.Humanoid.Health > 0 and
			IsEnemy(player) then

			local distance = (player.Character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude
			if distance <= MAX_DISTANCE then
				if isWithinFOV(player.Character.Head.Position) then
					local screenPoint = Camera:WorldToScreenPoint(player.Character.Head.Position)
					if screenPoint.Z > 0 and distance < shortestDistance then
						closest = player
						shortestDistance = distance
					end
				end
			end
		end
	end

	return closest
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end
end)

RunService:BindToRenderStep("MaxAimAssist", Enum.RenderPriority.Camera.Value + 1, function()
	if not isAiming then return end

	if not LocalPlayer.Character or
		not LocalPlayer.Character:FindFirstChild("Humanoid") or
		LocalPlayer.Character.Humanoid.Health <= 0 then
		return
	end

	local target = getClosestPlayerToCursor()
	if target then
		local targetPos = target.Character.Head.Position
		Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPos)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
		infiniteJumpEnabled = not infiniteJumpEnabled
		print("Infinite Jump:", infiniteJumpEnabled)
	end
end)

local ScreenGui = Instance.new("ScreenGui")
local Indicator = Instance.new("TextLabel")

ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

Indicator.Size = UDim2.new(0, 200, 0, 25)
Indicator.Position = UDim2.new(0.5, -100, 0.9, 0)
Indicator.BackgroundTransparency = 1
Indicator.TextColor3 = Color3.new(1, 0, 0)
Indicator.Font = Enum.Font.GothamBold
Indicator.TextSize = 16
Indicator.Parent = ScreenGui

RunService.RenderStepped:Connect(function()
	Indicator.Text = isAiming and "MAX AIM ASSIST ACTIVE" or ""
end)

local function createOrRefreshTargetBox(player)
	if player ~= LocalPlayer and player.Character and IsEnemy(player) then
		local character = player.Character
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local existingBox = character:FindFirstChild("BillboardGui")
			if existingBox then
				existingBox:Destroy()
			end
			local billboard = Instance.new("BillboardGui")
			billboard.Adornee = rootPart
			billboard.Size = BOX_SIZE
			billboard.AlwaysOnTop = true
			billboard.LightInfluence = 0
			local boxFrame = Instance.new("Frame")
			boxFrame.Size = UDim2.new(1, 0, 1, 0)
			boxFrame.BackgroundTransparency = BOX_TRANSPARENCY
			boxFrame.BackgroundColor3 = BOX_COLOR
			boxFrame.BorderSizePixel = 0
			boxFrame.Parent = billboard
			billboard.Parent = character
		end
	end
end

local function refreshAllBoxes()
	for _, player in pairs(Players:GetPlayers()) do
		createOrRefreshTargetBox(player)
	end
end

refreshAllBoxes()

while true do
	wait(REFRESH_INTERVAL)
	refreshAllBoxes()
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		createOrRefreshTargetBox(player)
	end)
end)

while wait() do
	game:GetService("Players").LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount.Value = 999
	game:GetService("Players").LocalPlayer.PlayerGui.GUI.Client.Variables.ammocount2.Value = 999
end
