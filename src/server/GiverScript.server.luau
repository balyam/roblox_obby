local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ссылка на Boom в общей папке
-- Используем WaitForChild, так как объект может подгрузиться не сразу
local ItemsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")
local BoomTool = ItemsFolder:WaitForChild("Boom")

-- Функция, которая срабатывает при каждом спавне персонажа
local function onCharacterAdded(character, player)
	-- Проверяем, нет ли уже Boom в рюкзаке или в руках
	local backpack = player:WaitForChild("Backpack")
	if not backpack:FindFirstChild("Boom") and not character:FindFirstChild("Boom") then
		-- Клонируем Boom из ReplicatedStorage и кладем в рюкзак игрока
		local boomClone = BoomTool:Clone()
		boomClone.Parent = backpack
		print("Boom выдан игроку: " .. player.Name)
	end
end

local function onPlayerAdded(player)
	-- Ждем, пока персонаж игрока появится на карте (заспавнится)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(character, player)
	end)
	-- Персонаж мог появиться еще до того, как мы подписались
	if player.Character then
		onCharacterAdded(player.Character, player)
	end
end

-- Отслеживаем вход новых игроков на сервер
Players.PlayerAdded:Connect(onPlayerAdded)
-- И тех, кто успел зайти раньше, чем запустился этот скрипт
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
