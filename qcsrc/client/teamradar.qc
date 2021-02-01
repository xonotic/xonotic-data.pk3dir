#include "teamradar.qh"

#include <client/hud/_mod.qh>
#include <client/view.qh>
#include <common/mutators/mutator/waypoints/all.qh>
#include <lib/csqcmodel/interpolate.qh>

vector teamradar_3dcoord_to_texcoord(vector in)
{
	vector out;
	out.x = (in.x - mi_picmin.x) / (mi_picmax.x - mi_picmin.x);
	out.y = (in.y - mi_picmin.y) / (mi_picmax.y - mi_picmin.y);
	out.z = 0;
	return out;
}

vector teamradar_texcoord_to_2dcoord(vector in)
{
	vector out;
	in -= teamradar_origin3d_in_texcoord;

	out = Rotate(in, teamradar_angle * DEG2RAD);
	out.y = - out.y; // screen space is reversed

	out = out * teamradar_size;
	if(v_flipped)
		out.x = -out.x;
	out += teamradar_origin2d;
	return out;
}


vector teamradar_2dcoord_to_texcoord(vector in)
{
	vector out;
	out = in;

	out -= teamradar_origin2d;
	if(v_flipped)
		out_x = -out_x;
	out = out / teamradar_size;

	out_y = - out_y; // screen space is reversed
	out = Rotate(out, -teamradar_angle * DEG2RAD);

	out += teamradar_origin3d_in_texcoord;

	return out;
}

vector teamradar_texcoord_to_3dcoord(vector in,float oz)
{
	vector out;
	out_x = in_x * (mi_picmax_x - mi_picmin_x) + mi_picmin_x;
	out_y = in_y * (mi_picmax_y - mi_picmin_y) + mi_picmin_y;
	out_z = oz;
	return out;
}

void draw_teamradar_background(float fg)
{
	float fga;
	vector fgc;

	if(fg > 0 && minimapname != "")
	{
		fga = 1;
		fgc = '1 1 1' * fg;
		R_BeginPolygon(minimapname, DRAWFLAG_SCREEN | DRAWFLAG_MIPMAP, true);
		if(v_flipped)
		{
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord3), yinvert(mi_pictexcoord3), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord2), yinvert(mi_pictexcoord2), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord1), yinvert(mi_pictexcoord1), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord0), yinvert(mi_pictexcoord0), fgc, fga);
		}
		else
		{
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord0), yinvert(mi_pictexcoord0), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord1), yinvert(mi_pictexcoord1), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord2), yinvert(mi_pictexcoord2), fgc, fga);
			R_PolygonVertex(teamradar_texcoord_to_2dcoord(mi_pictexcoord3), yinvert(mi_pictexcoord3), fgc, fga);
		}
		R_EndPolygon();
	}
}

void draw_teamradar_player(vector coord3d, vector pangles, vector rgb)
{
	vector coord, rgb2;

	coord = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(coord3d));

	vector forward, right, up;
	MAKE_VECTORS(pangles - '0 1 0' * teamradar_angle, forward, right, up);
	if(v_flipped)
	{
		forward.x = -forward.x;
		right.x = -right.x;
		up.x = -up.x; // TODO: unused!
	}
	forward.z = 0;
	forward = normalize(forward);
	forward.y *= -1.0;
	right.x = -forward.y;
	right.y = forward.x;

	if(rgb == '1 1 1')
		rgb2 = '0 0 0';
	else
		rgb2 = '1 1 1';

	R_BeginPolygon("", 0, true);
	R_PolygonVertex(coord+forward*3, '0 0 0', rgb2, panel_fg_alpha);
	R_PolygonVertex(coord+right*4-forward*2.5, '0 1 0', rgb2, panel_fg_alpha);
	R_PolygonVertex(coord-forward*2, '1 0 0', rgb2, panel_fg_alpha);
	R_PolygonVertex(coord-right*4-forward*2.5, '1 1 0', rgb2, panel_fg_alpha);
	R_EndPolygon();

	R_BeginPolygon("", 0, true);
	R_PolygonVertex(coord+forward*2, '0 0 0', rgb, panel_fg_alpha);
	R_PolygonVertex(coord+right*3-forward*2, '0 1 0', rgb, panel_fg_alpha);
	R_PolygonVertex(coord-forward, '1 0 0', rgb, panel_fg_alpha);
	R_PolygonVertex(coord-right*3-forward*2, '1 1 0', rgb, panel_fg_alpha);
	R_EndPolygon();
}

