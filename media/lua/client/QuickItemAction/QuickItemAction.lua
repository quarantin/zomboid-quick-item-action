
local origDoContextualDblClick = ISInventoryPane.doContextualDblClick;

function ISInventoryPane:doContextualDblClick(item)

	local player = getPlayer()
	local inventory = player:getInventory()

	local itemName = item:getName()
	local itemType = item:getType()
	local itemCategory = item:getScriptItem():getTypeString()

	-- Books
	if itemCategory == 'Literature' then
		ISInventoryPaneContextMenu.readItem(item, 0)

	-- Cigarettes
	elseif itemName == 'Cigarettes' then
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
	elseif luautils.stringEnds(itemType, 'Map') then
		ISInventoryPaneContextMenu.onCheckMap(item, 0)

	-- Pills
	elseif instanceof(item, 'Drainable') and luautils.stringStarts(itemType, 'Pills') then
		ISInventoryPaneContextMenu.takePill(item, 0)

	-- Seed Packets
	elseif itemCategory == 'Normal' and (luautils.stringEnds(itemType, 'Seed') or luautils.stringEnds(itemType, 'Seeds')) then

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
