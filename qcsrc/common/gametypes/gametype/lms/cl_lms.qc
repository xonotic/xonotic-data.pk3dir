#include "cl_lms.qh"

#include <client/draw.qh>
#include <client/hud/panel/modicons.qh>
#include <common/mutators/base.qh>

int lms_leaders;
int lms_leaders_lives_diff;
bool lms_visible_leaders;

NET_HANDLE(ENT_CLIENT_LMS_STATS, bool isNew)
{
	lms_leaders_lives_diff = ReadInt24_t();
	lms_leaders = ReadByte();
	lms_visible_leaders = ReadByte();
	return true;
}

void HUD_Mod_LMS(vector myPos, vector mySize, bool should_draw)
{
	if (!should_draw)
		return;

	mod_active = lms_leaders;
	if (autocvar__hud_configure && !mod_active) // we'll make up something, so the panel isn't empty
		mod_placeholder = mod_active = true;
	else if (!mod_active)
		return;
	else
		mod_placeholder = false;

	if (!mod_active)
		return;

	int rows = HUD_GetRowCount(2, mySize, 2); // 2 items, aspect ratio 2
	int cols = ceil(2 / rows);

	vector itemSize = vec2(mySize.x / cols, mySize.y / rows);

	vector visLeadersSize = vec2(0.5 * itemSize.x, itemSize.y);
	if (lms_visible_leaders)
		drawpic_aspect_skin(myPos, "flag_stalemate", visLeadersSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawpic_aspect_skin(myPos, "player_neutral", visLeadersSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
	drawstring_aspect(myPos + eX * visLeadersSize.x, itos(mod_placeholder ? 1 : lms_leaders), visLeadersSize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	if (rows > 1)
		myPos.y += itemSize.y;
	else
		myPos.x += itemSize.x;

	vector color;
	if (lms_leaders_lives_diff >= 4)
		color = '1 0 0';
	else if (lms_leaders_lives_diff == 3)
		color = '1 0.5 0';
	else
		color = '1 1 0';
	float scale = 0.75;
	drawstring_aspect(myPos + itemSize * (1 - scale) * 0.5, strcat("+", itos(mod_placeholder ? 2 : lms_leaders_lives_diff)), itemSize * scale, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}

REGISTER_MUTATOR(cl_lms, true);

MUTATOR_HOOKFUNCTION(cl_lms, DrawInfoMessages)
{
	if (!warmup_stage && ISGAMETYPE(LMS)
	&& playerslots[player_localnum].(scores(ps_primary)) > 0)
	{
		vector pos = M_ARGV(0, vector);
		vector mySize = M_ARGV(1, vector);
		vector fontsize = '0.2 0.2 0' * mySize.y;
		int img_curr_group = M_ARGV(2, int);
		InfoMessage(_("^1You have no more lives left"));
		M_ARGV(0, vector) = pos;
		M_ARGV(2, int) = img_curr_group;
		return true;
	}
	return false;
}
