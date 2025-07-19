#include "cl_turrets.qh"

void turret_remove(entity this)
{
	delete(this.tur_head);
	//remove(this.enemy);
	this.tur_head = NULL;
}

.vector glowmod;
void turret_changeteam(entity this)
{
	this.glowmod = Team_ColorRGB(this.team - 1);
	this.teamradar_color = Team_ColorRGB(this.team - 1);

	if(this.team)
		this.colormap = 1024 + (this.team - 1) * 17;

	this.tur_head.colormap = this.colormap;
	this.tur_head.glowmod = this.glowmod;

}

// unused?
void turret_head_draw(entity this)
{
	this.drawmask = MASK_NORMAL;
}

void turret_draw(entity this)
{
	float dt;

	dt = time - this.move_time;
	this.move_time = time;
	if(dt <= 0)
		return;

	this.tur_head.angles += dt * this.tur_head.avelocity;

	if (GetResource(this, RES_HEALTH) < 127)
	{
		dt = random();

		if(dt < 0.03)
			te_spark(this.origin + '0 0 40', randomvec() * 256 + '0 0 256', 16);
	}

	if(GetResource(this, RES_HEALTH) < 85)
	if(dt < 0.01)
		pointparticles(EFFECT_SMOKE_LARGE, (this.origin + (randomvec() * 80)), '0 0 0', 1);

	if(GetResource(this, RES_HEALTH) < 32)
	if(dt < 0.015)
		pointparticles(EFFECT_SMOKE_SMALL, (this.origin + (randomvec() * 80)), '0 0 0', 1);

}

