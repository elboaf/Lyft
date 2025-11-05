-- Lyft - Floating bar for useful Turtle WoW items
-- Based on ConsumesManagerBar design

Lyft = {}

-- Configuration
local BAR_HEIGHT = 40
local ICON_SIZE = 32
local ICON_SPACING = 5

-- Tracked items data
local trackedItems = {
    ["Portable Wormhole Generator: Orgrimmar"] = {
        itemID = 51313,
        texture = "Interface\\Icons\\inv_gizmo_06",
        isEquippedItem = false
    },
    ["Verdant Rune"] = {
        itemID = 41915, 
        texture = "Interface\\Icons\\inv_misc_rune_02",
        isEquippedItem = false
    },
    ["Time-Worn Rune"] = {
        itemID = 61000,
        texture = "Interface\\Icons\\INV_Misc_Rune_08",
        isEquippedItem = false
    },
    ["Guild Tabard"] = {
        itemID = 5976,
        texture = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
        isEquippedItem = true,  -- Special case: this item must be equipped to use
        equipSlot = "ShirtSlot" -- Tabard slot
    },
    ["Dimensional Ripper - Everlook"] = {
        itemID = 18984,
        texture = "Interface\\Icons\\inv_misc_enggizmos_07",
        isEquippedItem = true,  -- Special case: this item must be equipped to use
        equipSlot = "Trinket0Slot" -- Trinket slot
    },
    ["Hearthstone"] = {
        itemID = 6948,
        texture = "Interface\\Icons\\INV_Misc_Rune_01",
        isEquippedItem = false
    }
}

-- Main frame
local barFrame

-- Saved variables
Lyft_Settings = {}

function Lyft_Initialize()
    -- Create the main bar frame
    barFrame = CreateFrame("Frame", "LyftBarFrame", UIParent)
    barFrame:SetHeight(BAR_HEIGHT)
    
    -- Load saved position or use default
    if Lyft_Settings.barPosition then
        barFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", 
                         Lyft_Settings.barPosition.x, 
                         Lyft_Settings.barPosition.y)
    else
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
    end
    
    barFrame:SetFrameStrata("MEDIUM")
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")
    barFrame:SetScript("OnDragStart", function() 
        this:StartMoving() 
    end)
    barFrame:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing() 
        -- Save position
        Lyft_SavePosition()
    end)
    
    -- Background
    local bg = barFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(barFrame)
    bg:SetTexture(0, 0, 0, 0)
    barFrame.background = bg
    
    -- Border
    barFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    barFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    barFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    
    -- Title (only visible when dragging)
    local title = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", barFrame, "TOP", 0, -5)
    title:SetText("Lyft - Drag to move")
    title:SetTextColor(1, 1, 1, 0.5)
    barFrame.title = title
    
    -- We'll create icons dynamically in UpdateBar
    barFrame.icons = {}
    
    -- Hide title after a few seconds
    barFrame:SetScript("OnShow", function()
        this.title:Show()
    end)
    
    -- Hide title after 3 seconds and update bar periodically
    barFrame:SetScript("OnUpdate", function(arg1)
        -- Hide title
        if this.title and this.title:IsVisible() then
            if not this.hideTime then
                this.hideTime = GetTime() + 3
            elseif GetTime() > this.hideTime then
                this.title:Hide()
                this.hideTime = nil
            end
        end
        
        -- Update bar every 0.5 seconds
        if not this.lastBarUpdate then
            this.lastBarUpdate = GetTime()
        end
        
        if GetTime() - this.lastBarUpdate > 0.5 then
            Lyft_UpdateBar()
            this.lastBarUpdate = GetTime()
        end
    end)
    
    DEFAULT_CHAT_FRAME:AddMessage("Lyft loaded! Floating bar with useful items created.")
    
    -- Initial bar update
    Lyft_UpdateBar()
end

function Lyft_SavePosition()
    if not Lyft_Settings then
        Lyft_Settings = {}
    end
    
    -- Save bar position
    local barX = barFrame:GetLeft()
    local barY = barFrame:GetTop()
    
    if barX and barY then
        if not Lyft_Settings.barPosition then
            Lyft_Settings.barPosition = {}
        end
        Lyft_Settings.barPosition.x = barX
        Lyft_Settings.barPosition.y = barY
    end
end

