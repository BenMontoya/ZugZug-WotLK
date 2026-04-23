ZugZug = {}
ZugZug.NAME = "ZugZug";
ZugZug.VERSION = "0.0.1";
ZugZug.PREFIX = "ZUGZUG";
ZugZug.GUILD_NAME = "Zug Zug";
ZugZug.SHOULD_SYNC_ROSTER = false
ZugZug.BOTNAME = "Zugbot"; -- For later? :)
DISCORD_LINK = "https://discord.gg/cG27gCEK4c"

CLASS_COLORS = {
    ["Warrior"] = {1, 0.78, 0.64},
    ["Paladin"] = {0.96, 0.55, 0.73},
    ["Hunter"] = {0.67, 0.83, 0.45},
    ["Rogue"] = {1, 0.96, 0.41},
    ["Priest"] = {1, 1, 1},
    ["Shaman"] = {0, 0.44, 0.87},
    ["Mage"] = {0.41, 0.8, 0.94},
    ["Warlock"] = {0.58, 0.51, 0.79},
    ["Druid"] = {1, 0.49, 0.04},
    ["Death Knight"] = {0.77, 0.12, 0.23},
}

function ZugLog(msg)
    print("|cff00ff00[Zug Zug]|r ".. msg)
end

function NormalizeName(name)
    if not name or name == "" then
        return ""
    end
    local normalized = string.gsub(name, "%-.+$", "")
    return normalized
end

local function Trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

function ParseCommand(text)
    local msg = Trim(text)
    if msg == "" then
        return "", ""
    end
    local spacePos = string.find(msg, " ", 1, true)
    if not spacePos then
        return string.lower(msg), ""
    end
    local cmd = string.lower(string.sub(msg, 1, spacePos - 1))
    local rest = Trim(string.sub(msg, spacePos + 1))
    return cmd, rest
end

function SendZugAddonMessage(msg, channel, target)
    if not msg or msg == "" then return false end
    if not channel or channel == "" then return false end
    if channel == "WHISPER" and (not target or target == "") then return false end
    if not SendAddonMessage then return false end

    SendAddonMessage(ZugZug.PREFIX, msg, channel, target)
    return true
end

function AddonBroadcast(msg)
    return SendZugAddonMessage(msg, "GUILD")
end

function AddonSend(msg, channel, target)
    return SendZugAddonMessage(msg, channel, target)
end

function BotSend(msg)
    return SendZugAddonMessage(msg, "WHISPER", ZugZug.BOTNAME)
end

function SafeEncodeText(s)
  if not s then return "" end
  s = string.gsub(s, ":", "&#58;")
  s = string.gsub(s, "\r", "")
  s = string.gsub(s, "\n", "&#10;")
  return s
end

function SafeDecodeText(s)
  if not s then return "" end
  s = string.gsub(s, "&#10;", "\n")
  s = string.gsub(s, "&#58;", ":")
  return s
end

function FixColors(str)
    return string.gsub(str, "\\124", "|")
end

function ClassColorize(name)
    local lookupName = NormalizeName(name)
    local class
    local members = {}

    if ZugZugDB and ZugZugDB.MEMBERS then
        members = ZugZugDB.MEMBERS
    end

    for i, member in ipairs(members) do
        if NormalizeName(member.name) == lookupName then
            class = member.class
            break
        end
    end

    local displayName = GetDisplayName(lookupName)
    if class and CLASS_COLORS[class] then
        local c = CLASS_COLORS[class]
        return string.format("|cff%02x%02x%02x%s|r", c[1]*255, c[2]*255, c[3]*255, displayName)
    end

    return displayName
end

function Wait(delay, func)
    local start = GetTime()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        if GetTime() - start >= delay then
            frame:SetScript("OnUpdate", nil)
            func()
            frame = nil
        end
    end)
end

function FormatTimeRemaining(timestamp)
  local now = time()
  local diff = timestamp - now
  if diff <= 0 then
    return "now"
  end
  local days = floor(diff / 86400)
  local rem = diff - (days * 86400)

  local hours = floor(rem / 3600)
  rem = rem - (hours * 3600)

  local mins = floor(rem / 60)

  local txt = ""
  if days > 0 then txt = txt .. days .. "d " end
  if hours > 0 then txt = txt .. hours .. "h " end
  if mins > 0 then txt = txt .. mins .. "m" end
  return txt
end

function UpdateMembers()
    local i 
    if not ZugZugDB.MEMBERS then ZugZugDB.MEMBERS = {} end
    for i = table.getn(ZugZugDB.MEMBERS), 1, -1 do table.remove(ZugZugDB.MEMBERS, i) end
    if not IsInGuild() then return end
    local numMembers = GetNumGuildMembers(true)
    if not numMembers then return end

    local i = 1
    while i <= numMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFileName = GetGuildRosterInfo(i)
        if name then
            table.insert(ZugZugDB.MEMBERS, {
                name = NormalizeName(name),
                class = class or "",
                rank = rank or "",
                level = level or 0,
                zone = zone or "",
                online = online or 0,
                note = note or "",
                officerNote = officerNote or ""
            })
        end
        i = i + 1
    end
    --ZugLog("Updated Guild Roster (" .. numMembers .. " members)")
end

function ColorMessage(msg, sender)
    if not msg then return "" end
    local coloredSender = ClassColorize(sender) -- includes |r at end
    local result = ""
    local lastPos = 1
    while true do
        local s, e = string.find(msg, "|r", lastPos, true)
        if not s then break end
        result = result .. string.sub(msg, lastPos, e) .. "|cff00ff00"
        lastPos = e + 1
    end
    result = result .. string.sub(msg, lastPos)
    return string.format("|cff00ff00[|r%s|cff00ff00]|r |cff00ff00%s|r", coloredSender, result)
