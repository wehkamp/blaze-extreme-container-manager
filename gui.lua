/*
 * Cheap copy/paste code to get some sort of box showing with a tiny bit of
 * information about what's going on.
 */

good_hud = { };

local function clr(color) return color.r, color.g, color.b, color.a; end

function good_hud:PaintBar(x, y, w, h, colors, value)
	self:PaintPanel(x, y, w, h, colors);
	x = x + 1; y = y + 1;
	w = w - 2; h = h - 2;
	local width = w * math.Clamp( value, 0, 1 );
	local shade = 4;
	surface.SetDrawColor( clr( colors.shade ) );
	surface.DrawRect( x, y, width, shade );
	surface.SetDrawColor( clr( colors.fill ) );
	surface.DrawRect( x, y + shade, width, h - shade );
end

function good_hud:PaintPanel( x, y, w, h, colors )
	surface.SetDrawColor( clr( colors.border ) );
	surface.DrawOutlinedRect( x, y, w, h );
	x = x + 1; y = y + 1;
	w = w - 2; h = h - 2;
	surface.SetDrawColor( clr( colors.background ) );
	surface.DrawRect( x, y, w, h );
end

function good_hud:PaintText( x, y, text, font, colors )
	surface.SetFont( font )
	surface.SetTextPos( x + 1, y + 1 )
	surface.SetTextColor( clr( colors.shadow ) )
	surface.DrawText( text )
	surface.SetTextPos( x, y )
	surface.SetTextColor( clr( colors.text ) )
	surface.DrawText( text )
end

function good_hud:TextSize(text, font)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end

local vars = {
	font = "TargetID",
	padding = 10,
	margin = 250,
	text_spacing = 2,
	bar_spacing = 5,
	bar_height = 16,
	width = 0.25
}

local colors = {
	background = {
		border = Color( 190, 255, 128, 255 ),
		background = Color( 120, 240, 0, 75 )
	},
	text = {
		shadow = Color( 0, 0, 0, 200 ),
		text = Color( 255, 255, 255, 255 )
	}
}

/*
 * Draw information about the platform etc.
 * - spawned containers
 * - spawned zombies
 */
local function HUDPaint( )
	client = client or LocalPlayer()
	if (!client:Alive()) then return; end
	local _, th = good_hud:TextSize("TEXT", vars.font)
	local i = 8
	local width = vars.width * ScrW()
	local bar_width = width - ( vars.padding * i )
	local height = ( vars.padding * i ) + ( th * i ) + ( vars.text_spacing * i ) + ( vars.bar_height * i ) + vars.bar_spacing
	local x = 5
	local y = 5
	local cx = x + vars.padding
	local cy = y + vars.padding
	good_hud:PaintPanel(x, y, width, height, colors.background)
	local by = th + vars.text_spacing
    local zombies = #ents.FindByClass("npc_zombie")
    local allnpcs = #ents.FindByClass("npc_*")
	local text = "Zombies: "..zombies
	good_hud:PaintText( cx, cy, text, vars.font, colors.text )
	local text = "Containers: "..allnpcs-zombies
	good_hud:PaintText( cx, cy + by, text, vars.font, colors.text )
end

hook.Add( "HUDPaint", "PaintOurHud", HUDPaint );
