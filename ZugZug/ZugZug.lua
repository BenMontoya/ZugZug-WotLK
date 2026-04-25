local zug = CreateFrame("Frame")

zug:RegisterEvent("PLAYER_LOGIN")
zug:RegisterEvent("VARIABLES_LOADED")
zug:RegisterEvent("CHAT_MSG_ADDON")
zug:RegisterEvent("CHAT_MSG_SYSTEM")
zug:RegisterEvent("CHAT_MSG_GUILD")
zug:RegisterEvent("GUILD_ROSTER_UPDATE")
zug:RegisterEvent("GUILD_MOTD")

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", ZugChatNameFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", ZugChatNameFilter)

local function ShowHelp()
    ZugLog("Commands:")
    ZugLog("|cff00ff00/zug dmf|r - Darkmoon Faire (RIP)")
    ZugLog("|cff00ff00/zug shellcoin|r - Shellcoin Price")
    ZugLog("|cff00ff00/zug nick Name Nickname|r - Set nickname by character name")
    ZugLog("|cff00ff00/zug nick Nickname|r - Set nickname for your current target")
    ZugLog("|cff00ff00/zug clearnick Name|r - Clear nickname")
end

local function HandlePing(args)
    ZugLog("PONG! Zug Zug, " .. ClassColorize(UnitName("player")) .. "!")
end

local function HandleDMF()
    local dmf = GetCurrentDMFInfo()
    if not dmf then return end

    local current = "|cFF00FF00" .. dmf.current.name .. " (" .. dmf.current.zone .. ")|r"
    local nextLoc = "|cFF00FF00" .. dmf.next.name .. " (" .. dmf.next.zone .. ")|r"
    local remaining = "|cFFFFFF00" .. FormatTimeRemaining(dmf.nextMove) .. "|r"

    ZugLog("Darkmoon Faire is currently in " .. current)
    ZugLog("Will be in " .. nextLoc .. " in " .. remaining)
end

local function HandleRIPTurtle()
    ZugLog("RIP Turtle WoW.")
    ZugLog("Zug Zug had 4,183 members, 188 peak online.")
    ZugLog("270 registered raiders, 5 active raid teams.")
    ZugLog("The servers may be down, but Zug Zug lives on.")
    ZugLog("Zug Zug, " .. ClassColorize(UnitName("player")) .. "!")
end

local function HandleNickname(args)
    local msg = args or ""
    local explicitName, explicitNickname = string.match(msg, "^(%S+)%s+(.+)$")

    if explicitName and explicitNickname then
        explicitName = NormalizeName(explicitName)
        if SetNickname(explicitName, explicitNickname) then
            ZugLog("Nickname set: " .. explicitName .. " -> |cff00ff00" .. explicitNickname .. "|r")
        else
            ZugLog("Failed to set nickname.")
        end
        return
    end

    local targetName = UnitName("target")
    if targetName and targetName ~= "" and UnitIsPlayer("target") then
        local nickname = msg
        if not nickname or nickname == "" then
            ZugLog("Usage: /zug nick Nickname  (while targeting a player)")
            ZugLog("   or: /zug nick CharacterName Nickname")
            return
        end

        targetName = NormalizeName(targetName)
        if SetNickname(targetName, nickname) then
            ZugLog("Nickname set: " .. targetName .. " -> |cff00ff00" .. nickname .. "|r")
        else
            ZugLog("Failed to set nickname.")
        end
        return
    end

    ZugLog("Usage: /zug nick CharacterName Nickname")
    ZugLog("   or: /zug nick Nickname  (while targeting a player)")
end

local function HandleClearNickname(args)
    local target = NormalizeName(args or "")

    if target and target ~= "" then
        SetNickname(target, nil)
        ZugLog("Cleared nickname for " .. target)
        return
    end

    local targetName = UnitName("target")
    if targetName and targetName ~= "" and UnitIsPlayer("target") then
        targetName = NormalizeName(targetName)
        SetNickname(targetName, nil)
        ZugLog("Cleared nickname for " .. targetName)
        return
    end

    ZugLog("Usage: /zug clearnick CharacterName")
    ZugLog("   or: /zug clearnick  (while targeting a player)")
end

local function OnSlashCommand(msg)
    local cmd, args = ParseCommand(msg)

    if cmd == "ping" then HandlePing(args) return end
    if cmd == "dmf" or cmd == "moon" then HandleDMF() return end
    if cmd == "shellcoin" then HandleRIPTurtle() return end
    if cmd == "nick" then HandleNickname(args) return end
    if cmd == "clearnick" then HandleClearNickname(args) return end

    ShowHelp()
    return
end

local function OnAddonMessage(prefix, message, channel, sender)
    local senderName = NormalizeName(sender)
    local playerName = NormalizeName(UnitName("player"))

    if senderName == playerName then return end
    if not prefix or prefix ~= ZugZug.PREFIX then return end
    if not message or message == "" then return end

    local sep = string.find(message, "~", 1, true)
    if not sep then return end

    local cmd = string.upper(string.sub(message, 1, sep - 1))
    local data = string.sub(message, sep + 1)

    if senderName == ZugZug.BOTNAME then 
        if cmd == "AHSYNC" then 
            local status = data or "unknown"
            ZugLog(ClassColorize(senderName) .. " Auction House scan: " .. status)
        end
        return
    end
    if cmd == "LOGIN" then 
        local version = data or "unknown"
        ZugLog(ClassColorize(senderName) .. " logged in with Zug Zug addon version |cff00ff00" .. version .. "|r")
        return
    end
 
    ZugLog("AddonMessage: [" .. (channel or "nil") .. "] sender=" .. (senderName or "nil") .. " cmd=" .. (cmd or "nil") .. " data=" .. (data or "nil"))
end

SLASH_ZUGZUG1 = "/zug"
SLASH_ZUGZUG2 = "/zugzug"
SLASH_ZUGZUG3 = "/zz"

SlashCmdList["ZUGZUG"] = function(msg) OnSlashCommand(msg) return end

zug:SetScript("OnEvent", function(self, eventName, ...)
    if eventName == "PLAYER_LOGIN" then
        Wait(2, HandleLogin)
    elseif eventName == "VARIABLES_LOADED" then 
        ZugZugDB = ZugZugDB or {} 
        ZugZugDB.MEMBERS = ZugZugDB.MEMBERS or {}
        ZugZugDB.NICKNAMES = ZugZugDB.NICKNAMES or {}
        ZugZugDB.VERSION = ZugZug.VERSION
    elseif eventName == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        OnAddonMessage(prefix, message, channel, sender)
    elseif eventName == "GUILD_ROSTER_UPDATE" then
        UpdateMembers()
    end
end)