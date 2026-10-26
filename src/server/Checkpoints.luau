-- Чекпоинты: запоминаем, до какого этапа дошел игрок, и возвращаем его туда
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Checkpoints = {}

-- Площадки по номеру этапа. Этап 0 — синий старт
local pads = {}
pads[0] = workspace:WaitForChild("Course"):WaitForChild("Start")

-- Таблица в правом верхнем углу экрана: папка leaderstats со значением Stage
local function onPlayerAdded(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- именно такое имя, иначе Roblox ее не покажет
	leaderstats.Parent = player

	local stage = Instance.new("IntValue")
	stage.Name = "Этап"
	stage.Value = 0
	stage.Parent = leaderstats
end

local function getStageValue(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Этап")
end

-- Наступил на площадку этапа — запоминаем, если это дальше, чем он уже был
local function setupPad(pad)
	local padStage = pad:GetAttribute("Stage")
	pads[padStage] = pad

	pad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local stageValue = player and getStageValue(player)
		if stageValue and padStage > stageValue.Value then
			stageValue.Value = padStage
		end
	end)
end

-- Где должен появиться игрок: над площадкой его последнего этапа
function Checkpoints.getSpawnCFrame(player)
	local stageValue = getStageValue(player)
	local pad = stageValue and pads[stageValue.Value] or pads[0]
	return pad.CFrame + Vector3.new(0, 4, 0)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

for _, pad in CollectionService:GetTagged("Checkpoint") do
	setupPad(pad)
end
CollectionService:GetInstanceAddedSignal("Checkpoint"):Connect(setupPad)

return Checkpoints
