#include "cl_duel.qh"

#include <client/draw.qh>

void HUD_Mod_Duel_Export(int fh)
{
	HUD_Write_Cvar("hud_panel_modicons_duel_enable");
	HUD_Write_Cvar("hud_panel_modicons_duel_borders");
	HUD_Write_Cvar("hud_panel_modicons_duel_spectator_healtharmor_show_status");
}

void DrawDuelPlayer(vector elementPos, vector textSize, vector spectatorSize, int playerindex, int playerlocation, int spectatorItemCount) {
	//playerlocation means left or right position of element on the screen (for scores)
	
	int maxhealth = autocvar_hud_panel_healtharmor_maxhealth;
	int maxarmor = autocvar_hud_panel_healtharmor_maxarmor;
	float border = autocvar_hud_panel_modicons_duel_borders;
	bool enablepbar = (entcs_IsSpectating(player_localnum) && autocvar_hud_panel_modicons_duel_spectator_healtharmor_show_status);

	int sumval;

	entity entcs = entcs_receiver(playerindex);
	sumval = playerslots[playerindex].(scores(ps_primary)); //get player's score

	vector pos1 = '0 0 0';
	vector pos2 = '0 0 0';
	vector pos3 = '0 0 0';
	pos1 = elementPos + eX*border + eY*border;
	pos2 = elementPos + eY*textSize.y + eX*border - eY*border;
	pos3 = elementPos + eX*textSize.x;

	vector size1 = '0 0 0';
	vector size2 = '0 0 0';
	vector size3 = '0 0 0';
	size1 = textSize - 2*(eX*border + eY*border);
	size2 = spectatorSize - 2*eX*border;
	size3 = vec2(spectatorSize.x - textSize.x, size1.y);

	if (!enablepbar) {
		size1 = (textSize + eY*spectatorItemCount*spectatorSize.y) - 2*(eX*border + eY*border);
		size3 = vec2(size3.x, size1.y);
	}

	assert(getthink(entcs), eprint(entcs));
	getthink(entcs)(entcs);

	if (playerlocation) {
		pos3 = elementPos;
		pos1 = elementPos + eX*size3.x;
	}

	//Draw player's name
	drawcolorcodedstring_aspect(pos1, entcs_GetName(playerindex), size1, panel_fg_alpha, DRAWFLAG_NORMAL);
	//Draw player's score
	drawcolorcodedstring_aspect(pos3, itos(sumval), size3, panel_fg_alpha, DRAWFLAG_NORMAL);
	
	if (enablepbar) {
		//Background for healthbar and armorbar
		HUD_Panel_DrawProgressBar(pos2, size2, autocvar_hud_panel_healtharmor_progressbar_health, 1, 0, 0, '0 0 0', 0.3, DRAWFLAG_NORMAL);
		HUD_Panel_DrawProgressBar(pos2 + eY*spectatorSize.y, size2, autocvar_hud_panel_healtharmor_progressbar_armor, 1, 0, 0, '0 0 0', 0.3, DRAWFLAG_NORMAL);

		//Draw player's health and armor information
		HUD_Panel_DrawProgressBar(pos2, size2, autocvar_hud_panel_healtharmor_progressbar_health, entcs.healthvalue /maxhealth, 0, playerlocation, autocvar_hud_progressbar_health_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		HUD_Panel_DrawProgressBar(pos2 + eY*spectatorSize.y, size2, autocvar_hud_panel_healtharmor_progressbar_armor, GetResource(entcs, RES_ARMOR) /maxarmor, 0, playerlocation, autocvar_hud_progressbar_armor_color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	//print(strcat("Pos2: ", vtos(pos2), "\n"));
}

void HUD_Mod_Duel_Draw(vector myPos, vector mySize) {

	if (!autocvar_hud_panel_modicons_duel_enable) {
		return;
	}

	entity entcs;
	int pl1, pl2;
	int spectatorItemCount = 2;
	pl1 = -1;
	pl2 = -1;

	for (int i = 0; i <= maxclients; i++) {
		if (!entcs_IsSpectating(i)) {
			if (pl1 == -1) {
				pl1 = i;
			} else {
				pl2 = i;
			}
		}
	}

	vector pos = '0 0 0';
	vector textSize = vec2(2*mySize.x/8, 2*mySize.y/3);
	vector spectatorSize = vec2(3*textSize.x/2, textSize.y/4);
	vector partSize = vec2(mySize.x/2, mySize.y);

	for (int i = 0; i < 2; i++) {
		pos.x = myPos.x + 2*partSize.x*i - spectatorSize.x*i; //Start position with central breaks (left to left border, right to right border)
		pos.y = myPos.y;

		if (i == 0) {
			entcs = entcs_receiver(pl1);
			if (entcs) {
				DrawDuelPlayer(pos, textSize, spectatorSize, pl1, 0, spectatorItemCount);
			}
		} else {
			entcs = entcs_receiver(pl2);
			if (entcs) {
				DrawDuelPlayer(pos, textSize, spectatorSize, pl2, 1, spectatorItemCount);
			}
		}
	}

}

void HUD_Mod_Duel(vector myPos, vector mySize) {
	
	mod_active = 1; // required in each mod function that always shows something

	HUD_Mod_Duel_Draw(myPos, mySize);
}