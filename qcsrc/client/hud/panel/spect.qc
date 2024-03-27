#include "spect.qh"

#include <client/hud/hud.qh>
#include <client/view.qh>
#include <client/draw.qh>
#include <client/shownames.qh>
#include <client/hud/panel/healtharmor.qh>
#include <common/ent_cs.qh>
#include <common/gamemodes/gamemode/duel/duel.qh>
#include <common/resources/cl_resources.qh>

vector teamscore_size;
vector teamscore_fontsize;
vector teamname_fontsize;

void HUD_SpectHUD_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_SpectHUD_drawCurrentName(vector pos)
{
	vector tmp;
	string s;
	
	tmp = pos;
	
	s = entcs_GetName(current_player);
	tmp.x -= stringwidth_colors(s, hud_fontsize * 2) / 2;
	drawcolorcodedstring(tmp, s, hud_fontsize * 2, panel_fg_alpha, DRAWFLAG_NORMAL);

	tmp = pos;
	s = (entcs_GetRank(current_player) != "" ? entcs_GetRank(current_player) : "Spectating");
	tmp.x -= stringwidth_colors(s, hud_fontsize) / 2;
	tmp.y -= hud_fontsize.y;
	drawcolorcodedstring(tmp, s, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
}
	
void HUD_SpectHUD_drawTeamPlayers(vector pos, entity tm, vector rgb, bool invert)
{
	vector tmp_over;
	vector line_sz = vec2((vid_conwidth - 1) / 7, hud_fontsize.y * 1.5);
	vector line_sz_sub = vec2((vid_conwidth - 1) / 7, hud_fontsize.y);
	
	string playername;
	float a = panel_fg_alpha * 0.8;
	entity pl;
	
	if(invert)
		pos.x -= line_sz.x + hud_fontsize.x;
	else
		pos.x += hud_fontsize.x;	
	
	for(pl = players.sort_next; pl; pl = pl.sort_next)
	{
		if(pl.team != tm.team)
			continue;
		
		float health = 0;
		float armor = 0;
		string icon = "";
		vector icon_size = '0 0 0';
		vector icon_rgb = '1 1 1';
		
		// Position and size calculation vectors
		tmp_over = pos;
		vector total_sz = vec2(line_sz.x, line_sz.y + line_sz_sub.y);
		
		bool dead = entcs_IsDead(pl.sv_entnum) || pl.eliminated;
		
		if(dead) {
			// z411 TODO : Unhardcode luma
			icon = "gfx/hud/luma/notify_death.tga";
			icon_rgb = rgb;
		} else {
			entity entcs = entcs_receiver(pl.sv_entnum);
			if(entcs.m_entcs_private) {
				health = (min(entcs.healthvalue, autocvar_hud_panel_healtharmor_maxhealth) / autocvar_hud_panel_healtharmor_maxhealth) * line_sz.x;
				armor = (min(GetResource(entcs, RES_ARMOR), autocvar_hud_panel_healtharmor_maxarmor) / autocvar_hud_panel_healtharmor_maxarmor) * line_sz_sub.x;
					
				Weapon wep = REGISTRY_GET(Weapons, entcs.activewepid);
				icon = strcat("gfx/hud/luma/", wep.model2);
			} else {
				if(tm.team == NUM_TEAM_1)
					icon = "gfx/hud/luma/player_red";
				else if(tm.team == NUM_TEAM_2)
					icon = "gfx/hud/luma/player_blue";
				else if(tm.team == NUM_TEAM_3)
					icon = "gfx/hud/luma/player_yellow";
				else if(tm.team == NUM_TEAM_4)
					icon = "gfx/hud/luma/player_pink";
				else
					icon = "gfx/hud/luma/player_neutral";
			}
		}
		
		// Draw weapon
		if(icon != "")  {
			vector tmp_sz = draw_getimagesize(icon);
			icon_size = vec2(total_sz.y*(tmp_sz.x/tmp_sz.y), total_sz.y);
			total_sz.x += icon_size.x;
				
			if(invert) {
				pos.x -= icon_size.x;
				tmp_over.x -= icon_size.x;
			}
			drawpic(pos, icon, icon_size, icon_rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
			pos.x += icon_size.x;
		}
		
		// Get player's name
		string playername;
		if(entcs_GetRank(pl.sv_entnum) != "")
			playername = strcat(entcs_GetRank(pl.sv_entnum), "^7 ", entcs_GetName(pl.sv_entnum));
		else
			playername = entcs_GetName(pl.sv_entnum);

		playername = textShortenToWidth(playername, line_sz.x * 0.8, hud_fontsize, stringwidth_colors);
		
		// Draw health and name
		drawfill(pos, line_sz, rgb * 0.7, a * 0.3, DRAWFLAG_NORMAL);
		if(health)
			drawfill(pos, vec2(health, line_sz.y), rgb * 0.7, a, DRAWFLAG_NORMAL);
		drawcolorcodedstring(pos + eY * ((line_sz.y - hud_fontsize.y) / 2) + eX * (hud_fontsize.x * 0.5), playername, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		pos.y += line_sz.y;
		
		// Draw armor
		if(armor)
			drawfill(pos, vec2(armor, line_sz_sub.y), rgb, a, DRAWFLAG_NORMAL);
		
		// Highlight current player
		if(pl.sv_entnum == current_player && spectatee_status != -1)
			drawfill(tmp_over, total_sz, '1 1 1', a * 0.3, DRAWFLAG_NORMAL);
		if(dead || pl.eliminated)
			drawfill(tmp_over, total_sz, '0 0 0', a * 0.4, DRAWFLAG_NORMAL);
		
		if(!invert)
			pos.x -= icon_size.x;
		pos.y += line_sz_sub.y * 2;
	}
}


void HUD_SpectHUD_drawTeamScore(vector pos, entity tm, vector rgb, bool invert)
{
	if(!tm) return;
	
	vector tmp;
	string tmp_str;
	
	// Team score
	tmp_str = ftos(tm.(teamscores(ts_primary)));
	
	if(invert)
		pos.x -= teamscore_size.x;
	
	drawfill(pos, teamscore_size, rgb * 0.8, panel_fg_alpha * 0.3, DRAWFLAG_NORMAL);
	
	tmp = pos;
	tmp.x += (teamscore_size.x - stringwidth(tmp_str, true, teamscore_fontsize)) / 2;
	tmp.y += (teamscore_size.y - teamscore_fontsize.y) / 2;
		
	draw_beginBoldFont();
	drawstring(tmp, tmp_str, teamscore_fontsize, rgb, panel_fg_alpha, DRAWFLAG_NORMAL);
	draw_endBoldFont();
	
	// Team name
	tmp_str = Team_CustomName(tm.team);
	
	tmp = pos;
	if(invert)
		tmp.x -= stringwidth_colors(tmp_str, teamname_fontsize) + teamname_fontsize.x * 0.5;
	else
		tmp.x += teamscore_size.x + teamname_fontsize.x * 0.5;
	tmp.y += (teamscore_size.y - teamname_fontsize.y) / 2;
	
	drawcolorcodedstring(tmp, tmp_str, teamname_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_SpectHUD_drawDuelScore(vector pos, entity pl, bool invert)
{
	if(!pl) return;
	
	vector tmp, tmp_in;
	string tmp_str;
	vector health_sz = vec2((vid_conwidth - 1) / 6, teamscore_size.y * 0.4);
	vector armor_sz = vec2(health_sz.x, health_sz.y / 4);
	vector total_sz = vec2(health_sz.x + teamscore_size.x + (teamscore_size.x * 0.1), teamscore_size.y);
	
	float health = 0;
	float armor = 0;
	
	entity entcs = entcs_receiver(pl.sv_entnum);
	if(entcs.m_entcs_private) {
		health = (min(entcs.healthvalue, autocvar_hud_panel_healtharmor_maxhealth) / autocvar_hud_panel_healtharmor_maxhealth) * health_sz.x;
		armor = (min(GetResource(entcs, RES_ARMOR), autocvar_hud_panel_healtharmor_maxarmor) / autocvar_hud_panel_healtharmor_maxarmor) * armor_sz.x;
	}
	
	if(invert)
		pos.x -= teamscore_size.x;
	
	// Highlight current player
	tmp = pos;
	if(invert) tmp.x -= health_sz.x + (teamscore_size.x * 0.1);
	
	if(pl.sv_entnum == current_player && spectatee_status != -1)
		drawfill(tmp, total_sz, '1 1 1', panel_fg_alpha * 0.3, DRAWFLAG_NORMAL);

	if(entcs_IsDead(pl.sv_entnum))
		drawfill(tmp, total_sz, '0 0 0', panel_fg_alpha * 0.4, DRAWFLAG_NORMAL);
	
	// Player score
	tmp_str = ftos(pl.(scores(ps_primary)));
	
	drawfill(pos, teamscore_size, '0 0 0', panel_fg_alpha * 0.3, DRAWFLAG_NORMAL);
	
	tmp = pos;
	tmp.x += (teamscore_size.x - stringwidth(tmp_str, true, teamscore_fontsize)) / 2;
	tmp.y += (teamscore_size.y - teamscore_fontsize.y) / 2;
		
	draw_beginBoldFont();
	drawstring(tmp, tmp_str, teamscore_fontsize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	draw_endBoldFont();
	
	// Player health/armor
	tmp_in = pos;
	tmp_in.y += ((teamscore_size.y / 2) - health_sz.y) / 2;
	
	// Background
	tmp = tmp_in;
	if(invert)
		tmp.x -= health_sz.x;
	else
		tmp.x += teamscore_size.x;
	
	drawfill(tmp, health_sz, '0 0 0', panel_fg_alpha * 0.3, DRAWFLAG_NORMAL);
	
	// Bars
	if(health) {
		tmp = tmp_in;
		if(invert)
			tmp.x -= health;
		else
			tmp.x += teamscore_size.x;
	
		drawfill(tmp, vec2(health, health_sz.y), autocvar_hud_progressbar_health_color, panel_fg_alpha * 0.7, DRAWFLAG_NORMAL);
	}
	
	if(armor) {
		tmp = tmp_in;
		//tmp.y += health_sz.y - armor_sz.y;
		tmp.y += health_sz.y;
		
		if(invert)
			tmp.x -= armor;
		else
			tmp.x += teamscore_size.x;
		
		drawfill(tmp, vec2(armor, armor_sz.y), autocvar_hud_progressbar_armor_color, panel_fg_alpha * 0.7, DRAWFLAG_NORMAL);
	}
	
	// Align vertically
	tmp = pos;
	tmp.y += ((teamscore_size.y / 2) - teamname_fontsize.y) / 2;
	tmp.y += teamscore_size.y / 2;
	
	// RJZ rank
	string rank_str = entcs_GetRank(pl.sv_entnum);
	if(rank_str != "") {
		if(invert)
			tmp.x -= stringwidth_colors(rank_str, teamname_fontsize) + teamname_fontsize.x * 0.5;
		else
			tmp.x += teamscore_size.x + teamname_fontsize.x * 0.5;
		
		draw_beginBoldFont();
		drawcolorcodedstring(tmp, rank_str, teamname_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
		draw_endBoldFont();
	}
	
	// Player name
	tmp_str = entcs_GetName(pl.sv_entnum);
	
	if(invert)
		tmp.x -= stringwidth_colors(tmp_str, teamname_fontsize) + teamname_fontsize.x * 0.5;
	else
		tmp.x += (rank_str != "" ? stringwidth_colors(rank_str, teamname_fontsize) : teamscore_size.x) + teamname_fontsize.x * 0.5;
	
	drawcolorcodedstring(tmp, tmp_str, teamname_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
}

void HUD_SpectHUD()
{
	if(!spectatee_status) return;
	
	vector pos, rgb;
	float ammo_y, timer_width;
	entity tm;
	
	// Set main vars
	HUD_Panel_LoadCvars();
	HUD_Scale_Enable();
	hud_fontsize = HUD_GetFontsize("hud_fontsize");
	
	// Spectator name
	if (autocvar_hud_panel_spect_playername)
	{
		if(spectatee_status != -1) {
			ammo_y = stov(cvar_string("hud_panel_ammo_pos")).y * vid_conheight;
			pos = panel_pos + vec2((vid_conwidth - 1) / 2, (ammo_y - (hud_fontsize.y * 2)));
			HUD_SpectHUD_drawCurrentName(pos);
		}
	}
	
	// Scores
	if (!autocvar_hud_panel_spect_scores) return;
	if (teamplay)
	{
		// Set vars
		teamscore_fontsize = hud_fontsize * 3;
		teamname_fontsize = hud_fontsize * 2;
		teamscore_size = vec2(teamscore_fontsize.x * 1.5, teamscore_fontsize.y * 1.25);
		timer_width = stov(cvar_string("hud_panel_timer_size")).x * vid_conwidth;
		
		// Team 1
		pos = panel_pos + vec2((vid_conwidth - 1) / 2, 0);
		tm = GetTeam(NUM_TEAM_1, false);
		rgb = Team_ColorRGB(tm.team);
		pos.x -= (timer_width * 1.3) / 2;
		HUD_SpectHUD_drawTeamScore(pos, tm, rgb, true);
		
		pos = panel_pos + vec2(0, (vid_conheight - 1) / 4 + hud_fontsize.y);
		HUD_SpectHUD_drawTeamPlayers(pos, tm, rgb, false);
		
		// Team 2
		pos = panel_pos + vec2((vid_conwidth - 1) / 2, 0);
		tm = GetTeam(NUM_TEAM_2, false);
		rgb = Team_ColorRGB(tm.team);
		pos.x += (timer_width * 1.3) / 2;
		HUD_SpectHUD_drawTeamScore(pos, tm, rgb, false);
		
		pos = panel_pos + vec2(vid_conwidth - 1, (vid_conheight - 1) / 4 + hud_fontsize.y);
		HUD_SpectHUD_drawTeamPlayers(pos, tm, rgb, true);

		// Team 3
		pos = panel_pos + vec2((vid_conwidth - 1) / 2, 41);
		tm = GetTeam(NUM_TEAM_3, false);
		rgb = Team_ColorRGB(tm.team);
		pos.x -= (timer_width * 1.3) / 2;
		HUD_SpectHUD_drawTeamScore(pos, tm, rgb, true);
		
		pos = panel_pos + vec2(0, (vid_conheight + 450) / 4 + hud_fontsize.y);
		HUD_SpectHUD_drawTeamPlayers(pos, tm, rgb, false);

		// Team 4
		pos = panel_pos + vec2((vid_conwidth - 1) / 2, 41);
		tm = GetTeam(NUM_TEAM_4, false);
		rgb = Team_ColorRGB(tm.team);
		pos.x += (timer_width * 1.3) / 2;
		HUD_SpectHUD_drawTeamScore(pos, tm, rgb, false);
		
		pos = panel_pos + vec2(vid_conwidth - 1, (vid_conheight + 450) / 4 + hud_fontsize.y);
		HUD_SpectHUD_drawTeamPlayers(pos, tm, rgb, true);
	} else if(gametype == MAPINFO_TYPE_DUEL) {
		// Set vars
		teamscore_fontsize = hud_fontsize * 3;
		teamname_fontsize = hud_fontsize * 1.5;
		teamscore_size = vec2(teamscore_fontsize.x * 1.5, teamscore_fontsize.y * 1.25);
		timer_width = stov(cvar_string("hud_panel_timer_size")).x * vid_conwidth;
		
		entity pl_left = players.sort_next;
		entity pl_right = pl_left.sort_next;
	
		// Left player
		if(pl_left && (entcs_GetSpecState(pl_left.sv_entnum)) != ENTCS_SPEC_PURE) {
			pos = panel_pos + vec2((vid_conwidth - 1) / 2, 0);
			pos.x -= (timer_width * 1.3) / 2;
			HUD_SpectHUD_drawDuelScore(pos, pl_left, true);
		}
		
		// Right player
		if(pl_right && (entcs_GetSpecState(pl_right.sv_entnum)) != ENTCS_SPEC_PURE) {
			pos = panel_pos + vec2((vid_conwidth - 1) / 2, 0);
			pos.x += (timer_width * 1.3) / 2;
			HUD_SpectHUD_drawDuelScore(pos, pl_right, false);
		}
	}
}
