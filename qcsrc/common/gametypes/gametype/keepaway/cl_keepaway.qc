#include "cl_keepaway.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>

int kaballs, kaballs_carry, kaballs_taken, kaballs_dropped;

float kaballs_carry_change_time; ///< Time when kaballs_carry last changed
float kaballs_taken_change_time; ///< Time when kaballs_taken last changed

NET_HANDLE(ENT_CLIENT_KA_BALLSTATUSES, bool isNew)
{
	int i, sf = ReadByte();
	for (i = 0; i < maxclients; ++i)
		if (playerslots[i])
			playerslots[i].gametype_status = 0;
	int kaballs_carry_prev = kaballs_carry;
	int kaballs_taken_prev = kaballs_taken;

	if (sf & SF_KA_BALLS) // receive ball statuses
	{
		kaballs = ReadShort();
		kaballs_dropped = 0;
		int ball_owner;
		for (i = 0; i < kaballs; ++i)
		{
			ball_owner = ReadByte();
			if (!ball_owner)
				++kaballs_dropped;
			else
			{
				if (!playerslots[ball_owner - 1])
					playerslots[ball_owner - 1] = new_pure(playerslot);
				++playerslots[ball_owner - 1].gametype_status;
			}
		}
		kaballs_carry = (playerslots[player_currententnum - 1] ? playerslots[player_currententnum - 1].gametype_status : 0);
		kaballs_taken = kaballs - kaballs_carry - kaballs_dropped;
	}
	else if (sf & SF_KA_RESET) // reset - 0 balls
		kaballs = kaballs_carry = kaballs_dropped = kaballs_taken = 0;

	// need to update the prevs regardless
	if (kaballs_carry != kaballs_carry_prev)
		kaballs_carry_change_time = time;
	if (kaballs_taken != kaballs_taken_prev)
		kaballs_taken_change_time = time;
	return true;
}

void HUD_Mod_Keepaway_DrawItem_Single(vector itemPos, vector itemSize, string pic, float change_time, bool cond, bool is_carrying, string text)
{
	if (mod_placeholder && !is_carrying)
		return;

	float f, alpha = (autocvar_hud_panel_modicons_animations && is_carrying && cond)
		? blink(0.85, 0.15, 5) // blink only if it's the carrying icon, and kaballs_carry == 0
		: 1;

	if (!mod_placeholder && autocvar_hud_panel_modicons_animations)
	{
		f = bound(0, (time - change_time) * 2, 1);
		if (!mod_placeholder && f < 1)
			drawpic_aspect_skin_expanding(itemPos, pic, itemSize, '1 1 1', panel_fg_alpha * alpha, DRAWFLAG_NORMAL, f);
	}
	else
		f = 1;
	if (cond)
	{
		drawpic_aspect_skin(itemPos, pic, itemSize, '1 1 1', panel_fg_alpha * alpha * f, DRAWFLAG_NORMAL);
		if (text)
			drawstring_aspect(itemPos + eX * itemSize.x, text, itemSize, '1 1 1' * alpha, panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}

void HUD_Mod_Keepaway_DrawItem_Multiple(vector itemPos, vector itemSize, float aspect_ratio, int i)
{
	float f;
	if (itemSize.x / itemSize.y > aspect_ratio)
	{
		f = itemSize.y * aspect_ratio;
		itemPos.x += (itemSize.x - f) * 0.5;
		itemSize.x = f;
	}
	else
	{
		f = itemSize.x / aspect_ratio;
		itemPos.y += (itemSize.y - f) * 0.5;
		itemSize.y = f;
	}

	itemSize.x *= 0.5;
	switch (i)
	{
		default:
		case 0:  HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, "keepawayball_carrying", kaballs_carry_change_time, kaballs_carry,   true,  itos(kaballs_carry));     break;
		case 1:  HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, "notify_ballpickedup",   kaballs_taken_change_time, kaballs_taken,   false, itos(kaballs_taken));     break;
		case 2:  HUD_Mod_Keepaway_DrawItem_Single(itemPos, itemSize, "notify_balldropped",    0,                         kaballs_dropped, false, itos(kaballs_dropped));   break;
	}
}

void HUD_Mod_Keepaway(vector myPos, vector mySize, bool should_draw)
{
	if (spectatee_status != spectatee_status_prev) // changed spec, update caches
	{
		kaballs_carry = playerslots[player_currententnum - 1].gametype_status;
		kaballs_taken = kaballs - kaballs_carry - kaballs_dropped;
		spectatee_status_prev = spectatee_status;
	}

	if (!should_draw)
		return;

	mod_active = (kaballs >= 1);
	if (autocvar__hud_configure && !mod_active) // we'll make up something, so the panel isn't empty
		mod_placeholder = mod_active = true;
	else if (!mod_active)
		return;
	else
		mod_placeholder = false;

	// Draw icons
	if (mod_placeholder || kaballs == 1)
	{
		HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, "keepawayball_carrying", kaballs_carry_change_time, kaballs_carry,   true,  "");
		HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, "notify_ballpickedup",   kaballs_taken_change_time, kaballs_taken,   false, "");
		HUD_Mod_Keepaway_DrawItem_Single(myPos, mySize, "notify_balldropped",    0,                         kaballs_dropped, false, "");
	}
	else // >1 balls: layout showing the number of carrying, taken, and dropped
		HUD_Mod_TableWithAR_Draw(myPos, mySize, 3, 2, HUD_Mod_Keepaway_DrawItem_Multiple); // 3 items to draw, aspect ratio 2 (icon & text)
}
