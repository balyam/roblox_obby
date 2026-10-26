local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Checkpoints = require(script.Parent:WaitForChild("Checkpoints"))

-- Персонажи, которых только что вернули (чтобы не телепортировать 10 раз подряд)
local justSentBack = {}

local function sendBackToCheckpoint(player, character)
	if justSentBack[character] then
		return
	end
	justSentBack[character] = true

	-- Ставим персонажа над его последним чекпоинтом и гасим скорость
	character:PivotTo(Checkpoints.getSpawnCFrame(player))
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end

	task.delay(0.5, function()
		justSentBack[character] = nil
	end)
end

-- Делаем деталь лавой: при касании игрока — назад на чекпоинт
local function setupLava(part)
	part.Touched:Connect(function(hit)
		-- hit — часть тела (нога, рука...), ее родитель — персонаж
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			sendBackToCheckpoint(player, character)
		end
	end)
end

-- Все детали с тегом "Lava", которые уже есть в игре
for _, part in CollectionService:GetTagged("Lava") do
	setupLava(part)
end
-- И те, которые появятся позже
CollectionService:GetInstanceAddedSignal("Lava"):Connect(setupLava)
