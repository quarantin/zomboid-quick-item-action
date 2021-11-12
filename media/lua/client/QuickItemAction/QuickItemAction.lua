
local origDoContextualDblClick = ISInventoryPane.doContextualDblClick;

function ISInventoryPane:doContextualDblClick(item)

	-- Books
	if item:getCategory() == 'Literature' then
		ISInventoryPaneContextMenu.readItem(item, 0)
	end

	-- Cigarettes
	if item:getName() == 'Cigarettes' then
		ISInventoryPaneContextMenu.eatItem(item, 1, 0)
	end

	-- Maps
	if luautils.stringEnds(item:getType(), 'Map') then
		ISInventoryPaneContextMenu.onCheckMap(item, 0)
	end

	-- Pills
	if instanceof(item, 'Drainable') and luautils.stringStarts(item:getType(), 'Pills') then
		ISInventoryPaneContextMenu.takePill(item, 0)
	end

	-- Umbrellas
	if item:getName() == 'Umbrella' then
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, 0)
	end

	-- Keys
	if item:getCategory() == 'Key' then
		local player = getPlayer()
		local containers = player:getInventory():getItemsFromCategory('Container')
		for i = 0, containers:size() - 1 do
			local container = containers:get(i)
			if player:isEquipped(container) or container:getType() == 'KeyRing' then
				container:getInventory():addItem(item)
				break
			end
		end
	end

	return origDoContextualDblClick(self, item);
end
