local _G = _G or getfenv(0)

local FullSack = CreateFrame("Frame", "FullSackFrame", UIParent)
FullSack:RegisterEvent("BAG_UPDATE")
FullSack:RegisterEvent("BANKFRAME_OPENED")
FullSack:RegisterEvent("BANKFRAME_CLOSED")
FullSack:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
FullSack:RegisterEvent("UNIT_INVENTORY_CHANGED")
FullSack:RegisterEvent("PLAYER_LOGOUT")
FullSack:RegisterEvent("MAIL_CLOSED")
FullSack:RegisterEvent("MAIL_SHOW")
FullSack:RegisterEvent("PLAYER_MONEY")
FullSack:RegisterEvent("PLAYER_LOGIN")

local character = UnitName("player")
local _, class = UnitClass("player")
local realm = GetRealmName()
character = character..";"..class..";"..realm

local classColors = {}
classColors["WARRIOR"] = "|cffc79c6e"
classColors["DRUID"]   = "|cffff7d0a"
classColors["PALADIN"] = "|cfff58cba"
classColors["WARLOCK"] = "|cff9482c9"
classColors["MAGE"]    = "|cff69ccf0"
classColors["PRIEST"]  = "|cffffffff"
classColors["ROGUE"]   = "|cfffff569"
classColors["HUNTER"]  = "|cffabd473"
classColors["SHAMAN"]  = "|cff0070de"

local GOLD = "|cffffd100"
local SILVER = "|cffb0b0b0"
local COPPER = "|cffc8602c"
local BLUE = "|cff0070de"
local WHITE = "|cffffffff"
local CLOSE = FONT_COLOR_CODE_CLOSE

local bankOpened = false
local superwow = SUPERWOW_VERSION and tonumber(SUPERWOW_VERSION) >= 1.3
local insideHook = false
local tooltipMoney = 0

local original_SetTooltipMoney = SetTooltipMoney

function SetTooltipMoney(frame, money)
	if not insideHook then
		return original_SetTooltipMoney(frame, money)
	else
		tooltipMoney = money or 0
	end
end

local function ExtendTooltip(tooltip)
	if tooltip:GetAnchorType() == "ANCHOR_CURSOR" or not tooltip.itemID or not FULLSACK_DATA then
		return
	end
	local id = tonumber(tooltip.itemID)
	if id then
		local totalCount = 0
		local separatorAdded = false
		local addedText = ""
		local lastLine = _G[tooltip:GetName().."TextLeft"..tooltip:NumLines()]
		if not lastLine then
			return
		end
		for char in pairs(FULLSACK_DATA) do
			local _, _, charName, charClass, charRealm = strfind(char, "(.+);(.+);(.+)")
			local color = classColors[charClass]
			if charRealm == realm then
				for pos in pairs(FULLSACK_DATA[char]) do
					local count = FULLSACK_DATA[char][pos][id]
					local posStr = pos
					posStr = color..pos..CLOSE
					if count then
						if not separatorAdded and not strfind(lastLine:GetText() or "", "^ ") then
							tooltip:AddLine(" ")
							lastLine = _G[tooltip:GetName().."TextLeft"..tooltip:NumLines()]
							separatorAdded = true
						end
						totalCount = totalCount + count
						addedText = addedText.."\n"..color..charName..WHITE.." (" .. posStr ..WHITE.. ")".." - "..count..CLOSE
					end
				end
			end
		end
		if totalCount > 0 then
			lastLine:SetText(lastLine:GetText()..addedText)
			lastLine:SetText(lastLine:GetText().."\n"..LIGHTYELLOW_FONT_COLOR_CODE.."Total - " .. totalCount..CLOSE)
		end
	end
	if tooltip == GameTooltip and tooltipMoney > 0 then
		original_SetTooltipMoney(tooltip, tooltipMoney)
	end
	tooltip:Show()
end

local IDcache = {}
local function GetItemIDByName(name)
	if not name then return nil end
	if IDcache[name] then
		return IDcache[name] ~= 0 and IDcache[name] or nil
	end
	for itemID = 1, 99999 do
		if GetItemInfo(itemID) == name then
			IDcache[name] = itemID
			return itemID
		end
	end
	IDcache[name] = 0
	return nil
end