function Lyft_UpdateBar()
    if not barFrame then return end
    
    -- Get item counts from inventory
    local itemData = {}
    local itemCount = 0
    
    for itemName, itemInfo in trackedItems do
        local count, isEquipped, isInInventory, cooldownStart, cooldownDuration, cooldownEnable = Lyft_GetItemStatus(itemInfo.itemID, itemInfo.isEquippedItem)
        itemCount = itemCount + 1
        itemData[itemCount] = {
            id = itemInfo.itemID,
            count = count,
            name = itemName,
            texture = itemInfo.texture,
            isEquippedItem = itemInfo.isEquippedItem,
            isEquipped = isEquipped,
            isInInventory = isInInventory,
            equipSlot = itemInfo.equipSlot,
            cooldownStart = cooldownStart,
            cooldownDuration = cooldownDuration,
            cooldownEnable = cooldownEnable
        }
    end
    
    -- Sort by name for consistent ordering
    for i = 1, itemCount - 1 do
        for j = i + 1, itemCount do
            if itemData[i].name > itemData[j].name then
                local temp = itemData[i]
                itemData[i] = itemData[j]
                itemData[j] = temp
            end
        end
    end
    
    -- Update bar with items
    Lyft_UpdateBarIcons(barFrame, itemData, itemCount)
end

function Lyft_UpdateBarIcons(frame, items, itemCount)
    -- Clean up old icons if we have more than needed
    for i = itemCount + 1, table.getn(frame.icons) do
        if frame.icons[i] then
            frame.icons[i]:Hide()
            frame.icons[i] = nil
        end
    end
    
    -- Update or create icons
    for i = 1, itemCount do
        local iconFrame = frame.icons[i]
        local item = items[i]
        
        -- Create icon frame if it doesn't exist
        if not iconFrame then
            iconFrame = CreateFrame("Button", frame:GetName().."Icon"..i, frame)
            iconFrame:SetWidth(ICON_SIZE)
            iconFrame:SetHeight(ICON_SIZE)
            
            -- Icon texture
            local icon = iconFrame:CreateTexture(nil, "BACKGROUND")
            icon:SetAllPoints(iconFrame)
            iconFrame.icon = icon
            
            -- Count text
            local count = iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
            count:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -2, 2)
            count:SetJustifyH("RIGHT")
            iconFrame.count = count
            
            -- Cooldown frame (Vanilla WoW 1.12 compatible)
            local cooldown = CreateFrame("Model", frame:GetName().."Cooldown"..i, iconFrame, "CooldownFrameTemplate")
            cooldown:SetAllPoints(iconFrame)
            
            iconFrame.cooldown = cooldown
            
            -- Equipped indicator (for tabard and dimensional ripper)
            local equippedBorder = iconFrame:CreateTexture(nil, "OVERLAY")
            equippedBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            equippedBorder:SetBlendMode("ADD")
            equippedBorder:SetAlpha(0.7)
            equippedBorder:SetWidth(ICON_SIZE + 12)
            equippedBorder:SetHeight(ICON_SIZE + 12)
            equippedBorder:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
            equippedBorder:Hide()
            iconFrame.equippedBorder = equippedBorder
            
            -- Tooltip
            iconFrame:SetScript("OnEnter", function()
                if this.itemID then
                    Lyft_ShowTooltip(this)
                end
            end)
            iconFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            -- Click handler
            iconFrame:SetScript("OnClick", function()
                if this.itemID then
                    Lyft_UseItem(this.itemID, this.isEquippedItem, this.isInInventory, this.equipSlot)
                end
            end)
            
            frame.icons[i] = iconFrame
        end
        
        -- Position the icon
        iconFrame:SetPoint("LEFT", frame, "LEFT", (i-1) * (ICON_SIZE + ICON_SPACING) + ICON_SPACING, 0)
        
        -- Update icon content
        iconFrame.itemID = item.id
        iconFrame.isEquippedItem = item.isEquippedItem
        iconFrame.isInInventory = item.isInInventory
        iconFrame.equipSlot = item.equipSlot
        iconFrame.icon:SetTexture(item.texture)
        
        -- Update count display - special handling for equipped items
        if item.isEquippedItem then
            if item.isEquipped then
                iconFrame.count:SetText("USE")
                iconFrame.count:SetTextColor(0, 1, 0) -- Green for use
                iconFrame.equippedBorder:Show()
            elseif item.isInInventory then
                iconFrame.count:SetText("EQP")
                iconFrame.count:SetTextColor(1, 1, 0) -- Yellow for equip
                iconFrame.equippedBorder:Hide()
            else
                iconFrame.count:SetText("")
                iconFrame.equippedBorder:Hide()
            end
        else
            -- Normal inventory items - handle both positive counts and negative charges
            if item.count > 0 then
                -- Multiple copies
                if item.count > 1 then
                    iconFrame.count:SetText(item.count)
                    iconFrame.count:SetTextColor(1, 1, 1) -- White for normal count
                else
                    iconFrame.count:SetText("")
                end
            elseif item.count < 0 then
                -- Charges remaining (negative count)
                local charges = math.abs(item.count)
                iconFrame.count:SetText(charges)
                iconFrame.count:SetTextColor(0.5, 1, 0.5) -- Light green for charges
            else
                -- No item
                iconFrame.count:SetText("")
            end
            iconFrame.equippedBorder:Hide()
        end
        
        -- Update cooldown
        if item.cooldownStart and item.cooldownDuration and item.cooldownEnable then
            CooldownFrame_SetTimer(iconFrame.cooldown, item.cooldownStart, item.cooldownDuration, item.cooldownEnable)
        else
            CooldownFrame_SetTimer(iconFrame.cooldown, 0, 0, 0)
        end
        
        -- Update appearance based on whether item is available
        if item.isEquippedItem then
            -- For equipped items, availability is based on whether it's equipped OR in inventory
            if item.isEquipped or item.isInInventory then
                iconFrame.icon:SetDesaturated(false)
            else
                iconFrame.icon:SetDesaturated(true)
            end
        else
            -- For normal items, availability is based on count (positive OR negative)
            if item.count > 0 or item.count < 0 then
                -- Item is available - normal appearance
                iconFrame.icon:SetDesaturated(false)
                iconFrame.count:SetTextColor(1, 1, 1)
            else
                -- Item is not available - greyed out
                iconFrame.icon:SetDesaturated(true)
                iconFrame.count:SetTextColor(0.5, 0.5, 0.5)
            end
        end
        
        iconFrame:Show()
    end
    
    -- Adjust bar width based on number of items
    if itemCount > 0 then
        local newWidth = (itemCount * (ICON_SIZE + ICON_SPACING)) + ICON_SPACING
        frame:SetWidth(newWidth)
        frame:Show()
    else
        frame:Hide()
    end