void turret_draw2d(entity this)
{
	if(this.netname == "")
		return;

	if(!autocvar_g_waypointsprite_turrets)
		return;

	if(autocvar_cl_hidewaypoints)
		return;

	float dist = vlen(this.origin - view_origin);
	float t = (entcs_GetTeam(player_localnum) + 1);

	vector o;
	string txt;

	if(autocvar_cl_vehicles_hud_tactical)
	if(dist < 10240 && t != this.team)
	{
		// TODO: Vehicle tactical hud
		o = project_3d_to_2d(this.origin + '0 0 32');
		if(o_z < 0
		|| o_x < (vid_conwidth * waypointsprite_edgeoffset_left)
		|| o_y < (vid_conheight * waypointsprite_edgeoffset_top)
		|| o_x > (vid_conwidth - (vid_conwidth * waypointsprite_edgeoffset_right))
		|| o_y > (vid_conheight - (vid_conheight * waypointsprite_edgeoffset_bottom)))
			return; // Dont draw wp's for turrets out of view
		o_z = 0;
		if(hud != HUD_NORMAL)
		{
			if((get_turretinfo(this.m_id)).spawnflags & TUR_FLAG_MOVE)
				txt = "gfx/vehicles/turret_moving";
			else
				txt = "gfx/vehicles/turret_stationary";

			vector pz = drawgetimagesize(txt) * autocvar_cl_vehicles_crosshair_size;
			drawpic(o - pz * 0.5, txt, pz , '1 1 1', 0.7, DRAWFLAG_NORMAL);
		}
	}

	if(dist > this.maxdistance)
		return;

	string spriteimage = this.netname;
	float a = this.alpha * autocvar_hud_panel_fg_alpha;
	vector rgb = spritelookupcolor(this, spriteimage, this.teamradar_color);


	if(this.maxdistance > waypointsprite_normdistance)
		a *= (bound(0, (this.maxdistance - dist) / (this.maxdistance - waypointsprite_normdistance), 1) ** waypointsprite_distancealphaexponent);
	else if(this.maxdistance > 0)
		a *= (bound(0, (waypointsprite_fadedistance - dist) / (waypointsprite_fadedistance - waypointsprite_normdistance), 1) ** waypointsprite_distancealphaexponent) * (1 - waypointsprite_minalpha) + waypointsprite_minalpha;

	if(rgb == '0 0 0')
	{
		this.teamradar_color = '1 0 1';
		LOG_INFOF("WARNING: sprite of name %s has no color, using pink so you notice it", spriteimage);
	}

	txt = spritelookuptext(this, spriteimage);

	if(time - floor(time) > 0.5 && t == this.team)
	{
		if(this.helpme && time < this.helpme)
		{
			a *= SPRITE_HELPME_BLINK;
			txt = sprintf(_("%s under attack!"), txt);
		}
		else
			a *= spritelookupblinkvalue(this, spriteimage);
	}

	if(autocvar_g_waypointsprite_uppercase)
		txt = strtoupper(txt);

	if(a > 1)
	{
		rgb *= a;
		a = 1;
	}

	if(a <= 0)
		return;

	rgb = fixrgbexcess(rgb);

	o = project_3d_to_2d(this.origin + '0 0 64');
	if(o_z < 0
	|| o_x < (vid_conwidth * waypointsprite_edgeoffset_left)
	|| o_y < (vid_conheight * waypointsprite_edgeoffset_top)
	|| o_x > (vid_conwidth - (vid_conwidth * waypointsprite_edgeoffset_right))
	|| o_y > (vid_conheight - (vid_conheight * waypointsprite_edgeoffset_bottom)))
		return; // Dont draw wp's for turrets out of view

	o_z = 0;

	float edgedistance_min = min((o.y - (vid_conheight * waypointsprite_edgeoffset_top)),
	(o_x - (vid_conwidth * waypointsprite_edgeoffset_left)),
	(vid_conwidth - (vid_conwidth * waypointsprite_edgeoffset_right)) - o_x,
	(vid_conheight - (vid_conheight * waypointsprite_edgeoffset_bottom)) - o_y);

	float crosshairdistance = sqrt( ((o.x - vid_conwidth/2) ** 2) + ((o.y - vid_conheight/2) ** 2) );

	t = waypointsprite_scale;
	a *= waypointsprite_alpha;

	{
		a = a * (1 - (1 - waypointsprite_distancefadealpha) * (bound(0, dist/waypointsprite_distancefadedistance, 1)));
		t = t * (1 - (1 - waypointsprite_distancefadescale) * (bound(0, dist/waypointsprite_distancefadedistance, 1)));
	}
	if (edgedistance_min < waypointsprite_edgefadedistance) {
		a = a * (1 - (1 - waypointsprite_edgefadealpha) * (1 - bound(0, edgedistance_min/waypointsprite_edgefadedistance, 1)));
		t = t * (1 - (1 - waypointsprite_edgefadescale) * (1 - bound(0, edgedistance_min/waypointsprite_edgefadedistance, 1)));
	}
	if(crosshairdistance < waypointsprite_crosshairfadedistance) {
		a = a * (1 - (1 - waypointsprite_crosshairfadealpha) * (1 - bound(0, crosshairdistance/waypointsprite_crosshairfadedistance, 1)));
		t = t * (1 - (1 - waypointsprite_crosshairfadescale) * (1 - bound(0, crosshairdistance/waypointsprite_crosshairfadedistance, 1)));
	}

	bool draw_healthbar = ((this.helpme && time < this.helpme) || !autocvar_g_waypointsprite_turrets_onlyhurt || hud != HUD_NORMAL);
	bool draw_text = autocvar_g_waypointsprite_turrets_text;

	if(draw_healthbar || draw_text) // make sure it's actually being drawn
	{
		o = drawspritearrow(o, M_PI, rgb, a, SPRITE_ARROW_SCALE * t);
	}
	if(draw_text)
	{
		o = drawsprite_TextOrIcon(true, o, M_PI, (SPRITE_HEALTHBAR_WIDTH + 2 * SPRITE_HEALTHBAR_BORDER) * t, rgb, a, waypointsprite_fontsize * '1 1 0', txt);
	}
	if(draw_healthbar)
	{
		drawhealthbar(
				o,
				0,
				GetResource(this, RES_HEALTH) / 255,
				'0 0 0',
				'0 0 0',
				0.5 * SPRITE_HEALTHBAR_WIDTH * t,
				0.5 * SPRITE_HEALTHBAR_HEIGHT * t,
				SPRITE_HEALTHBAR_MARGIN * t + 0.5 * waypointsprite_fontsize,
				SPRITE_HEALTHBAR_BORDER * t,
				0,
				rgb,
				a * SPRITE_HEALTHBAR_BORDERALPHA,
				rgb,
				a * SPRITE_HEALTHBAR_HEALTHALPHA,
				DRAWFLAG_NORMAL
				);
	}
}