void draw_teamradar_icon(vector coord, entity icon, entity pingdata, vector rgb, float a)
{
	coord = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(coord));
	drawpic_builtin(coord - '4 4 0', strcat("gfx/teamradar_icon_", ftos(icon.m_radaricon)), '8 8 0', rgb, a, 0);

	if(pingdata)
	{
		for(int i = 0; i < MAX_TEAMRADAR_TIMES; ++i)
		{
			float dt = pingdata.(teamradar_times[i]);
			if(dt == 0)
				continue;
			dt = time - dt;
			if(dt >= 1 || dt <= 0)
				continue;
			vector v = '2 2 0' * teamradar_size * dt;
			drawpic_builtin(coord - 0.5 * v, "gfx/teamradar_ping", v, '1 1 1', (1 - dt) * a, DRAWFLAG_ADDITIVE);
		}
	}
}

void draw_teamradar_link(vector start, vector end, int colors)
{
	TC(int, colors);
	vector c0, c1, norm;

	start = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(start));
	end = teamradar_texcoord_to_2dcoord(teamradar_3dcoord_to_texcoord(end));
	norm = normalize(start - end);
	norm.z = norm.x;
	norm.x = -norm.y;
	norm.y = norm.z;
	norm.z = 0;

	c0 = colormapPaletteColor(colors & 0x0F, false);
	c1 = colormapPaletteColor((colors & 0xF0) / 0x10, false);

	R_BeginPolygon("", 0, true);
	R_PolygonVertex(start - norm, '0 0 0', c0, panel_fg_alpha);
	R_PolygonVertex(start + norm, '0 1 0', c0, panel_fg_alpha);
	R_PolygonVertex(end + norm, '1 1 0', c1, panel_fg_alpha);
	R_PolygonVertex(end - norm, '1 0 0', c1, panel_fg_alpha);
	R_EndPolygon();
}

void teamradar_loadcvars()
{
	v_flipped = autocvar_v_flipped;
	hud_panel_radar_scale = autocvar_hud_panel_radar_scale;
	if (hud_panel_radar_maximized && !autocvar__hud_configure)
	{
		if (autocvar_hud_panel_radar_maximized_scale > 0)
			hud_panel_radar_scale = autocvar_hud_panel_radar_maximized_scale;
	}
	hud_panel_radar_foreground_alpha = autocvar_hud_panel_radar_foreground_alpha * panel_fg_alpha;
	hud_panel_radar_rotation = autocvar_hud_panel_radar_rotation;
	hud_panel_radar_zoommode = autocvar_hud_panel_radar_zoommode;
	hud_panel_radar_maximized_rotation = autocvar_hud_panel_radar_maximized_rotation;
	hud_panel_radar_maximized_zoommode = autocvar_hud_panel_radar_maximized_zoommode;

	// others default to 0
	// match this to default hud cfg file!
	if(!hud_panel_radar_scale) hud_panel_radar_scale = 4096;
	if(!hud_panel_radar_foreground_alpha) hud_panel_radar_foreground_alpha = 0.8 * panel_fg_alpha;
	if(!hud_panel_radar_size.x) hud_panel_radar_size.x = 128;
	if(!hud_panel_radar_size.y) hud_panel_radar_size.y = hud_panel_radar_size.x;
}

// radar links

NET_HANDLE(ENT_CLIENT_RADARLINK, bool isnew)
{
	int sendflags = ReadByte();

	InterpolateOrigin_Undo(this);

	this.iflags = IFLAG_VELOCITY | IFLAG_ORIGIN;
	if (isnew) IL_PUSH(g_radarlinks, this);

	if(sendflags & 1)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);
	}

	if(sendflags & 2)
	{
		this.velocity = ReadVector();
	}

	if(sendflags & 4)
	{
		this.team = ReadByte();
	}

	return = true;

	InterpolateOrigin_Note(this);
}