end

function Lyft_GetItemStatus(itemID, isEquippedItem)
    if isEquippedItem then
        -- For equipped items, check both if equipped AND if in inventory
        local isEquipped = Lyft_IsItemEquipped(itemID)
        local isInInventory = Lyft_IsItemInInventory(itemID)
        local cooldownStart, cooldownDuration, cooldownEnable = 0, 0, 0
        
        -- Get cooldown for equipped item
        if isEquipped then
            for i = 1, 19 do
                local equippedItemID = Lyft_GetInventoryItemID(i)
                if equippedItemID and equippedItemID == itemID then
                    cooldownStart, cooldownDuration, cooldownEnable = GetInventoryItemCooldown("player", i)
                    break
                end
            end
        end
        
        return isEquipped and 1 or 0, isEquipped, isInInventory, cooldownStart, cooldownDuration, cooldownEnable
    else
        -- Normal inventory count
        local count = Lyft_GetItemCount(itemID)
        local cooldownStart, cooldownDuration, cooldownEnable = Lyft_GetItemCooldown(itemID)
        
        -- Special handling for items with charges (negative count)
        local isAvailable = count > 0 or count < 0  -- Available if positive OR negative
        
        return count, false, isAvailable, cooldownStart, cooldownDuration, cooldownEnable
    end
end

function Lyft_GetItemCount(itemID)
    local totalCount = 0
    
    -- Check all bags using GetContainerItemLink
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = Lyft_ExtractItemID(itemLink)
                if foundID and foundID == itemID then
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    totalCount = totalCount + (itemCount or 1)
                end
            end
        end
    end
    
    return totalCount
end

function Lyft_GetItemCooldown(itemID)
    -- Find the first instance of the item and return its cooldown
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = Lyft_ExtractItemID(itemLink)
                if foundID and foundID == itemID then
                    local cooldownStart, cooldownDuration, cooldownEnable = GetContainerItemCooldown(bag, slot)
                    return cooldownStart, cooldownDuration, cooldownEnable
                end
            end
        end
    end
    return 0, 0, 0