void turret_construct(entity this, bool isnew)
{
	entity tur = get_turretinfo(this.m_id);

	if(this.tur_head == NULL)
		this.tur_head = spawn();

	this.netname = tur.m_name;

	setorigin(this, this.origin);
	_setmodel(this, tur.model);
	_setmodel(this.tur_head, tur.head_model);
	this.solid = SOLID_BBOX; // before setsize so it will be linked to the area grid
	this.tur_head.solid = SOLID_NOT;
	setsize(this, tur.m_mins, tur.m_maxs);
	setsize(this.tur_head, '0 0 0', '0 0 0');

	if(this.m_id == TUR_EWHEEL.m_id)
		setattachment(this.tur_head, this, "");
	else
		setattachment(this.tur_head, this, "tag_head");

	this.tur_head.classname			= "turret_head";
	this.tur_head.owner				= this;
	set_movetype(this.tur_head, MOVETYPE_NOCLIP);
	set_movetype(this, MOVETYPE_NOCLIP);
	this.tur_head.angles			= this.angles;
	SetResourceExplicit(this, RES_HEALTH, 255);
	set_movetype(this, MOVETYPE_NOCLIP);
	set_movetype(this.tur_head, MOVETYPE_NOCLIP);
	this.draw						= turret_draw;
	this.entremove					= turret_remove;
	this.drawmask					= MASK_NORMAL;
	this.tur_head.drawmask			= MASK_NORMAL;
	this.anim_start_time			= 0;
	this.draw2d = turret_draw2d;
	this.maxdistance = autocvar_g_waypointsprite_turrets_maxdist;
	this.teamradar_color = '1 0 0';
	this.alpha = 1;

	if(isnew)
	{
		IL_PUSH(g_drawables, this);
		IL_PUSH(g_drawables_2d, this);
	}

	tur.tr_setup(tur, this);
}

entity turret_gibtoss(string _model, vector _from, vector _to, vector _cmod, float _explode);
void turret_gibboom(entity this);
void turret_gib_draw(entity this)
{
	Movetype_Physics_MatchTicrate(this, autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);

	this.drawmask = MASK_NORMAL;

	if(this.cnt)
	{
		if(time >= this.nextthink)
		{
			turret_gibboom(this);
			delete(this);
		}
	}
	else
	{
		this.alpha = bound(0, this.nextthink - time, 1);
		if(this.alpha < ALPHA_MIN_VISIBLE)
			delete(this);
	}
}

void turret_gibboom(entity this)
{
	sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	pointparticles(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);

	for (int j = 1; j < 5; j = j + 1)
		turret_gibtoss(strcat("models/turrets/head-gib", ftos(j), ".md3"), this.origin + '0 0 2', this.velocity + randomvec() * 700, '0 0 0', false);
}

entity turret_gibtoss(string _model, vector _from, vector _to, vector _cmod, float _explode)
{
	entity gib;

	traceline(_from, _to, MOVE_NOMONSTERS, NULL);
	if(trace_startsolid)
		return NULL;

	gib = new(turret_gib);
	setorigin(gib, _from);
	_setmodel(gib, _model);
	gib.colormod	= _cmod;
	gib.solid	   = SOLID_CORPSE;
	gib.draw		= turret_gib_draw;
	gib.cnt		 = _explode;
	setsize(gib, '-1 -1 -1', '1 1 1');
	if(_explode)
	{
		gib.nextthink = time + 0.2 * (autocvar_cl_gibs_lifetime * (1 + prandom() * 0.15));
		gib.effects = EF_FLAME;
	}
	else
		gib.nextthink = time + autocvar_cl_gibs_lifetime * (1 + prandom() * 0.15);

	gib.gravity		 = 1;
	set_movetype(gib, MOVETYPE_BOUNCE);
	setorigin(gib,		_from);
	gib.velocity   = _to;
	gib.avelocity  = prandomvec() * 32;
	gib.move_time	   = time;
	gib.damageforcescale = 1;

	return gib;
}