end

function ColorOfficerMessage(msg, sender)
    if not msg then return "" end
    local coloredSender = ClassColorize(sender) -- includes |r at end
    local result = ""
    local lastPos = 1
    while true do
        local s, e = string.find(msg, "|r", lastPos, true)
        if not s then break end
        result = result .. string.sub(msg, lastPos, e) .. "|cff00ffff"
        lastPos = e + 1
    end
    result = result .. string.sub(msg, lastPos)
    return string.format("|cff00ffff[|r%s|cff00ffff]|r |cff00ffff%s|r", coloredSender, result)
end

function isOfficerOrGM(name)
    if not IsInGuild() then return nil end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local fullName, rank, rankIndex = GetGuildRosterInfo(i)
        if fullName and string.lower(fullName) == string.lower(name) then
            if rankIndex <= 1 then -- (on twow I used 2 since we had Spirit Walker and Officers)
                return 1
            end
        end
    end
    return nil
end

function isGuildMember(name)
    if not IsInGuild() then return false end
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local fullName = GetGuildRosterInfo(i)
        if fullName and string.lower(fullName) == string.lower(name) then 
            return true
        end
    end
    return false
end

function SetNickname(name, nickname)
    local realName = NormalizeName(name)
    local nick = nickname

    if not ZugZugDB then ZugZugDB = {} end
    if not ZugZugDB.NICKNAMES then ZugZugDB.NICKNAMES = {} end

    if not realName or realName == "" then
        return false
    end

    if not nick or nick == "" then
        ZugZugDB.NICKNAMES[realName] = nil
        return true
    end

    ZugZugDB.NICKNAMES[realName] = nick
    return true
end

function GetNickname(name)
    local realName = NormalizeName(name)
    if not ZugZugDB or not ZugZugDB.NICKNAMES then
        return nil
    end
    return ZugZugDB.NICKNAMES[realName]
end

function GetDisplayName(name)
    local realName = NormalizeName(name)
    local nick = GetNickname(realName)
    if nick and nick ~= "" then
        return nick
    end
    return realName
end

function ZugChatNameFilter(self, event, msg, author, ...)
    local realAuthor = NormalizeName(author)
    local displayAuthor = GetDisplayName(realAuthor)
    local coloredAuthor = ClassColorize(realAuthor)

    if displayAuthor ~= realAuthor then
        msg = "(" .. coloredAuthor .. ") " .. msg
    end

    return false, msg, author, ...
end

function HandleLogin()
    if not IsInGuild() then 
        ZugLog("You are not in a guild! WTF?!")
    else
        local guildName, guildRank, guildRankIndex = GetGuildInfo("player")
        if guildName == ZugZug.GUILD_NAME then 
            ZugLog("Welcome back, |cff00ff00".. guildRank .. "|r " .. ClassColorize(UnitName("player")) .. "!")
            ZugLog("You are a proud member of |cff00ff00<" .. guildName .. ">|r!")
            if guildRankIndex and guildRankIndex <= 1 then -- Swap to 2 if we end up having 2 officers role (like on twow)
                ZugLog("|cff00ffffOfficer|r access granted!")
                ZugZug.SHOULD_SYNC_ROSTER = true
            end
            --ZugLog("Type |cff00ff00/zug|r to toggle the UI.")
            AddonBroadcast("LOGIN~" .. ZugZug.VERSION)
            ZugZug.READY = true
            GuildRoster()
            UpdateMembers()
        else 
            ZugLog("Unfortunately you are not a member of |cff00ff00<".. ZugZug.GUILD_NAME ..">|r. Sorry you're lame.")
        end
    end
end

local rosterPoller = CreateFrame("Frame")
local lastRosterPoll = 0
local rosterPollInterval = 120
rosterPoller:SetScript("OnUpdate", function()
    if not ZugZug.READY then return end
    if not ZugZug.SHOULD_SYNC_ROSTER then return end
    if not IsInGuild() then return end
    local now = GetTime()
    if now - lastRosterPoll < rosterPollInterval then return end
    lastRosterPoll = now
    GuildRoster()
end)

-- ============
-- RIP Turtle
-- ============
ZugZug.DMF_REFERENCE = 1697328000
ZugZug.DMF_PERIOD = 60 * 60 * 24 * 7
ZugZug.DMF_LOCATIONS = {
    { name = "Thunder Bluff", zone = "Mulgore" },
    { name = "Goldshire", zone = "Elwynn Forest" },
}
function GetCurrentDMFInfo()
    local now = time()
    local ref = ZugZug.DMF_REFERENCE
    local period = ZugZug.DMF_PERIOD
    local locations = ZugZug.DMF_LOCATIONS
    
    local count = table.getn(locations)
    if count < 2 then return nil end
    
    local weeksPassed = floor((now - ref) / period)
    if weeksPassed < 0 then weeksPassed = 0 end
    
    local cyclesPassed = floor(weeksPassed / count)
    local currentIndex = weeksPassed - (cyclesPassed * count) + 1
    
    local nextIndex = currentIndex + 1
    if nextIndex > count then nextIndex = 1 end
    local nextMove = ref + ((weeksPassed + 1) * period)
    
    return {
        current = locations[currentIndex],
        next = locations[nextIndex],
        nextMove = nextMove
    }
end