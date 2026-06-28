local Players = GAMESTATE:GetHumanPlayers()
local IsUltraWide = (GetScreenAspectRatio() > 21/9)
local FilterAlpha = BackgroundFilterValues()

local ShouldDisplayStatsForPlayer = function(player)
    local pn = ToEnumShortString(player)
    local mods = SL[pn].ActiveModifiers
    local steps = mods.DataVisualizations == "Step Statistics" or ThemePrefs.Get("EnableTournamentMode") and ThemePrefs.Get("StepStats") == "Show"
    local score = mods.NPSGraphAtTop or mods.ScoreAlternatePosition or ThemePrefs.Get("EnableTournamentMode")
    local any = steps or score
    return any, steps, score
end

local ShouldDisplayStats = function()
    -- Only use this in Versus + Widescreen.
    if GAMESTATE:GetCurrentStyle():GetName() ~= "versus" or not IsUsingWideScreen() then
        return false
    end

    -- Ultrawide versus is already supported natively.
    if IsUltraWide then return false end

    local shouldDisplay = false
    for player in ivalues(Players) do
        if ShouldDisplayStatsForPlayer(player) then
            shouldDisplay = true
        end
    end
    return shouldDisplay
end

-- Returns a table of the background filter alpha values for each player
-- used to diffuse the step statistics bg quad accordingly
local determineFilterAlphas = function()
    local alphas = {}
    for player in ivalues(Players) do
        local pn = ToEnumShortString(player)
        alphas[player] = clamp(FilterAlpha[SL[pn].ActiveModifiers.BackgroundFilter]/100 or 0, 0.25, 0.9)
    end
    return alphas
end

if not ShouldDisplayStats() then
    return
end

local af = Def.ActorFrame{
    InitCommand=function(self)
		self:Center()
    end
}

local playerFilters = determineFilterAlphas()
if ShouldDisplayStats() then
    af[#af+1] = Def.Quad{
        InitCommand=function(self)
            self:diffuseleftedge(0,0,0, playerFilters[PLAYER_1] or 0.25)
                :diffuserightedge(0,0,0, playerFilters[PLAYER_2] or 0.25)
            self:zoomto(150, SCREEN_HEIGHT)
        end,
    }
end

for player in ivalues(Players) do
    local any, steps, score = ShouldDisplayStatsForPlayer(player)
    if any and #Players > 1 then
        if steps then
            -- No need to reimplement the wheel here. Just use the existing actor and modify it for our use case.
            local judgments = LoadActor("../PerPlayer/StepStatistics/TapNoteJudgments.lua", {player, false})
            judgments.InitCommand = function(self)    
                local StepsOrTrail = (GAMESTATE:IsCourseMode() and GAMESTATE:GetCurrentTrail(player)) or GAMESTATE:GetCurrentSteps(player)
                local total_tapnotes = StepsOrTrail:GetRadarValues(player):GetValue( "RadarCategory_Notes" )

                -- determine how many digits are needed to express the number of notes in base-10
                local digits = (math.floor(math.log10(total_tapnotes)) + 1)
                -- display a minimum 4 digits for aesthetic reasons
                digits = math.max(4, digits)

                self:zoom(0.8)
                self:y(100)
                self:x(65 * (player==PLAYER_1 and -1 or 1) + 1)

                if digits > 4 then
                    -- This works okay enough for 5 and 6 digits.
                    self:zoomx(self:GetZoomX() - 0.12 * (digits-4))
                end
            end
            af[#af+1] = judgments
        end

        -- Add a score to Step Stats if it's hidden by the NPS graph, alternate position or we're in Tournament Mode.
        if score then
            af[#af+1] = GameplayScoreBase(player) .. {
                InitCommand = function(self)
                    self:zoom(0.25)
                    if player == PLAYER_1 then
                        self:xy(-7, -150)
                    else
                        self:xy(65, -150)
                    end
                end
            }
        end
    end
end

af[#af+1] = Def.Banner{
    CurrentSongChangedMessageCommand=function(self)
		self:LoadFromSong( GAMESTATE:GetCurrentSong() )
		self:setsize(418,164):zoom(0.3):addy(70)
        self:SetDecodeMovie(ThemePrefs.Get("AnimateBanners"))
    end
}

return af