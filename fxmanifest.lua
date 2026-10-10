fx_version 'cerulean'
game 'gta5'
lua54 'yes' -- Faster VM than the default Lua 5.3 runtime.
author 'dullpear'
version '1.0.4'
description 'dpClothing+'

client_scripts {
	'Client/Functions.lua', 		-- Global Functions / Events / Debug and Locale start.
	'Locale/*.lua', 				-- Locales.
	'Client/Config.lua',			-- Configuration.
	'Client/Variations.lua',		-- Variants, this is where you wanna change stuff around most likely.
	'Client/Clothing.lua',
	'Client/GUI.lua',				-- The GUI.
}
