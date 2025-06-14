#include "ammo.qh"

#include <client/draw.qh>
#include <client/items/items.qh>
#include <client/view.qh>
#include <common/mutators/mutator/nades/_mod.qh>
#include <common/resources/resources.qh>
#include <common/wepent.qh>

// Ammo (#1)

void HUD_Ammo_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_ammo_onlycurrent");
	HUD_Write_Cvar("hud_panel_ammo_noncurrent_alpha");
	HUD_Write_Cvar("hud_panel_ammo_noncurrent_scale");
	HUD_Write_Cvar("hud_panel_ammo_iconalign");
	HUD_Write_Cvar("hud_panel_ammo_progressbar");
	HUD_Write_Cvar("hud_panel_ammo_progressbar_name");
	HUD_Write_Cvar("hud_panel_ammo_progressbar_xoffset");
	HUD_Write_Cvar("hud_panel_ammo_text");
}

void DrawNadeProgressBar(vector myPos, vector mySize, float progress, vector color)
{
	HUD_Panel_DrawProgressBar(
		myPos + eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize.x,
		mySize - eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize.x,
		autocvar_hud_panel_ammo_progressbar_name,
		progress, 0, 0, color,
		autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
}

void DrawAmmoItem(vector myPos, vector mySize, Resource ammoType, bool isCurrent, bool isInfinite)
{
	TC(bool, isCurrent); TC(bool, isInfinite);
	if(ammoType == RES_NONE)
		return;

	// Initialize variables

	int ammo;
	if(autocvar__hud_configure)
	{
		isCurrent = (ammoType == RES_ROCKETS); // Rockets always current
		ammo = 60;
	}
	else
		ammo = getstati(GetAmmoStat(ammoType));

	if(!isCurrent)
	{
		float scale = bound(0.01, autocvar_hud_panel_ammo_noncurrent_scale, 1);
		myPos = myPos + (mySize - mySize * scale) * 0.5;
		mySize = mySize * scale;
	}

	vector iconPos, textPos;
	if(autocvar_hud_panel_ammo_iconalign)
	{
		iconPos = myPos + eX * 2 * mySize.y;
		textPos = myPos;
	}
	else
	{
		iconPos = myPos;
		textPos = myPos + eX * mySize.y;
	}

	bool isShadowed = (ammo <= 0 && !isCurrent && !isInfinite);

	vector iconColor = isShadowed ? '0 0 0' : '1 1 1';
	vector textColor;
	if(isInfinite)
		textColor = '0.2 0.95 0';
	else if(isShadowed)
		textColor = '0 0 0';
	else if(ammo < 10)
		textColor = '0.8 0.04 0';
	else
		textColor = '1 1 1';

	float alpha;
	if(isCurrent)
		alpha = panel_fg_alpha;
	else if(isShadowed)
		alpha = panel_fg_alpha * bound(0, autocvar_hud_panel_ammo_noncurrent_alpha, 1) * 0.5;
	else
		alpha = panel_fg_alpha * bound(0, autocvar_hud_panel_ammo_noncurrent_alpha, 1);

	string text = isInfinite ? "\xE2\x88\x9E" : ftos(ammo); // Use infinity symbol (U+221E)

	// Draw item

	if(isCurrent)
		drawpic_aspect_skin(myPos, "ammo_current_bg", mySize, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

	if(ammo > 0 && autocvar_hud_panel_ammo_progressbar)
		HUD_Panel_DrawProgressBar(myPos + eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize.x, mySize - eX * autocvar_hud_panel_ammo_progressbar_xoffset * mySize.x, autocvar_hud_panel_ammo_progressbar_name, ammo/autocvar_hud_panel_ammo_maxammo, 0, 0, textColor * 0.2 + ammoType.m_color * 0.8, autocvar_hud_progressbar_alpha * alpha, DRAWFLAG_NORMAL);

	if(autocvar_hud_panel_ammo_text)
		drawstring_aspect(textPos, text, eX * (2/3) * mySize.x + eY * mySize.y, textColor * 0.6 + ammoType.m_color * 0.4, alpha, DRAWFLAG_NORMAL);

	drawpic_aspect_skin(iconPos, ammoType.m_icon, '1 1 0' * mySize.y, iconColor, alpha, DRAWFLAG_NORMAL);
}

int nade_prevstatus;
int nade_prevframe;
float nade_statuschange_time;

void HUD_Ammo()
{
	if(hud != HUD_NORMAL) return;
	if(!autocvar__hud_configure)
	{
		if((!autocvar_hud_panel_ammo) || (spectatee_status == -1))
			return;
		if(STAT(HEALTH) <= 0 && autocvar_hud_panel_ammo_hide_ondeath)
			return;
	}

	HUD_Panel_LoadCvars();

	draw_beginBoldFont();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (autocvar_hud_panel_ammo_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();
	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	int rows = 0, columns, row, column;
	float nade_cnt = STAT(NADE_BONUS), nade_score = STAT(NADE_BONUS_SCORE);
	bool draw_nades = (nade_cnt > 0 || nade_score > 0);
	float nade_statuschange_elapsedtime;
	int total_ammo_count;

	vector ammo_size;
	if (autocvar_hud_panel_ammo_onlycurrent)
		total_ammo_count = 1;
	else
		total_ammo_count = AMMO_COUNT;

	if(draw_nades)
	{
		++total_ammo_count;
		if (nade_cnt != nade_prevframe)
		{
			nade_statuschange_time = time;
			nade_prevstatus = nade_prevframe;
			nade_prevframe = nade_cnt;
		}
	}
	else
		nade_prevstatus = nade_prevframe = nade_statuschange_time = 0;

	rows = HUD_GetRowCount(total_ammo_count, mySize, 3);
	columns = ceil((total_ammo_count)/rows);
	ammo_size = vec2(mySize.x / columns, mySize.y / rows);

	vector offset = '0 0 0';
	float newSize;
	if(ammo_size.x/ammo_size.y > 3)
	{
		newSize = 3 * ammo_size.y;
		offset.x = ammo_size.x - newSize;
		pos.x += offset.x/2;
		ammo_size.x = newSize;
	}
	else
	{
		newSize = 1/3 * ammo_size.x;
		offset.y = ammo_size.y - newSize;
		pos.y += offset.y/2;
		ammo_size.y = newSize;
	}

	entity wepent = viewmodels[0]; // TODO: unhardcode

	Weapon wep = wepent.switchweapon;
	int i;
	bool infinite_ammo = (STAT(ITEMS) & IT_UNLIMITED_AMMO);
	row = column = 0;
	if(autocvar_hud_panel_ammo_onlycurrent)
	{
		if(autocvar__hud_configure)
		{
			DrawAmmoItem(pos, ammo_size, RES_ROCKETS, true, false);
		}
		else
		{
			DrawAmmoItem(
				pos,
				ammo_size,
				wep.ammo_type,
				true,
				infinite_ammo
			);
		}

		++row;
		if(row >= rows)
		{
			row = 0;
			column = column + 1;
		}
	}
	else
	{
		row = column = 0;
		IL_EACH(default_order_resources, it.instanceOfAmmoResource && !it.m_hidden,
		{
			DrawAmmoItem(
				pos + vec2(column * (ammo_size.x + offset.x), row * (ammo_size.y + offset.y)),
				ammo_size,
				it,
				(wep.ammo_type == it),
				infinite_ammo
			);

			++row;
			if(row >= rows)
			{
				row = 0;
				column = column + 1;
			}
		});
	}

	if (draw_nades)
	{
		nade_statuschange_elapsedtime = time - nade_statuschange_time;

		float f = bound(0, nade_statuschange_elapsedtime*2, 1);

		DrawAmmoNades(pos + vec2(column * (ammo_size.x + offset.x), row * (ammo_size.y + offset.y)), ammo_size, nade_prevstatus < nade_cnt && nade_cnt != 0 && f < 1, f);
	}

	draw_endBoldFont();
}
