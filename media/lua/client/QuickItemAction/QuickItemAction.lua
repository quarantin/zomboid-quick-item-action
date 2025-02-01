local pillsTypes = {
	Antibiotics          = true,
	Pills                = true,
	PillsAntiDep         = true,
	PillsBeta            = true,
	PillsSleepingTablets = true,
	PillsVitamins        = true,
}

local liquidCansTypes = {
	BeerBottle           = true,
	BeerCan              = true,
	Pop                  = true,
	Pop2                 = true,
	Pop3                 = true,
	PopBottle            = true,
	SodaCan              = true,
	TestCanPopCommon     = true,
	Wine                 = true,
}

local handledRecipesTypes = {
	AdhesiveBandageBox   = true,
	AdhesiveTapeBox      = true,
	AntibioticsBox       = true,
	BandageBox           = true,
	BatteryBox           = true,
	BeerCanPack          = true,
	BeerPack             = true,
	BoxOfJars            = true,
	CandleBox            = true,
	CigarettePack        = true,
	ColdpackBox          = true,
	CottonBallsBox       = true,
	DuctTapeBox          = true,
	Garbagebag_box       = true,
	FishingHookBox       = true,
	LightBulbBox         = true,
	SutureNeedleBox      = true,
	TissueBox            = true,
	TongueDepressorBox   = true,
	WineRed_Boxed        = true,
	WineWhite_Boxed      = true,
}

local function shouldHandleRecipe(itemName, itemCategory, itemDisplayCategory, itemType)

	if itemCategory == 'Normal' then
		return handledRecipesTypes[itemType]
			or itemDisplayCategory == 'Ammo'
			or luautils.stringStarts(itemType, 'Nails')
			or luautils.stringStarts(itemType, 'Paperclip')
			or luautils.stringStarts(itemType, 'Screws')
			or luautils.stringEnds(itemType, 'Seed')
			or luautils.stringEnds(itemType, 'Seeds')
			or luautils.stringEnds(itemType, '_Box')
			or (liquidCansTypes[itemType] and string.find(itemName, '(Sealed)'))

	elseif itemCategory == 'Drainable' then
		return handledRecipesTypes[itemType]

	elseif itemCategory == 'Literature' and itemDisplayCategory == 'Gardening' then
		return luautils.stringEnds(itemType, 'BagSeed') or luautils.stringEnds(itemType, 'BagSeed2')

	elseif itemCategory == 'Food' and itemDisplayCategory == 'Food' then
		return itemType == 'HotdogPack'
			or itemType == 'BunsHamburger'
			or (luautils.stringStarts(itemName, 'Canned') and not luautils.stringEnds(itemType, 'Open'))
	end
end

local function useRecipe(player, playerNum, recipe, item, inventory, containers)

	if getCore():getGameVersion():getMajor() < 42 then

		local howMany = RecipeManager.getNumberOfTimesRecipeCanBeDone(recipe, player, containers, item)
		if howMany > 0 then
			local action = ISCraftAction:new(player, item, recipe:getTimeToMake(), recipe, inventory, containers)
			ISTimedActionQueue.add(action)
		end
	else
		ISInventoryPaneContextMenu.OnNewCraft(item, recipe, playerNum, false)

	end
end

local function getRecipes(item, player, containers)

	if getCore():getGameVersion():getMajor() < 42 then
		return RecipeManager.getUniqueRecipeItems(item, player, containers)
	else
		return CraftRecipeManager.getUniqueRecipeItems(item, player, containers)
	end
end

local function findRecipeByName(recipeName, recipes)
	for i = 0, recipes:size() - 1 do
		local recipe = recipes:get(i)
		if recipe:getName() == recipeName then
			return recipe
		end
	end
end

local function selectRecipe(itemType, recipes)

	local recipe

	-- The first recipe is either `SmashBottle` or `PackBeerBottles`
	if itemType == 'BeerBottle' then
		recipe = findRecipeByName('OpenBottleOfBeer', recipes)

	-- The first recipe may be `AddACigarette`
	elseif itemType == 'CigarettePack' then
		recipe = findRecipeByName('TakeACigarette', recipes)

	-- The first recipe may be `Read`
	elseif luautils.stringEnds(itemType, 'BagSeed') or luautils.stringEnds(itemType, 'BagSeed2') then
		recipe = findRecipeByName('OpenPacketOfSeeds', recipes)
	end

	if recipe then
		return recipe
	end

	return recipes:get(0)
end


local origDoContextualDblClick = ISInventoryPane.doContextualDblClick;

function ISInventoryPane:doContextualDblClick(item)

	local player = getPlayer()
	local playerNum = player:getPlayerNum()
	local inventory = player:getInventory()
	local scriptItem = item:getScriptItem()

	local itemName = item:getName()
	local itemType = item:getType()
	local itemEatType = item:getEatType()
	local itemCategory = scriptItem:getTypeString()
	local itemDisplayCategory = scriptItem:getDisplayCategory()

	if isDebugEnabled() then
		print('-----------------------')
		print('DEBUG: Version:', getCore():getGameVersion())
		print('DEBUG: Name:', itemName)
		print('DEBUG: Type:', itemType)
		print('DEBUG: EatType:', itemEatType)
		print('DEBUG: Category:', itemCategory)
		print('DEBUG: DisplayCategory:', itemDisplayCategory)
		print('-----------------------')
	end

	-- Books
	if itemCategory == 'Literature' and itemDisplayCategory ~= 'Gardening' then
		ISInventoryPaneContextMenu.readItem(item, playerNum)

	-- Cigarettes
	elseif itemEatType == 'Cigarettes' then
		ISInventoryPaneContextMenu.eatItem(item, 1, playerNum)

	-- Keys
	elseif itemCategory == 'Key' then

		local containers = inventory:getItemsFromCategory('Container')
		for i = 0, containers:size() - 1 do
			local container = containers:get(i)
			if player:isEquipped(container) or container:getType() == 'KeyRing' then
				container:getInventory():addItem(item)
				break
			end
		end

	-- Liquids
	elseif liquidCansTypes[itemType] and not string.find(itemName, '(Sealed)') and not string.find(itemName, 'Empty') then
		ISInventoryPaneContextMenu.onDrinkFluid(item, 1, player)

	-- Maps
	elseif itemCategory == 'Map' or itemDisplayCategory == 'Cartography' then
		ISInventoryPaneContextMenu.onCheckMap(item, playerNum)

	-- Pills
	elseif itemDisplayCategory == 'FirstAid' and pillsTypes[itemType] ~= nil then
		ISInventoryPaneContextMenu.takePill(item, playerNum)

	-- Umbrellas
	elseif itemName == 'Umbrella' then
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, playerNum)

	-- Use Recipes
	elseif shouldHandleRecipe(itemName, itemCategory, itemDisplayCategory, itemType) then

		local containers = ISInventoryPaneContextMenu.getContainers(player)
		local recipes = getRecipes(item, player, containers)

		if recipes and recipes:size() > 0 then
			local recipe = selectRecipe(itemType, recipes)
			useRecipe(player, playerNum, recipe, item, inventory, containers)
		end
	end

	return origDoContextualDblClick(self, item);
end
