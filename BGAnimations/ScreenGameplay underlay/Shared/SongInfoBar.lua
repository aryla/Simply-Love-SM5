local players = GAMESTATE:GetHumanPlayers()
local show = false
local squish = false
for player in ivalues(players) do
	if SL[ToEnumShortString(player)].ActiveModifiers.HideSongInfoBar then
		squish = #players == 2
	else
		show = true
	end
end
if not show then
	return
end

local w = SL_WideScale(310, 417)
local h = 22

if squish then
	w = w / 2
end

-- Song Completion Meter
return Def.ActorFrame{
	Name="SongMeter",
	InitCommand=function(self)
		local x = _screen.cx
		if squish then
			local player1_hide = SL.P1.ActiveModifiers.HideSongInfoBar
			x = x + (player1_hide and w/2 or -w/2)
		end
		self:xy(x, 20)
	end,

	-- border
	Def.Quad{ InitCommand=function(self) self:zoomto(w, h) end },
	Def.Quad{ InitCommand=function(self) self:zoomto(w-4, h-4):diffuse(0,0,0,1) end },

	Def.SongMeterDisplay{
		StreamWidth=(w-4),
		Stream=Def.Quad({ InitCommand=function(self) self:zoomy(18):diffuse(GetCurrentColor(true)) end })
	},

	-- Song Title
	LoadFont("Common Normal")..{
		Name="SongTitle",
		InitCommand=function(self) self:zoom(0.8):shadowlength(0.6):maxwidth(w-8) end,
		CurrentSongChangedMessageCommand=function(self)
			local song = GAMESTATE:GetCurrentSong()
			self:settext( song and song:GetDisplayFullTitle() or "" )
		end
	}
}