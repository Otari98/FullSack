local FullSack = CreateFrame("Frame", "FullSackFrame", UIParent)
FullSack:RegisterEvent("VARIABLES_LOADED")
FullSack:RegisterEvent("BAG_UPDATE")
FullSack:RegisterEvent("BANKFRAME_OPENED")
FullSack:RegisterEvent("BANKFRAME_CLOSED")
FullSack:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
FullSack:RegisterEvent("UNIT_INVENTORY_CHANGED")
FullSack:RegisterEvent("PLAYER_LOGOUT")
FullSack:RegisterEvent("MAIL_INBOX_UPDATE")
FullSack:RegisterEvent("PLAYER_MONEY")
FullSack:RegisterEvent("PLAYER_ENTERING_WORLD")

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
local SILVER = "|cffe6e6e6"
local COPPER = "|cffc8602c"
local BLUE = "|cff0070de"
local WHITE = "|cffffffff"
local CLOSE = FONT_COLOR_CODE_CLOSE

local bankOpened = false
local superwow = (SUPERWOW_VERSION and tonumber(SUPERWOW_VERSION) >= 1.3) or false

local function ExtendTooltip(tooltip)
    if tooltip:GetAnchorType() == "ANCHOR_CURSOR" or not tooltip.itemID or not FULLSACK_DATA then
        return
    end
    local id = tonumber(tooltip.itemID)
    if id then
        local totalCount = 0
        local separatorAdded = false
        local numLines = tooltip:NumLines()
        for char in pairs(FULLSACK_DATA) do
            local _, _, charName, charClass, charRealm = strfind(char, "(.+);(.+);(.+)")
            if charRealm ~= realm then
                -- continue
            else
                for pos in pairs(FULLSACK_DATA[char]) do
                    local count = FULLSACK_DATA[char][pos][id]
                    if count then
                        totalCount = totalCount + count
                    end
                end
            end
        end
        if numLines == 1 and totalCount > 0 then
            tooltip:AddLine(" ")
            numLines = numLines + 1
            separatorAdded = true
        end
        local lastLine = getglobal(tooltip:GetName().."TextLeft"..numLines)
        for char in pairs(FULLSACK_DATA) do
            local _, _, charName, charClass, charRealm = strfind(char, "(.+);(.+);(.+)")
            if charRealm ~= realm then
                -- continue
            else
                for pos in pairs(FULLSACK_DATA[char]) do
                    local count = FULLSACK_DATA[char][pos][id]
                    if count then
                        local color = classColors[charClass]
                        if not separatorAdded then
                            separatorAdded = true
                            lastLine:SetText(lastLine:GetText().."\n\n"..color..charName.." (" .. pos .. ")".." - "..count..CLOSE)
                        else
                            lastLine:SetText(lastLine:GetText().."\n"..color..charName.." (" .. pos .. ")".." - "..count..CLOSE)
                        end
                    end
                end
            end
        end
        if totalCount > 0 then
            lastLine:SetText(lastLine:GetText().."\n"..GOLD.."Total - " .. totalCount..CLOSE)
        end
    end
    tooltip:Show()
end

local lastSearchName
local lastSearchID
local function GetItemIDByName(name)
    if name ~= lastSearchName then
        for itemID = 1, 99999 do
            local itemName = GetItemInfo(itemID)
            if (itemName and itemName == name) then
                lastSearchID = itemID
                break
            end
        end
        lastSearchName = name
    end
    return lastSearchID
end

local original_SetLootRollItem      = GameTooltip.SetLootRollItem
local original_SetLootItem          = GameTooltip.SetLootItem
local original_SetMerchantItem      = GameTooltip.SetMerchantItem
local original_SetQuestLogItem      = GameTooltip.SetQuestLogItem
local original_SetQuestItem         = GameTooltip.SetQuestItem
local original_SetHyperlink         = GameTooltip.SetHyperlink
local original_SetBagItem           = GameTooltip.SetBagItem
local original_SetInboxItem         = GameTooltip.SetInboxItem
local original_SetInventoryItem     = GameTooltip.SetInventoryItem
local original_SetCraftItem         = GameTooltip.SetCraftItem
local original_SetCraftSpell        = GameTooltip.SetCraftSpell
local original_SetTradeSkillItem    = GameTooltip.SetTradeSkillItem
local original_SetAuctionItem       = GameTooltip.SetAuctionItem
local original_SetAuctionSellItem   = GameTooltip.SetAuctionSellItem
local original_SetTradePlayerItem   = GameTooltip.SetTradePlayerItem
local original_SetTradeTargetItem   = GameTooltip.SetTradeTargetItem
local original_SetItemRef           = SetItemRef

