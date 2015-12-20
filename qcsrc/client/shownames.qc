#include "shownames.qh"

#include "hud/all.qh"

#include "../common/constants.qh"
#include "../common/mapinfo.qh"
#include "../common/teams.qh"

#include "../lib/csqcmodel/cl_model.qh"

// self.isactive = player is in range and coordinates/status (health and armor) are up to date
// self.origin = player origin
// self.healthvalue
// self.armorvalue
// self.sameteam = player is on same team as local client
// self.fadedelay = time to wait before name tag starts fading in for enemies
// self.pointtime = last time you pointed at this player
// self.csqcmodel_isdead = value of csqcmodel_isdead to know when the player is dead or not

LinkedList shownames_ent;
STATIC_INIT(shownames_ent)
{
	shownames_ent = LL_NEW();
	for (int i = 0; i < maxclients; ++i)
	{
		entity e = new(shownames_tag);
		make_pure(e);
		e.sv_entnum = i + 1;
		LL_PUSH(shownames_ent, e);
	}
}

const float SHOWNAMES_FADESPEED = 4;
const float SHOWNAMES_FADEDELAY = 0.4;
void Draw_ShowNames(entity this)
{
	if (this.sv_entnum == player_localentnum)  // self or spectatee
		if (!(autocvar_hud_shownames_self && autocvar_chase_active)) return;
	if (!this.sameteam && !autocvar_hud_shownames_enemies) return;
	bool hit;
	if (!autocvar_hud_shownames_crosshairdistance && this.sameteam)
	{
		hit = true;
	}
	else
	{
		traceline(view_origin, this.origin, MOVE_NORMAL, this);
		hit = !(trace_fraction < 1 && (trace_networkentity != this.sv_entnum && trace_ent.entnum != this.sv_entnum));
	}
	// handle tag fading
	bool overlap = false;
	vector o = project_3d_to_2d(this.origin + eZ * autocvar_hud_shownames_offset);
	float dist = vlen(this.origin - view_origin);
	if (autocvar_hud_shownames_antioverlap)
	{
		// fade tag out if another tag that is closer to you overlaps
		LL_EACH(shownames_ent, it != this && entcs_receiver(i), LAMBDA(
			vector eo = project_3d_to_2d(it.origin);
			if (eo.z < 0 || eo.x < 0 || eo.y < 0 || eo.x > vid_conwidth || eo.y > vid_conheight) continue;
			eo.z = 0;
			if (vlen((eX * o.x + eY * o.y) - eo) < autocvar_hud_shownames_antioverlap_distance
			    && dist > vlen(it.origin - view_origin))
			{
				overlap = true;
				break;
			}
		));
	}
	bool onscreen = (o.z >= 0 && o.x >= 0 && o.y >= 0 && o.x <= vid_conwidth && o.y <= vid_conheight);
	if (autocvar_hud_shownames_crosshairdistance)
	{
		float d = autocvar_hud_shownames_crosshairdistance;
		float w = o.x - vid_conwidth / 2;
		float h = o.y - vid_conheight / 2;
		if (d * d > w * w + h * h) this.pointtime = time;
		if (this.pointtime + autocvar_hud_shownames_crosshairdistance_time <= time) overlap = true;
		else overlap = (autocvar_hud_shownames_crosshairdistance_antioverlap ? overlap : false); // override what antioverlap says unless allowed by cvar.
	}
	if (!this.fadedelay) this.fadedelay = time + SHOWNAMES_FADEDELAY;
	if (this.csqcmodel_isdead)                                                                   // dead player, fade out slowly
	{
		this.alpha = max(0, this.alpha - SHOWNAMES_FADESPEED * 0.25 * frametime);
	}
	else if (!onscreen || (!this.sameteam && !hit)) // out of view, fade out
	{
		this.alpha = max(0, this.alpha - SHOWNAMES_FADESPEED * frametime);
		this.fadedelay = 0;                         // reset fade in delay, enemy has left the view
	}
	else if (overlap)                               // tag overlap detected, fade out
	{
		this.alpha = max(0, this.alpha - SHOWNAMES_FADESPEED * frametime);
	}
	else if (this.sameteam)  // fade in for team mates
	{
		this.alpha = min(1, this.alpha + SHOWNAMES_FADESPEED * frametime);
	}
	else if (time > this.fadedelay)  // fade in for enemies
	{
		this.alpha = min(1, this.alpha + SHOWNAMES_FADESPEED * frametime);
	}
	float a = autocvar_hud_shownames_alpha * this.alpha;
	// multiply by player alpha
	if (!this.sameteam || (this.sv_entnum == player_localentnum))
	{
		float f = entcs_GetAlpha(this.sv_entnum - 1);
		if (f == 0) f = 1;
		if (f < 0) f = 0;
		// FIXME: alpha is negative when dead, breaking death fade
		if (!this.csqcmodel_isdead) a *= f;
	}
	if (a < ALPHA_MIN_VISIBLE && gametype != MAPINFO_TYPE_CTS) return;
	if (autocvar_hud_shownames_maxdistance)
	{
		if (dist >= autocvar_hud_shownames_maxdistance) return;
		float f = autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance;
		a *= (f - max(0, dist - autocvar_hud_shownames_mindistance)) / f;
	}
	if (!a) return;
	float resize = 1;
	if (autocvar_hud_shownames_resize)  // limit resize so its never smaller than 0.5... gets unreadable
	{
		float f = autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance;
		resize = 0.5 + 0.5 * (f - max(0, dist - autocvar_hud_shownames_mindistance)) / f;
	}
	// draw the sprite image
	if (o.z >= 0)
	{
		o.z = 0;
		vector mySize = (eX * autocvar_hud_shownames_aspect + eY) * autocvar_hud_shownames_fontsize;
		vector myPos = o - '0.5 0 0' * mySize.x - '0 1 0' * mySize.y;
		// size scaling
		mySize.x *= resize;
		mySize.y *= resize;
		myPos.x += 0.5 * (mySize.x / resize - mySize.x);
		myPos.y += (mySize.y / resize - mySize.y);
		// this is where the origin of the string
		vector namepos = myPos;
		float namewidth = mySize.x;
		if (autocvar_hud_shownames_status && this.sameteam)
		{
			vector v = namepos + '0 1 0' * autocvar_hud_shownames_fontsize * resize;
			vector s = eX * 0.5 * mySize.x + eY * resize * autocvar_hud_shownames_statusbar_height;
			if (this.healthvalue > 0)
			{
				HUD_Panel_DrawProgressBar(v, s, "nametag_statusbar",
					this.healthvalue / autocvar_hud_panel_healtharmor_maxhealth, false, 1, '1 0 0', a,
					DRAWFLAG_NORMAL);
			}
			if (this.armorvalue > 0)
			{
				HUD_Panel_DrawProgressBar(v + eX * 0.5 * mySize.x, s, "nametag_statusbar",
					this.armorvalue / autocvar_hud_panel_healtharmor_maxarmor, false, 0, '0 1 0', a,
					DRAWFLAG_NORMAL);
			}
		}
		string s = entcs_GetName(this.sv_entnum - 1);
		if ((autocvar_hud_shownames_decolorize == 1 && teamplay)
		    || autocvar_hud_shownames_decolorize == 2) s = playername(s, entcs_GetTeam(this.sv_entnum - 1));
		drawfontscale = '1 1 0' * resize;
		s = textShortenToWidth(s, namewidth, '1 1 0' * autocvar_hud_shownames_fontsize, stringwidth_colors);
		float width = stringwidth(s, true, '1 1 0' * autocvar_hud_shownames_fontsize);
		if (width != namewidth) namepos.x += (namewidth - width) / 2;
		drawcolorcodedstring(namepos, s, '1 1 0' * autocvar_hud_shownames_fontsize, a, DRAWFLAG_NORMAL);
		drawfontscale = '1 1 0';
	}
}

void Draw_ShowNames_All()
{
	if (!autocvar_hud_shownames) return;
	LL_EACH(shownames_ent, true, LAMBDA(
		entity entcs = entcs_receiver(i);
		if (!entcs)
		{
			make_pure(it);
			continue;
		}
		make_impure(it);
		assert(entcs.think, eprint(entcs));
		WITH(entity, self, entcs, entcs.think());
		if (!entcs.has_origin) continue;
		if (entcs.m_entcs_private)
		{
			it.healthvalue = entcs.healthvalue;
			it.armorvalue = entcs.armorvalue;
			it.sameteam = true;
		}
		else
		{
			it.healthvalue = 0;
			it.armorvalue = 0;
			it.sameteam = false;
		}
		bool dead = entcs_IsDead(i) || entcs_IsSpectating(i);
		if (!it.csqcmodel_isdead) setorigin(it, entcs.origin);
		it.csqcmodel_isdead = dead;
		Draw_ShowNames(it);
	));
}
