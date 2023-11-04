function tdm.KCenter(pos,point)
	local dis = 0

	for i,point in pairs(point) do
		--local dis2 = math.min(math.max(pos:Distance(point[1]) / point[3] - 0.95,0) / 0.05,1)
	    --if dis2 < dis then dis = dis2 end
	end

	return dis
end

if SERVER then return end

local grtodown = Material( "vgui/gradient-u" )
local grtoup = Material( "vgui/gradient-d" )
local grtoright = Material( "vgui/gradient-l" )
local grtoleft = Material( "vgui/gradient-r" )

tdm.SupportCenter = true