function GameTooltip.SetLootRollItem(self, id)
    local _, _, itemID = string.find(GetLootRollItemLink(id) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return original_SetLootRollItem(self, id)
end

function GameTooltip.SetLootItem(self, slot)
    local _, _, itemID = string.find(GetLootSlotLink(slot) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    original_SetLootItem(self, slot)
end

function GameTooltip.SetMerchantItem(self, merchantIndex)
    local _, _, itemID = string.find(GetMerchantItemLink(merchantIndex) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return original_SetMerchantItem(self, merchantIndex)
end

function GameTooltip.SetQuestLogItem(self, itemType, index)
    local _, _, itemID = string.find(GetQuestLogItemLink(itemType, index) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    if not GameTooltip.itemID then
        return
    end
    return original_SetQuestLogItem(self, itemType, index)
end

function GameTooltip.SetQuestItem(self, itemType, index)
    local _, _, itemID = string.find(GetQuestItemLink(itemType, index) or "", "item:(%d+)")
    GameTooltip.itemID = itemID
    return original_SetQuestItem(self, itemType, index)
end

function GameTooltip.SetHyperlink(self, arg1)
    if arg1 then
        local _, _, id = string.find(arg1, "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetHyperlink(self, arg1)
end

function GameTooltip.SetBagItem(self, container, slot)
    if GetContainerItemLink(container, slot) then
        local _, _, id = string.find(GetContainerItemLink(container, slot) or "", "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetBagItem(self, container, slot)
end

function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
    local itemName = GetInboxItem(mailID)
    if itemName then
        GameTooltip.itemID = GetItemIDByName(itemName)
    end
    return original_SetInboxItem(self, mailID, attachmentIndex)
end

function GameTooltip.SetInventoryItem(self, unit, slot)
    if GetInventoryItemLink(unit, slot) then
        local _, _, id = string.find(GetInventoryItemLink(unit, slot) or "", "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetInventoryItem(self, unit, slot)
end

function GameTooltip.SetCraftItem(self, skill, slot)
    if GetCraftReagentItemLink(skill, slot) then
        local _, _, id = string.find(GetCraftReagentItemLink(skill, slot) or "", "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetCraftItem(self, skill, slot)
end

function GameTooltip.SetCraftSpell(self, slot)
    local _, _, id = string.find(GetCraftItemLink(slot) or "", "item:(%d+)")
    GameTooltip.itemID = id
    return original_SetCraftSpell(self, slot)
end

function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
    if reagentIndex then
        if GetTradeSkillReagentItemLink(skillIndex, reagentIndex) then
            local _, _, id = string.find(GetTradeSkillReagentItemLink(skillIndex, reagentIndex) or "", "item:(%d+)")
            GameTooltip.itemID = id
        end
    else
        if GetTradeSkillItemLink(skillIndex) then
            local _, _, id = string.find(GetTradeSkillItemLink(skillIndex) or "", "item:(%d+)")
            GameTooltip.itemID = id
        end
    end
    return original_SetTradeSkillItem(self, skillIndex, reagentIndex)
end

function GameTooltip.SetAuctionItem(self, atype, index)
    local itemName = GetAuctionItemInfo(atype, index)
    if itemName then
        GameTooltip.itemID = GetItemIDByName(itemName)
    end
    return original_SetAuctionItem(self, atype, index)
end

function GameTooltip.SetAuctionSellItem(self)
    local itemName = GetAuctionSellItemInfo()
    if itemName then
        GameTooltip.itemID = GetItemIDByName(itemName)
    end
    return original_SetAuctionSellItem(self)
end

function GameTooltip.SetTradePlayerItem(self, index)
    if GetTradePlayerItemLink(index) then
        local _, _, id = string.find(GetTradePlayerItemLink(index) or "", "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetTradePlayerItem(self, index)
end

function GameTooltip.SetTradeTargetItem(self, index)
    if GetTradeTargetItemLink(index) then
        local _, _, id = string.find(GetTradeTargetItemLink(index) or "", "item:(%d+)")
        GameTooltip.itemID = id
    end
    return original_SetTradeTargetItem(self, index)
end

function SetItemRef(link, text, button)
    local item, _, id = string.find(link, "item:(%d+)")
    ItemRefTooltip.itemID = id
    original_SetItemRef(link, text, button)
    if not IsShiftKeyDown() and not IsControlKeyDown() and item then
        ExtendTooltip(ItemRefTooltip)
    end
end

local function tblwipe(tbl)
    if not tbl or type(tbl) ~= "table" then
        return
    end
    for k in pairs(tbl) do
        tbl[k] = nil
    end
end

local function UpdateBagsAndBank()
    local position = "bank"
    if not FULLSACK_DATA[character][position] then
        FULLSACK_DATA[character][position] = {}
    end
    tblwipe(FULLSACK_DATA[character][position])
    for bag = -1, 10 do
        if (bag == 0) then
            position = "bags"
            tblwipe(FULLSACK_DATA[character][position])
        end
        if (bag == 5) then
            position = "bank"
        end
        local bagSize = GetContainerNumSlots(bag)
        if (bagSize > 0) then
            for slot = 1, bagSize do
                local _, itemCount = GetContainerItemInfo(bag, slot)
                local itemLink = GetContainerItemLink(bag, slot)
                local _, _, id = strfind(itemLink or "", "item:(%d+)")
                id = tonumber(id)
                if itemCount and itemCount < 0 then
                    itemCount = -itemCount
                end
                if (id and itemCount and itemCount > 0) then
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
    if not FULLSACK_DATA[character].mailbox then
        FULLSACK_DATA[character].mailbox = {}
    end
    tblwipe(FULLSACK_DATA[character].mailbox)
    for i = 1, GetInboxNumItems() do
        local itemName, _, count = GetInboxItem(i)
        local id = GetItemIDByName(itemName)
        id = tonumber(id)
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
    if not FULLSACK_DATA[character].equipped then
        FULLSACK_DATA[character].equipped = {}
    end
    tblwipe(FULLSACK_DATA[character].equipped)
    for i = 1, 19 do
        local link = GetInventoryItemLink("player", i)
        local _, _, id = strfind(link or "", "item:(%d+)")
        id = tonumber(id)
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
    local str = gold..GOLD.."g "..CLOSE..silver..SILVER.."s "..CLOSE..copper..COPPER.."c"..CLOSE
    return str
end

local function MoneyOnEnter()
    if FULLSACK_DATA then
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
                    if GameTooltip:NumLines() < 28 then
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
end

local function MoneyOnLeave()
    GameTooltip:Hide()
end

local moneyButtons = {}

local function HookMoneyButtons()
    for k, v in pairs(getfenv(0)) do
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
    if event == "VARIABLES_LOADED" then
        if not FULLSACK_DATA then
            FULLSACK_DATA = {}
        end
        if not FULLSACK_DATA[character] then
            FULLSACK_DATA[character] = {}
        end
        if superwow then
            FULLSACK_DATA = assert(loadstring(ImportFile("FullSack") or ""))() or FULLSACK_DATA
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if not FULLSACK_DATA then
            FULLSACK_DATA = {}
        end
        if not FULLSACK_DATA[character] then
            FULLSACK_DATA[character] = {}
        end
        FULLSACK_DATA[character].money = { GetMoney() }
        ScheduleFunctionLaunch(HookMoneyButtons, 2)

    elseif event == "PLAYER_LOGOUT" then
        if not superwow then
            return
        end
        local chunk = 'local tbl = {\n'
        for char in pairs(FULLSACK_DATA) do
            chunk = chunk..'    ["'..char..'"] = {\n'
            for pos in pairs(FULLSACK_DATA[char]) do
                chunk = chunk..'        ["'..pos..'"] = {\n'
                for id, count in pairs(FULLSACK_DATA[char][pos]) do
                    chunk = chunk..'            ['..id..'] = '..count..',\n'
                end
                chunk = chunk..'        },\n'
            end
            chunk = chunk..'    },\n'
        end
        chunk = chunk..'}\nreturn tbl'
        ExportFile("FullSack", chunk)

    elseif event == "BAG_UPDATE" then
        if bankOpened then
            UpdateBagsAndBank()
        else
            if not FULLSACK_DATA[character] then
                FULLSACK_DATA[character] = {}
            end
            if not FULLSACK_DATA[character].bags then
                FULLSACK_DATA[character].bags = {}
            end
            tblwipe(FULLSACK_DATA[character].bags)
            for bag = 0, 4 do
                local bagSize = GetContainerNumSlots(bag)
                if (bagSize > 0) then
                    for slot = 1, bagSize do
                        local _, itemCount = GetContainerItemInfo(bag, slot)
                        local itemLink = GetContainerItemLink(bag, slot)
                        local _, _, id = strfind(itemLink or "", "item:(%d+)")
                        id = tonumber(id)
                        if itemCount and itemCount < 0 then
                            itemCount = -itemCount
                        end
                        if (id and itemCount and itemCount > 0) then
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

    elseif event == "MAIL_INBOX_UPDATE" then
        ScheduleFunctionLaunch(UpdateMailbox)

    elseif event == "PLAYER_MONEY" then
        if not FULLSACK_DATA then
            FULLSACK_DATA = {}
        end
        if not FULLSACK_DATA[character] then
            FULLSACK_DATA[character] = {}
        end
        FULLSACK_DATA[character].money = { GetMoney() }
    end
end

FullSack:SetScript("OnEvent", OnEvent)
FullSack:SetScript("OnUpdate", function()
    ScheduleFunctionLaunch()
end)

local FullSackTooltip = CreateFrame("Frame", "FullSackTooltipFrame", GameTooltip)
FullSackTooltip:SetScript("OnShow", function()
    if aux_frame and aux_frame:IsVisible() then
        if GetMouseFocus():GetParent() then
            if GetMouseFocus():GetParent().row then
                if GetMouseFocus():GetParent().row.record.item_id then
                    GameTooltip.itemID = GetMouseFocus():GetParent().row.record.item_id
                end
            end
        end
    end
    ExtendTooltip(GameTooltip)
end)

ItemRefTooltip:SetScript("OnHide", function() ItemRefTooltip.itemID = nil end)
FullSackTooltip:SetScript("OnHide", function() GameTooltip.itemID = nil end)

local HookAddonOrVariable = function(addon, func)
    local lurker = CreateFrame("Frame")
    lurker.func = func
    lurker:RegisterEvent("ADDON_LOADED")
    lurker:RegisterEvent("VARIABLES_LOADED")
    lurker:RegisterEvent("PLAYER_ENTERING_WORLD")
    lurker:SetScript("OnEvent",function()
        if IsAddOnLoaded(addon) or getglobal(addon) then
            this:func()
            this:UnregisterAllEvents()
        end
    end)
end

HookAddonOrVariable("AtlasLoot", function()
    local atlas = CreateFrame("Frame", nil, AtlasLootTooltip)
    local atlas2 = CreateFrame("Frame", nil, AtlasLootTooltip2)
    atlas:SetScript("OnShow", function()
        if GetMouseFocus().dressingroomID and GetMouseFocus().dressingroomID ~= 0 and
                strsub(GetMouseFocus().itemID or "", 1, 1) ~= "s" and strsub(GetMouseFocus().itemID or "", 1, 1) ~= "e" then
            AtlasLootTooltip.itemID = GetMouseFocus().dressingroomID
        end
        ExtendTooltip(AtlasLootTooltip)
    end)
    atlas2:SetScript("OnShow", function()
        if GetMouseFocus().dressingroomID and GetMouseFocus().dressingroomID ~= 0 and
                strsub(GetMouseFocus().itemID or "", 1, 1) ~= "s" and strsub(GetMouseFocus().itemID or "", 1, 1) ~= "e" then
            AtlasLootTooltip2.itemID = GetMouseFocus().dressingroomID
        end
        ExtendTooltip(AtlasLootTooltip2)
    end)
    atlas:SetScript("OnHide", function() AtlasLootTooltip.itemID = nil end)
    atlas2:SetScript("OnHide", function() AtlasLootTooltip2.itemID = nil end)
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