local original_SetLootRollItem = GameTooltip.SetLootRollItem
local original_SetLootItem = GameTooltip.SetLootItem
local original_SetMerchantItem = GameTooltip.SetMerchantItem
local original_SetQuestLogItem = GameTooltip.SetQuestLogItem
local original_SetQuestItem = GameTooltip.SetQuestItem
local original_SetHyperlink = GameTooltip.SetHyperlink
local original_SetBagItem = GameTooltip.SetBagItem
local original_SetInboxItem = GameTooltip.SetInboxItem
local original_SetInventoryItem = GameTooltip.SetInventoryItem
local original_SetCraftItem = GameTooltip.SetCraftItem
local original_SetCraftSpell = GameTooltip.SetCraftSpell
local original_SetTradeSkillItem = GameTooltip.SetTradeSkillItem
local original_SetAuctionItem = GameTooltip.SetAuctionItem
local original_SetAuctionSellItem = GameTooltip.SetAuctionSellItem
local original_SetTradePlayerItem = GameTooltip.SetTradePlayerItem
local original_SetTradeTargetItem = GameTooltip.SetTradeTargetItem
local original_SetItemRef = SetItemRef

local function IDFromLink(link)
	if not link then return nil end
	local _, _, id = strfind(link, "item:(%d+)")
	return tonumber(id)
end

if superwow then
	local original_SetAction = GameTooltip.SetAction
	function GameTooltip.SetAction(self, actionID)
		local hasCooldown = original_SetAction(self, actionID)
		local text, actionType, id = GetActionText(actionID)
		if actionType == "ITEM" then
			GameTooltip.itemID = tonumber(id)
			ExtendTooltip(GameTooltip)
		end
		return hasCooldown
	end
end

function GameTooltip.SetLootRollItem(self, id)
	insideHook = true
	original_SetLootRollItem(self, id)
	GameTooltip.itemID = IDFromLink(GetLootRollItemLink(id))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetLootItem(self, slot)
	insideHook = true
	original_SetLootItem(self, slot)
	GameTooltip.itemID = IDFromLink(GetLootSlotLink(slot))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetMerchantItem(self, merchantIndex)
	insideHook = true
	original_SetMerchantItem(self, merchantIndex)
	GameTooltip.itemID = IDFromLink(GetMerchantItemLink(merchantIndex))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetQuestLogItem(self, itemType, index)
	insideHook = true
	original_SetQuestLogItem(self, itemType, index)
	GameTooltip.itemID = IDFromLink(GetQuestLogItemLink(itemType, index))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetQuestItem(self, itemType, index)
	insideHook = true
	original_SetQuestItem(self, itemType, index)
	GameTooltip.itemID = IDFromLink(GetQuestItemLink(itemType, index))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetHyperlink(self, arg1)
	insideHook = true
	original_SetHyperlink(self, arg1)
	GameTooltip.itemID = IDFromLink(arg1)
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetBagItem(self, container, slot)
	insideHook = true
	local hasCooldown, repairCost = original_SetBagItem(self, container, slot)
	GameTooltip.itemID = IDFromLink(GetContainerItemLink(container, slot))
	insideHook = false
	ExtendTooltip(GameTooltip)
	return hasCooldown, repairCost
end

function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
	insideHook = true
	original_SetInboxItem(self, mailID, attachmentIndex)
	GameTooltip.itemID = GetItemIDByName(GetInboxItem(mailID))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetInventoryItem(self, unit, slot)
	insideHook = true
	local hasItem, hasCooldown, repairCost = original_SetInventoryItem(self, unit, slot)
	GameTooltip.itemID = IDFromLink(GetInventoryItemLink(unit, slot))
	insideHook = false
	ExtendTooltip(GameTooltip)
	return hasItem, hasCooldown, repairCost
end