end

function Lyft_GetInventoryItemID(slot)
    local itemLink = GetInventoryItemLink("player", slot)
    if itemLink then
        return Lyft_ExtractItemID(itemLink)
    end
    return nil
end

function Lyft_IsItemInInventory(itemID)
    -- Check if item is in bags using GetContainerItemLink
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = Lyft_ExtractItemID(itemLink)
                if foundID and foundID == itemID then
                    return true
                end
            end
        end
    end
    return false
end

function Lyft_IsItemEquipped(itemID)
    -- Check all equipment slots using GetInventoryItemLink
    for i = 1, 19 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            local foundID = Lyft_ExtractItemID(itemLink)
            if foundID and foundID == itemID then
                return true
            end
        end
    end
    return false
end

-- Vanilla WoW compatible item ID extraction
function Lyft_ExtractItemID(itemLink)
    if not itemLink then return nil end
    
    -- Item link format in Vanilla: |cff9d9d9d|Hitem:6948:0:0:0|h[Hearthstone]|h|r
    -- Extract the number between "item:" and the first ":"
    local startPos = string.find(itemLink, "item:")
    if startPos then
        local afterItem = string.sub(itemLink, startPos + 5) -- +5 to skip "item:"
        local endPos = string.find(afterItem, ":")
        if endPos then
            local idString = string.sub(afterItem, 1, endPos - 1)
            return tonumber(idString)
        end
    end
    
    return nil
end

function Lyft_UseItem(itemID, isEquippedItem, isInInventory, equipSlot)
    if isEquippedItem then
        -- For equipped items like Guild Tabard and Dimensional Ripper
        if Lyft_IsItemEquipped(itemID) then
            -- Item is equipped - use it
            for i = 1, 19 do
                local itemLink = GetInventoryItemLink("player", i)
                if itemLink then
                    local foundID = Lyft_ExtractItemID(itemLink)
                    if foundID and foundID == itemID then
                        UseInventoryItem(i)
                        return
                    end
                end
            end
        elseif isInInventory then
            -- Item is in inventory but not equipped - equip it first
            Lyft_EquipItem(itemID, equipSlot)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Lyft: Item not found in inventory or equipment.")
        end
    else
        -- Find and use the item from bags
        local found = false
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    local foundID = Lyft_ExtractItemID(itemLink)
                    if foundID and foundID == itemID then
                        UseContainerItem(bag, slot)
                        found = true
                        return
                    end
                end
            end
        end
        
        if not found then
            local itemName = Lyft_GetItemNameByID(itemID)
            DEFAULT_CHAT_FRAME:AddMessage("Lyft: " .. itemName .. " not found in bags.")
        end
    end
end

function Lyft_EquipItem(itemID, equipSlot)
    -- Find the item in bags and equip it to the appropriate slot
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = Lyft_ExtractItemID(itemLink)
                if foundID and foundID == itemID then
                    -- Get the target inventory slot
                    local targetSlotID = GetInventorySlotInfo(equipSlot)
                    if targetSlotID then
                        -- Pick up the item from bag and equip it
                        PickupContainerItem(bag, slot)
                        EquipCursorItem(targetSlotID)
                        DEFAULT_CHAT_FRAME:AddMessage("Lyft: Equipped " .. Lyft_GetItemNameByID(itemID))
                        return
                    end
                end
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage("Lyft: Could not equip item - not found in bags.")
end

function Lyft_GetItemNameByID(itemID)
    for name, info in trackedItems do
        if info.itemID == itemID then
            return name
        end
    end
    return "Unknown Item"
end