void turret_die(entity this)
{
	sound (this, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	pointparticles(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);
	if (!autocvar_cl_nogibs)
	{
		// Base
		if(this.m_id == TUR_EWHEEL.m_id)
			turret_gibtoss((get_turretinfo(this.m_id)).model, this.origin + '0 0 18', this.velocity + '0 0 400' + '0.1 0.1 1' * (random() * 400), '-1 -1 -1', true);
		else if (this.m_id == TUR_WALKER.m_id)
			turret_gibtoss((get_turretinfo(this.m_id)).model, this.origin + '0 0 18', this.velocity + '0 0 300' + '0.1 0.1 1' * (random() * 200), '-1 -1 -1', true);
		else if (this.m_id == TUR_TESLA.m_id)
			turret_gibtoss((get_turretinfo(this.m_id)).model, this.origin + '0 0 18', '0 0 200', '-1 -1 -1', false);
		else
		{
			if (random() > 0.5)
			{
				turret_gibtoss("models/turrets/base-gib2.md3", this.origin + '0 0 8', '0 0 50' + randomvec() * 150, '0 0 0', false);
				turret_gibtoss("models/turrets/base-gib3.md3", this.origin + '0 0 8', '0 0 50' + randomvec() * 150, '0 0 0', false);
				turret_gibtoss("models/turrets/base-gib4.md3", this.origin + '0 0 8', '0 0 50' + randomvec() * 150, '0 0 0', false);
			}
			else
				turret_gibtoss("models/turrets/base-gib1.md3", this.origin + '0 0 8', '0 0 0', '0 0 0', true);

			entity headgib = turret_gibtoss((get_turretinfo(this.m_id)).head_model, this.origin + '0 0 32', '0 0 200' + randomvec() * 200, '-1 -1 -1', true);
			if(headgib)
			{
				headgib.angles = this.tur_head.angles;
				headgib.avelocity = this.tur_head.avelocity + randomvec() * 45;
				headgib.avelocity_y = headgib.avelocity_y * 5;
				headgib.gravity = 0.5;
			}
		}
	}

	setmodel(this, MDL_Null);
	setmodel(this.tur_head, MDL_Null);
}

NET_HANDLE(ENT_CLIENT_TURRET, bool isnew)
{
	float sf;
	sf = ReadByte();

	if(sf & TNSF_SETUP)
	{
		this.m_id = ReadByte();

		this.origin = ReadVector();
		setorigin(this, this.origin);

		this.angles = ReadAngleVector2D();

		turret_construct(this, isnew);
		this.colormap = 1024;
		this.glowmod = '0 1 1';
		this.tur_head.colormap = this.colormap;
		this.tur_head.glowmod = this.glowmod;
	}

	if(sf & TNSF_ANG)
	{
		if(this.tur_head == NULL) // aparenly this can happpen before TNSF_SETUP. great.
			this.tur_head = spawn();

		this.tur_head.angles_x = ReadShort();
		this.tur_head.angles_y = ReadShort();
		//this.tur_head.angles = this.angles + this.tur_head.angles;
	}

	if(sf & TNSF_AVEL)
	{
		if(this.tur_head == NULL) // aparenly this can happpen before TNSF_SETUP. great.
			this.tur_head = spawn();

		this.tur_head.avelocity_x = ReadShort();
		this.tur_head.avelocity_y = ReadShort();
	}

	if(sf & TNSF_MOVE)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);

		this.velocity = ReadVector();

		this.angles_y = ReadShort();

		this.move_time	 = time;
	}

	if(sf & TNSF_ANIM)
	{
		this.frame1time = ReadCoord();
		this.frame	  = ReadByte();
	}

	if(sf & TNSF_STATUS)
	{
		float _tmp;
		_tmp = ReadByte();
		if(_tmp != this.team)
		{
			this.team = _tmp;
			turret_changeteam(this);
		}

		_tmp = ReadByte();
		float myhp = GetResource(this, RES_HEALTH);
		if(_tmp == 0 && myhp != 0)
			turret_die(this);
		else if(myhp && myhp > _tmp)
			this.helpme = servertime + 10;
		else if(myhp && myhp < _tmp)
			this.helpme = 0; // we're being healed, don't spam help me waypoints

		SetResourceExplicit(this, RES_HEALTH, _tmp);
	}
	return true;
}