function GameTooltip.SetCraftItem(self, skill, slot)
	insideHook = true
	original_SetCraftItem(self, skill, slot)
	GameTooltip.itemID = IDFromLink(GetCraftReagentItemLink(skill, slot))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetCraftSpell(self, slot)
	insideHook = true
	original_SetCraftSpell(self, slot)
	GameTooltip.itemID = IDFromLink(GetCraftItemLink(slot))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
	insideHook = true
	original_SetTradeSkillItem(self, skillIndex, reagentIndex)
	if reagentIndex then
		GameTooltip.itemID = IDFromLink(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
	else
		GameTooltip.itemID = IDFromLink(GetTradeSkillItemLink(skillIndex))
	end
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetAuctionItem(self, atype, index)
	insideHook = true
	original_SetAuctionItem(self, atype, index)
	GameTooltip.itemID = IDFromLink(GetAuctionItemLink(atype, index))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetAuctionSellItem(self)
	insideHook = true
	original_SetAuctionSellItem(self)
	GameTooltip.itemID = GetItemIDByName(GetAuctionSellItemInfo())
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetTradePlayerItem(self, index)
	insideHook = true
	original_SetTradePlayerItem(self, index)
	GameTooltip.itemID = IDFromLink(GetTradePlayerItemLink(index))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function GameTooltip.SetTradeTargetItem(self, index)
	insideHook = true
	original_SetTradeTargetItem(self, index)
	GameTooltip.itemID = IDFromLink(GetTradeTargetItemLink(index))
	insideHook = false
	ExtendTooltip(GameTooltip)
end

function SetItemRef(link, text, button)
	ItemRefTooltip.itemID = IDFromLink(link)
	original_SetItemRef(link, text, button)
	if not IsShiftKeyDown() and not IsControlKeyDown() and ItemRefTooltip.itemID then
		ExtendTooltip(ItemRefTooltip)
	end
end

local function wipe(table)
	if type(table) ~= "table" then
		return
	end
	for k in pairs(table) do
		table[k] = nil
	end
end

local function UpdateBagsAndBank()
	local position = "bank"
	FULLSACK_DATA[character][position] = FULLSACK_DATA[character][position] or {}
	wipe(FULLSACK_DATA[character][position])
	for bag = -1, 10 do
		if bag == 0 then
			position = "bags"
			wipe(FULLSACK_DATA[character][position])
		end
		if bag == 5 then
			position = "bank"
		end
		local bagSize = GetContainerNumSlots(bag)
		if bagSize > 0 then
			for slot = 1, bagSize do
				local _, itemCount = GetContainerItemInfo(bag, slot)
				local id = IDFromLink(GetContainerItemLink(bag, slot))
				if itemCount and itemCount < 0 then
					itemCount = -itemCount
				end
				if id and itemCount and itemCount > 0 then
					local tmpCount = FULLSACK_DATA[character][position][id]
					if not tmpCount then
						FULLSACK_DATA[character][position][id] = itemCount
					else
						FULLSACK_DATA[character][position][id] = tmpCount + itemCount
					end
				end
			end
		end
	end
end

local delayedFunctions = {}

local function ScheduleFunctionLaunch(func, delay)
	if func and not delayedFunctions[func] then
		delay = delay or 0.75
		delayedFunctions[func] = GetTime() + delay
	else
		for f, t in pairs(delayedFunctions) do
			if GetTime() >= t then
				f()
				delayedFunctions[f] = nil
			end
		end
	end
end

local function UpdateMailbox()
	FULLSACK_DATA[character].mailbox = FULLSACK_DATA[character].mailbox or {}
	wipe(FULLSACK_DATA[character].mailbox)
	for i = 1, GetInboxNumItems() do
		local itemName, _, count = GetInboxItem(i)
		local id = GetItemIDByName(itemName)
		if id then
			local tmpCount = FULLSACK_DATA[character].mailbox[id]
			if not tmpCount then
				FULLSACK_DATA[character].mailbox[id] = count
			else
				FULLSACK_DATA[character].mailbox[id] = tmpCount + count
			end
		end
	end
end

local function UpdateGear()
	FULLSACK_DATA[character].equipped = FULLSACK_DATA[character].equipped or {}
	wipe(FULLSACK_DATA[character].equipped)
	for i = 1, 19 do
		local id = IDFromLink(GetInventoryItemLink("player", i))
		if id then
			local tmpCount = FULLSACK_DATA[character].equipped[id]
			if not tmpCount then
				FULLSACK_DATA[character].equipped[id] = 1
			else
				FULLSACK_DATA[character].equipped[id] = tmpCount + 1
			end
		end
	end
end

local function MoneyToStr(money)
	local gold = floor(money / (COPPER_PER_SILVER * SILVER_PER_GOLD))
	local silver = floor((money - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = mod(money, COPPER_PER_SILVER)
	if silver < 10 then
		silver = "0"..silver
	end
	if copper < 10 then
		copper = "0"..copper
	end
	gold = gold..GOLD.."g"..CLOSE
	silver = silver..SILVER.."s"..CLOSE
	copper = copper..COPPER.."c"..CLOSE
	if gold == "0"..GOLD.."g"..CLOSE then
		gold = ""
		if silver == "00"..SILVER.."s"..CLOSE then
			silver = ""
			if copper == "00"..COPPER.."c"..CLOSE then
				copper = "0"..COPPER.."c"..CLOSE
			end
		end
	end
	local str = gold.." "..silver.." "..copper
	return str
end

local function MoneyOnEnter()
	if not FULLSACK_DATA then
		return
	end
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -12, 0)
	GameTooltip:SetText("Money")
	local totalCount = 0
	for char, data in pairs(FULLSACK_DATA) do
		for pos in pairs(data) do
			if pos == "money" then
				local count = data[pos][1]
				totalCount = totalCount + count
				local _, _, charName, charClass = strfind(char, "(.+);(.+);")
				local color = classColors[charClass]
				if GameTooltip:NumLines() < 28 and count > 0 then
					GameTooltip:AddDoubleLine(color..charName..":", MoneyToStr(count), 0.65, 0.75, 0.85, 1, 1, 1)
				end
			end
		end
	end
	if totalCount > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine("Total:", MoneyToStr(totalCount), 1, 0.8, 0, 1, 1, 1)
	end
	GameTooltip:Show()
end

local function MoneyOnLeave()
	GameTooltip:Hide()
end

local moneyButtons = {}

local function HookMoneyButtons()
	for k, v in pairs(_G) do
		if type(v) == "table" and (strfind(k, "GoldButton$") or strfind(k, "SilverButton$") or strfind(k, "CopperButton$"))
				and not (strfind(k, "Tooltip") or strfind(k, "Quest") or strfind(k, "Popup")) then
			if not moneyButtons[k] then
				moneyButtons[k] = v
			end
		end
	end
	for k, button in pairs(moneyButtons) do
		button:SetScript("OnEnter", MoneyOnEnter)
		button:SetScript("OnLeave", MoneyOnLeave)
	end
end

local function OnEvent()
	if event == "PLAYER_LOGIN" then
		character = UnitName("player")
		_, class = UnitClass("player")
		realm = GetRealmName()
		character = character..";"..class..";"..realm
		FULLSACK_DATA = FULLSACK_DATA or {}
		if superwow then
			FULLSACK_DATA = assert(loadstring(ImportFile("FullSack") or ""))() or FULLSACK_DATA
		end
		FULLSACK_DATA[character] = FULLSACK_DATA[character] or {}
		FULLSACK_DATA[character].money = { GetMoney() }
		ScheduleFunctionLaunch(HookMoneyButtons, 2)

	elseif event == "PLAYER_LOGOUT" then
		if not superwow then
			return
		end
		local chunk = 'return {\n'
		for char in pairs(FULLSACK_DATA) do
			chunk = chunk..'["'..char..'"]={\n'
			for pos in pairs(FULLSACK_DATA[char]) do
				chunk = chunk..'\t["'..pos..'"]={'
				for id, count in pairs(FULLSACK_DATA[char][pos]) do
					if pos == "money" then
						chunk = chunk..count..','
					else
						chunk = chunk..'['..id..']='..count..','
					end
				end
				chunk = gsub(chunk, ',$', '')..'},\n'
			end
			chunk = chunk..'},\n'
		end
		chunk = chunk..'}'
		ExportFile("FullSack", chunk)

	elseif event == "BAG_UPDATE" then
		if bankOpened then
			UpdateBagsAndBank()
		else
			FULLSACK_DATA[character] = FULLSACK_DATA[character] or {}
			FULLSACK_DATA[character].bags = FULLSACK_DATA[character].bags or {}
			wipe(FULLSACK_DATA[character].bags)
			for bag = 0, 4 do
				local bagSize = GetContainerNumSlots(bag)
				if bagSize > 0 then
					for slot = 1, bagSize do
						local _, itemCount = GetContainerItemInfo(bag, slot)
						local id = IDFromLink(GetContainerItemLink(bag, slot))
						if itemCount and itemCount < 0 then
							itemCount = -itemCount
						end
						if id and itemCount and itemCount > 0 then
							local tmpCount = FULLSACK_DATA[character].bags[id]
							if not tmpCount then
								FULLSACK_DATA[character].bags[id] = itemCount
							else
								FULLSACK_DATA[character].bags[id] = tmpCount + itemCount
							end
						end
					end
				end
			end
		end

	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		UpdateGear()

	elseif event == "BANKFRAME_OPENED" then
		bankOpened = true
		UpdateBagsAndBank()

	elseif event == "BANKFRAME_CLOSED" then
		bankOpened = false

	elseif event == "PLAYERBANKSLOTS_CHANGED" then
		UpdateBagsAndBank()

	elseif event == "MAIL_CLOSED" or event == "MAIL_SHOW" then
		ScheduleFunctionLaunch(UpdateMailbox)

	elseif event == "PLAYER_MONEY" then
		FULLSACK_DATA = FULLSACK_DATA or {}
		FULLSACK_DATA[character] = FULLSACK_DATA[character] or {}
		FULLSACK_DATA[character].money = { GetMoney() }
	end
end

FullSack:SetScript("OnEvent", OnEvent)
FullSack:SetScript("OnUpdate", ScheduleFunctionLaunch)

local FullSackTooltip = CreateFrame("Frame", "FullSackTooltipFrame", GameTooltip)
FullSackTooltip:SetScript("OnShow", function()
	if not (aux_frame and aux_frame:IsShown()) then
		return
	end
	local focus = GetMouseFocus()
	if not focus then
		return
	end
	local parent = focus:GetParent()
	if not (parent and parent.row and parent.row.record) then
		return
	end
	GameTooltip.itemID = tonumber(parent.row.record.item_id)
	ExtendTooltip(GameTooltip)
end)

local original_OnHide = ItemRefTooltip:GetScript("OnHide")
ItemRefTooltip:SetScript("OnHide", function()
	original_OnHide()
	ItemRefTooltip.itemID = nil
end)

FullSackTooltip:SetScript("OnHide", function()
	GameTooltip.itemID = nil
	tooltipMoney = 0
end)

local HookAddonOrVariable = function(addon, func)
	local lurker = CreateFrame("Frame")
	lurker.func = func
	lurker:RegisterEvent("ADDON_LOADED")
	lurker:RegisterEvent("VARIABLES_LOADED")
	lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
	lurker:SetScript("OnEvent",function()
		if IsAddOnLoaded(addon) or _G[addon] then
			this:func()
			this:UnregisterAllEvents()
		end
	end)
end

HookAddonOrVariable("AtlasLoot", function()
	local atlas = CreateFrame("Frame", nil, AtlasLootTooltip)
	local atlas2 = CreateFrame("Frame", nil, AtlasLootTooltip2)
	atlas:SetScript("OnShow", function()
		local focus = GetMouseFocus()
		if not focus then return end
		if focus.dressingroomID and focus.dressingroomID ~= 0 and strsub(focus.itemID or "", 1, 1) ~= "s" and strsub(focus.itemID or "", 1, 1) ~= "e" then
			AtlasLootTooltip.itemID = tonumber(focus.dressingroomID)
			ExtendTooltip(AtlasLootTooltip)
		end
	end)
	atlas2:SetScript("OnShow", function()
		local focus = GetMouseFocus()
		if not focus then return end
		if focus.dressingroomID and focus.dressingroomID ~= 0 and strsub(focus.itemID or "", 1, 1) ~= "s" and strsub(focus.itemID or "", 1, 1) ~= "e" then
			AtlasLootTooltip2.itemID = tonumber(focus.dressingroomID)
			ExtendTooltip(AtlasLootTooltip2)
		end
	end)
	atlas:SetScript("OnHide", function()
		AtlasLootTooltip.itemID = nil
	end)
	atlas2:SetScript("OnHide", function()
		AtlasLootTooltip2.itemID = nil
	end)
end)

SLASH_FULLSACK1 = "/fullsack"
SlashCmdList["FULLSACK"] = function(msg)
	local cmd = string.gsub(msg or "", "^%s*(.-)%s*$", "%1")
	cmd = strupper(cmd)
	if cmd == "" then
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Version "..GetAddOnMetadata("FullSack", "Version"))
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Available commands:")
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."/fullsack delete <character name> - clears data for specified character (ex. /fullsack delete "..UnitName("player")..")")
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."/fullsack purge - clears all data")
	elseif cmd == "PURGE" then
		FULLSACK_DATA = {}
		FULLSACK_DATA[character] = {}
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Cleared data for all characters")
	elseif strfind(cmd, "DELETE") then
		local _, _, charToDelete = strfind(cmd, "DELETE (%w+)")
		if not charToDelete then
			DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Specify character (ex. /fullsack delete "..UnitName("player")..")")
			return
		end
		for k in pairs(FULLSACK_DATA) do
			local _, _, charRealm = strfind(k, "%w+;%w+;(%w+)")
			if charRealm == realm then
				if strfind(strupper(k), "^"..charToDelete..";") then
					FULLSACK_DATA[k] = nil
					DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Cleared data for "..charToDelete)
					return
				end
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."[FullSack] "..WHITE.."Couldn't find data for "..charToDelete)
	end
end