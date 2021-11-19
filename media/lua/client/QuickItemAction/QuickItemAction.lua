
local origDoContextualDblClick = ISInventoryPane.doContextualDblClick;

function ISInventoryPane:doContextualDblClick(item)

	local player = getPlayer()

	-- Books
	if item:getScriptItem():getTypeString() == 'Literature' then
		ISInventoryPaneContextMenu.readItem(item, 0)

	-- Cigarettes
	elseif item:getName() == 'Cigarettes' then
		ISInventoryPaneContextMenu.eatItem(item, 1, 0)

	-- Keys
	elseif item:getScriptItem():getTypeString() == 'Key' then
		local containers = player:getInventory():getItemsFromCategory('Container')
		for i = 0, containers:size() - 1 do
			local container = containers:get(i)
			if player:isEquipped(container) or container:getType() == 'KeyRing' then
				container:getInventory():addItem(item)
				break
			end
		end

	-- Maps
	elseif luautils.stringEnds(item:getType(), 'Map') then
		ISInventoryPaneContextMenu.onCheckMap(item, 0)

	-- Pills
	elseif instanceof(item, 'Drainable') and luautils.stringStarts(item:getType(), 'Pills') then
		ISInventoryPaneContextMenu.takePill(item, 0)

	-- Umbrellas
	elseif item:getName() == 'Umbrella' then
		ISInventoryPaneContextMenu.equipWeapon(item, false, false, 0)
	end

	return origDoContextualDblClick(self, item);
end
