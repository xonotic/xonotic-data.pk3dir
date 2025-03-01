#include "cl_nades.qh"

#include <client/draw.qh>
#include <client/hud/hud.qh>

REGISTER_MUTATOR(cl_nades, true);

MUTATOR_HOOKFUNCTION(cl_nades, Ent_Projectile)
{
	entity proj = M_ARGV(0, entity);

	if (proj.cnt == PROJECTILE_NAPALM_FOUNTAIN)
	{
		proj.modelindex = 0;
		proj.traileffect = EFFECT_FIREBALL.m_id;
		return true;
	}
	if (Nade_FromProjectile(proj.cnt) != NADE_TYPE_Null)
	{
		setmodel(proj, MDL_PROJECTILE_NADE);
		entity trail = Nade_TrailEffect(proj.cnt, proj.team);
		if (trail.eent_eff_name) proj.traileffect = trail.m_id;
		return true;
	}
}
MUTATOR_HOOKFUNCTION(cl_nades, EditProjectile)
{
	if (!mut_is_active(MUT_NADES)) return;

	entity proj = M_ARGV(0, entity);

	if (proj.cnt == PROJECTILE_NAPALM_FOUNTAIN)
	{
		loopsound(proj, CH_SHOTS_SINGLE, SND_NADE_NAPALM_FLY, VOL_BASE, ATTEN_NORM);
		proj.mins = '-16 -16 -16';
		proj.maxs = '16 16 16';
	}

	entity nade_type = Nade_FromProjectile(proj.cnt);
	if (nade_type == NADE_TYPE_Null) return;

	if(STAT(NADES_SMALL))
	{
		proj.mins = '-8 -8 -8';
		proj.maxs = '8 8 8';
	}
	else
	{
		proj.mins = '-16 -16 -16';
		proj.maxs = '16 16 16';
	}
	proj.colormod = nade_type.m_color;
	set_movetype(proj, MOVETYPE_BOUNCE);
	settouch(proj, func_null);
	proj.scale = 1.5;
	proj.avelocity = randomvec() * 720;
	proj.alphamod = nade_type.m_alpha;

	if (nade_type == NADE_TYPE_TRANSLOCATE
	||  nade_type == NADE_TYPE_SPAWN
	||  nade_type == NADE_TYPE_MONSTER)
		proj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	else
		proj.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
}

MUTATOR_HOOKFUNCTION(cl_nades, BuildGameplayTipsString)
{
	if (mut_is_active(MUT_NADES))
	{
		string key = getcommandkey(_("drop weapon / throw nade"), "dropweapon");
		M_ARGV(0, string) = strcat(M_ARGV(0, string),
			"\n", sprintf(_("^3nades^8 are enabled, press ^3%s^8 to use them"), key), "\n");
	}
}

bool Projectile_isnade(int p)
{
	return Nade_FromProjectile(p) != NADE_TYPE_Null;
}
void DrawAmmoNades(vector myPos, vector mySize, bool draw_expanding, float expand_time)
{
	float bonusNades    = STAT(NADE_BONUS);
	float bonusProgress = STAT(NADE_BONUS_SCORE);
	float bonusType     = STAT(NADE_BONUS_TYPE);
	Nade def = REGISTRY_GET(Nades, max(1, bonusType));
	string nadeIcon = def.m_icon; // use the Normal Nade icon for the random nade, and draw it as rainbow
	vector nadeColor;
	if(bonusType)
		nadeColor = def.m_color;
	else
	{
		nadeColor.x = time % (M_PI * 2);
		nadeColor.y = 1;
		nadeColor.z = 1;
		nadeColor = hsv_to_rgb(nadeColor);
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

	if(bonusNades > 0 || bonusProgress > 0)
	{
		DrawNadeProgressBar(myPos, mySize, bonusProgress, nadeColor);

		if(autocvar_hud_panel_ammo_text)
			drawstring_aspect(textPos, ftos(bonusNades), vec2((2/3) * mySize.x, mySize.y), '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

		if(draw_expanding)
			drawpic_aspect_skin_expanding(iconPos, nadeIcon, '1 1 0' * mySize.y, (bonusType ? '1 1 1' : nadeColor), panel_fg_alpha, DRAWFLAG_NORMAL, expand_time);

		drawpic_aspect_skin(iconPos, nadeIcon, '1 1 0' * mySize.y, (bonusType ? '1 1 1' : nadeColor), panel_fg_alpha, DRAWFLAG_NORMAL);
	}
}
