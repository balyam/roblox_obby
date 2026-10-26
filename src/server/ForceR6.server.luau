local Players = game:GetService("Players")

-- Сами решаем, когда и какого персонажа создавать (обычный автоспавн выключен)
Players.CharacterAutoLoads = false

local Checkpoints = require(script.Parent:WaitForChild("Checkpoints"))

-- Внешность игрока: его одежда, цвета, аксессуары
local function getDescription(player)
	local ok, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	end)
	if ok then
		-- Убираем "фигурные" части тела из аватара: тогда тело будет
		-- классическим кубическим, а одежда, волосы и шапки останутся
		description.Head = 0
		description.Torso = 0
		description.LeftArm = 0
		description.RightArm = 0
		description.LeftLeg = 0
		description.RightLeg = 0
		return description
	end
	-- Не получилось загрузить (например, нет интернета) — обычный персонаж
	return Instance.new("HumanoidDescription")
end

local function spawnR6(player)
	if not player.Parent then
		return -- игрок уже вышел
	end

	-- Создаем персонажа R6 с внешностью игрока
	local character = Players:CreateHumanoidModelFromDescription(getDescription(player), Enum.HumanoidRigType.R6)
	character.Name = player.Name
	character:PivotTo(Checkpoints.getSpawnCFrame(player)) -- на последний чекпоинт

	local oldCharacter = player.Character
	player.Character = character
	character.Parent = workspace
	if oldCharacter then
		oldCharacter:Destroy()
	end

	-- Когда персонаж упадет — через пару секунд создаем нового
	character:WaitForChild("Humanoid").Died:Connect(function()
		task.wait(Players.RespawnTime)
		spawnR6(player)
	end)
end

Players.PlayerAdded:Connect(spawnR6)
-- Игроки, которые зашли раньше, чем запустился этот скрипт
for _, player in Players:GetPlayers() do
	spawnR6(player)
end
