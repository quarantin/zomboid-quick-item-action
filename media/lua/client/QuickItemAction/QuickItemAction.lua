local pillsTypes = {
	Antibiotics          = true,
	Pills                = true,
	PillsAntiDep         = true,
	PillsBeta            = true,
	PillsSleepingTablets = true,
	PillsVitamins        = true,
}

local function toBeHandled(itemName, itemCategory, itemDisplayCategory, itemType)

	if itemCategory == 'Normal' then
		return itemDisplayCategory == 'Ammo' or
			luautils.stringStarts(itemType, 'Nails') or
			luautils.stringStarts(itemType, 'Paperclip') or
			luautils.stringStarts(itemType, 'Screws') or
			luautils.stringEnds(itemType, 'Seed') or
			luautils.stringEnds(itemType, 'Seeds')
	end
end

local origDoContextualDblClick = ISInventoryPane.doContextualDblClick;

function ISInventoryPane:doContextualDblClick(item)

	local player = getPlayer()
	local inventory = player:getInventory()
	local scriptItem = item:getScriptItem()

	local itemName = item:getName()
	local itemType = item:getType()
	local itemEatType = item:getEatType()
	local itemCategory = scriptItem:getTypeString()
	local itemDisplayCategory = scriptItem:getDisplayCategory()

	if isDebugEnabled() then
		print('DEBUG: Name:', itemName)
		print('DEBUG: Type:', itemType)
		print('DEBUG: EatType:', itemEatType)
		print('DEBUG: Category:', itemCategory)
		print('DEBUG: DisplayCategory:', itemDisplayCategory)
	end

	-- Books
	if itemCategory == 'Literature' then
		ISInventoryPaneContextMenu.readItem(item, 0)

	-- Cigarettes
	elseif itemEatType == 'Cigarettes' then
		ISInventoryPaneContextMenu.eatItem(item, 1, 0)

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

	-- Maps
	elseif itemCategory == 'Map' or itemDisplayCategory == 'Cartography' then
		ISInventoryPaneContextMenu.onCheckMap(item, 0)

	-- Pills
	elseif itemDisplayCategory == 'FirstAid' and pillsTypes[itemType] ~= nil then
		ISInventoryPaneContextMenu.takePill(item, 0)

	-- Apply Recipes
	elseif toBeHandled(itemName, itemCategory, itemDisplayCategory, itemType) then

		local containers = ISInventoryPaneContextMenu.getContainers(player)

		local recipes = RecipeManager.getUniqueRecipeItems(item, player, containers)
		if recipes and recipes:size() > 0 then

			local recipe = recipes:get(0)
			local howMany = RecipeManager.getNumberOfTimesRecipeCanBeDone(recipe, player, containers, item)
			if howMany < 1 then
				return
			end

			local action = ISCraftAction:new(player, item, recipe:getTimeToMake(), recipe, inventory, containers)
			ISTimedActionQueue.add(action)
		end

	-- Umbrellas
	elseif itemName == 'Umbrella' then
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, 0)
	end

	return origDoContextualDblClick(self, item);
end
