--// ▼ Service References
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// ▼ Main HUD Manager Table
local HUDManager = {}
HUDManager.__index = HUDManager

--// Active HUDs for each player
HUDManager.ActiveHUDs = {}

--// ▼ Create HUD object using metatable
function HUDManager.new(player)
	local self = setmetatable({}, HUDManager)

	-- Store HUD data
	self.Player = player
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.HumanoidRootPart = self.Character:WaitForChild("HumanoidRootPart")

	-- Create Billboard GUI
	self.Gui = Instance.new("BillboardGui")
	self.Gui.Name = "NameTagHUD"
	self.Gui.Adornee = self.HumanoidRootPart
	self.Gui.Size = UDim2.new(5, 0, 2, 0)
	self.Gui.StudsOffset = Vector3.new(0, 4, 0)
	self.Gui.AlwaysOnTop = true
	self.Gui.LightInfluence = 0
	self.Gui.Enabled = false -- will fade in later via Tween

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = (player == LocalPlayer) and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = self.Gui

	-- DisplayName label
	local displayLabel = Instance.new("TextLabel")
	displayLabel.Size = UDim2.new(1, 0, 0.6, 0)
	displayLabel.Position = UDim2.new(0, 0, 0, 0)
	displayLabel.BackgroundTransparency = 1
	displayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayLabel.TextStrokeTransparency = 0.7
	displayLabel.Font = Enum.Font.SourceSansBold
	displayLabel.TextScaled = true
	displayLabel.Text = player.DisplayName
	displayLabel.Parent = frame

	-- Username label (@Username)
	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	usernameLabel.Position = UDim2.new(0, 0, 0.6, 0)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	usernameLabel.Font = Enum.Font.SourceSans
	usernameLabel.TextScaled = true
	usernameLabel.Text = "@" .. player.Name
	usernameLabel.Parent = frame

	-- Prepare transparency for Tween
	frame.BackgroundTransparency = 1
	displayLabel.TextTransparency = 1
	usernameLabel.TextTransparency = 1

	self.Gui.Parent = PlayerGui

	self.Frame = frame
	self.DisplayLabel = displayLabel
	self.UsernameLabel = usernameLabel

	-- Run fade-in animation
	self:FadeIn()

	-- Register HUD as active
	HUDManager.ActiveHUDs[player] = self

	return self
end

--// ▼ Fade-in animation
function HUDManager:FadeIn()
	self.Gui.Enabled = true
	local t1 = TweenService:Create(self.Frame, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.5})
	local t2 = TweenService:Create(self.DisplayLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0})
	local t3 = TweenService:Create(self.UsernameLabel, TweenInfo.new(1, Enum.EasingStyle.Quad), {TextTransparency = 0})
	t1:Play()
	t2:Play()
	t3:Play()
end

--// ▼ Fade-out animation
function HUDManager:FadeOut(callback)
	local t1 = TweenService:Create(self.Frame, TweenInfo.new(0.6), {BackgroundTransparency = 1})
	local t2 = TweenService:Create(self.DisplayLabel, TweenInfo.new(0.6), {TextTransparency = 1})
	local t3 = TweenService:Create(self.UsernameLabel, TweenInfo.new(0.6), {TextTransparency = 1})
	t1:Play()
	t2:Play()
	t3:Play()
	task.delay(0.6, function()
		self.Gui.Enabled = false
		if callback then callback() end
	end)
end

--// ▼ Destroy HUD
function HUDManager:Destroy()
	self:FadeOut(function()
		self.Gui:Destroy()
		HUDManager.ActiveHUDs[self.Player] = nil
	end)
end

--// ▼ Add HUD for each player
local function CreateHUDFor(player)
	if HUDManager.ActiveHUDs[player] then return end
	HUDManager.new(player)
end

--// ▼ Remove HUD when player leaves
local function RemoveHUDFor(player)
	local hud = HUDManager.ActiveHUDs[player]
	if hud then
		hud:Destroy()
	end
end

--// ▼ Keep HUD facing the camera
RunService.RenderStepped:Connect(function()
	for player, hud in pairs(HUDManager.ActiveHUDs) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local root = player.Character.HumanoidRootPart
			local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 4, 0))
			hud.Gui.Enabled = onScreen
			if onScreen then
				hud.Gui.StudsOffset = Vector3.new(0, 4, 0)
			end
		end
	end
end)

--// ▼ Initialize HUDs for existing players
for _, player in ipairs(Players:GetPlayers()) do
	CreateHUDFor(player)
end

--// ▼ Handle player join/leave events
Players.PlayerAdded:Connect(CreateHUDFor)
Players.PlayerRemoving:Connect(RemoveHUDFor)

--// ▼ Demo: Change DisplayName periodically
task.spawn(function()
	while task.wait(10) do
		for _, hud in pairs(HUDManager.ActiveHUDs) do
			local p = hud.Player
			hud.DisplayLabel.Text = p.DisplayName .. " ✨"
			local t = TweenService:Create(hud.DisplayLabel, TweenInfo.new(0.5), {TextTransparency = 0.2})
			t:Play()
		end
	end
end)

print("✅ Dynamic NameTag HUD System Loaded Successfully")