function Lyft_ShowTooltip(iconFrame)
    GameTooltip:SetOwner(iconFrame, "ANCHOR_RIGHT")
    
    -- Find the item name from our tracked items
    local itemName, itemInfo
    for name, info in trackedItems do
        if info.itemID == iconFrame.itemID then
            itemName = name
            itemInfo = info
            break
        end
    end
    
    if itemName then
        GameTooltip:SetText(itemName)
        
        if itemInfo.isEquippedItem then
            -- Special tooltip for equipped items
            local isEquipped = Lyft_IsItemEquipped(iconFrame.itemID)
            local isInInventory = Lyft_IsItemInInventory(iconFrame.itemID)
            
            if isEquipped then
                GameTooltip:AddLine("Status: Equipped - Click to USE", 0, 1, 0)
                if itemName == "Guild Tabard" then
                    GameTooltip:AddLine("(Teleport to Guild House)", 0.7, 0.7, 0.7)
                elseif itemName == "Dimensional Ripper - Everlook" then
                    GameTooltip:AddLine("(Teleport to Everlook)", 0.7, 0.7, 0.7)
                end
            elseif isInInventory then
                GameTooltip:AddLine("Status: In bags - Click to EQUIP", 1, 1, 0)
                if itemName == "Guild Tabard" then
                    GameTooltip:AddLine("(Then click again to teleport)", 0.7, 0.7, 0.7)
                elseif itemName == "Dimensional Ripper - Everlook" then
                    GameTooltip:AddLine("(Then click again to teleport)", 0.7, 0.7, 0.7)
                end
            else
                GameTooltip:AddLine("Status: Not available", 1, 0.5, 0.5)
            end
        else
            -- Normal tooltip for inventory items
            local count = Lyft_GetItemCount(iconFrame.itemID)
            
            if count > 0 then
                GameTooltip:AddLine("Count: " .. count, 1, 1, 1)
                GameTooltip:AddLine("Click to use", 0.5, 1, 0.5)
            elseif count < 0 then
                local charges = math.abs(count)
                GameTooltip:AddLine("Charges: " .. charges, 0.5, 1, 0.5)
                GameTooltip:AddLine("Click to use", 0.5, 1, 0.5)
            else
                GameTooltip:AddLine("Count: 0 (Not in bags)", 1, 0.5, 0.5)
                GameTooltip:AddLine("Item not available", 1, 0.5, 0.5)
            end
        end
        
        GameTooltip:Show()
    end
end

-- Debug function to scan for Verdant Rune
function Lyft_DebugScanVerdantRune()
    DEFAULT_CHAT_FRAME:AddMessage("Lyft: Scanning bags for Verdant Rune...")
    
    local foundCount = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = Lyft_ExtractItemID(itemLink)
                if foundID and foundID == 41915 then -- Verdant Rune ID
                    local itemName = Lyft_GetItemNameByID(foundID)
                    local _, itemCount = GetContainerItemInfo(bag, slot)
                    DEFAULT_CHAT_FRAME:AddMessage("Found: " .. itemName .. " (ID: " .. foundID .. ") Count: " .. (itemCount or 1))
                    foundCount = foundCount + 1
                end
            end
        end
    end
    
    if foundCount == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Lyft: No Verdant Rune found in bags.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Lyft: Scan complete. Found " .. foundCount .. " Verdant Runes.")
    end
end

-- Slash command for showing/hiding the bar
SLASH_LYFT1 = "/lyft"
SLASH_LYFT2 = "/lift"
SlashCmdList["LYFT"] = function(msg)
    if not barFrame then
        Lyft_Initialize()
    else
        if barFrame:IsShown() then
            barFrame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("Lyft bar hidden. Use /lyft to show again.")
        else
            barFrame:Show()
            DEFAULT_CHAT_FRAME:AddMessage("Lyft bar shown.")
        end
    end
end

-- Slash command to reset position
SLASH_LYFTRESET1 = "/lyftreset"
SLASH_LYFTRESET2 = "/liftreset"
SlashCmdList["LYFTRESET"] = function(msg)
    -- Reset saved position
    Lyft_Settings.barPosition = nil
    
    -- Reset to default position
    if barFrame then
        barFrame:ClearAllPoints()
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        DEFAULT_CHAT_FRAME:AddMessage("Lyft: Bar position reset to default.")
    end
end

-- Slash command for debugging
SLASH_LYFTDEBUG1 = "/lyftdebug"
SLASH_LYFTDEBUG2 = "/liftdebug"
SlashCmdList["LYFTDEBUG"] = function(msg)
    if msg and string.lower(msg) == "verdant" then
        Lyft_DebugScanVerdantRune()
    else
        DEFAULT_CHAT_FRAME:AddMessage("Lyft Debug Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/lyftdebug verdant - Scan for Verdant Rune ID")
        DEFAULT_CHAT_FRAME:AddMessage("Current Verdant Rune ID: " .. trackedItems["Verdant Rune"].itemID)
    end
end

-- Initialize when the addon is loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "Lyft" then
        -- Initialize saved variables if they don't exist
        if not Lyft_Settings then
            Lyft_Settings = {}
        end
        
        -- Initialize the bar
        Lyft_Initialize()
    end
end)