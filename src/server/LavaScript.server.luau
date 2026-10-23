local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- Куда возвращаем игрока, если он наступил на лаву
local startPoint = workspace:WaitForChild("Course"):WaitForChild("Start")

-- Персонажи, которых только что вернули (чтобы не телепортировать 10 раз подряд)
local justSentBack = {}

local function sendBackToStart(character)
	if justSentBack[character] then
		return
	end
	justSentBack[character] = true

	-- Ставим персонажа чуть выше старта и гасим его скорость
	character:PivotTo(startPoint.CFrame + Vector3.new(0, 3, 0))
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end

	task.delay(0.5, function()
		justSentBack[character] = nil
	end)
end

-- Делаем деталь лавой: при касании игрока — назад на старт
local function setupLava(part)
	part.Touched:Connect(function(hit)
		-- hit — часть тела (нога, рука...), ее родитель — персонаж
		local character = hit.Parent
		if Players:GetPlayerFromCharacter(character) then
			sendBackToStart(character)
		end
	end)
end

-- Все детали с тегом "Lava", которые уже есть в игре
for _, part in CollectionService:GetTagged("Lava") do
	setupLava(part)
end
-- И те, которые появятся позже
CollectionService:GetInstanceAddedSignal("Lava"):Connect(setupLava)
