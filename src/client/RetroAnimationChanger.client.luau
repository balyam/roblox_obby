local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Функция, которая меняет анимацию при появлении персонажа
local function onCharacterAdded(character)
	-- Ждем, пока загрузится стандартный скрипт анимации Roblox
	local animateScript = character:WaitForChild("Animate")

	-- Находим ID ходьбы (walk) и меняем его на свою анимацию
	animateScript.walk.WalkAnim.AnimationId = "rbxassetid://119403761018758"
end

-- Запуск функции при входе и каждом возрождении
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)
