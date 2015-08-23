const string vCROSS_BURST = "gfx/vehicles/crosshair_burst.tga";
const string vCROSS_DROP  = "gfx/vehicles/crosshair_drop.tga";
const string vCROSS_GUIDE = "gfx/vehicles/crosshair_guide.tga";
const string vCROSS_HEAL  = "gfx/vehicles/crosshair_heal.tga";
const string vCROSS_HINT  = "gfx/vehicles/crosshair_hint.tga";
const string vCROSS_LOCK  = "gfx/vehicles/crosshair_lock.tga";
const string vCROSS_RAIN  = "gfx/vehicles/crosshair_rain.tga";

entity dropmark;

const int MAX_AXH = 4;
entity AuxiliaryXhair[MAX_AXH];

.string axh_image;
.float  axh_fadetime;
.int    axh_drawflag;

float alarm1time;
float alarm2time;

void vehicle_alarm(entity e, int ch, string s0und)
{
	if(!autocvar_cl_vehicles_alarm)
		return;

	sound(e, ch, s0und, VOL_BASEVOICE, ATTEN_NONE);
}

void AuxiliaryXhair_Draw2D()
{
	if (scoreboard_showscores)
		return;

	vector size = draw_getimagesize(self.axh_image) * autocvar_cl_vehicles_crosshair_size;
	vector pos = project_3d_to_2d(self.move_origin) - 0.5 * size;

	if (!(pos.z < 0 || pos.x < 0 || pos.y < 0 || pos.x > vid_conwidth || pos.y > vid_conheight))
	{
		pos.z = 0;
		size.z = 0;
		drawpic(pos, self.axh_image, size, self.colormod, autocvar_crosshair_alpha * self.alpha, self.axh_drawflag);
	}

	if(time - self.cnt > self.axh_fadetime)
		self.draw2d = func_null;
}

void Net_AuXair2(bool bIsNew)
{
	int axh_id	= bound(0, ReadByte(), MAX_AXH);
	entity axh 		= AuxiliaryXhair[axh_id];

	if(axh == world || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
	{
		axh					= spawn();
		axh.draw2d			= func_null;
		axh.drawmask 		= MASK_NORMAL;
		axh.axh_drawflag	= DRAWFLAG_ADDITIVE;
		axh.axh_fadetime	= 0.1;
		axh.axh_image		= vCROSS_HINT;
		axh.alpha			= 1;
		AuxiliaryXhair[axh_id] = axh;
	}

	axh.move_origin_x	= ReadCoord();
	axh.move_origin_y	= ReadCoord();
	axh.move_origin_z	= ReadCoord();
	axh.colormod_x		= ReadByte() / 255;
	axh.colormod_y		= ReadByte() / 255;
	axh.colormod_z		= ReadByte() / 255;
	axh.cnt 			= time;
	axh.draw2d			= AuxiliaryXhair_Draw2D;
}

void Net_VehicleSetup()
{
	int hud_id = ReadByte();

	// hud_id == 0 means we exited a vehicle, so stop alarm sound/s
	if(hud_id == 0)
	{
		sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
		sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
		return;
	}

	// Init auxiliary crosshairs
	for(int i = 0; i < MAX_AXH; ++i)
	{
		entity axh = AuxiliaryXhair[i];

		if(axh != world && !wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
			remove(axh);

		axh              = spawn();
		axh.draw2d       = func_null;
		axh.drawmask     = MASK_NORMAL;
		axh.axh_drawflag = DRAWFLAG_NORMAL;
		axh.axh_fadetime = 0.1;
		axh.axh_image    = vCROSS_HINT;
		axh.alpha        = 1;
		AuxiliaryXhair[i] = axh;
	}

	if(hud_id == HUD_BUMBLEBEE_GUN)
	{
		AuxiliaryXhair[0].axh_image = vCROSS_BURST; // Plasma cannons
		AuxiliaryXhair[1].axh_image = vCROSS_BURST; // Raygun
	}
	else { VEH_ACTION(hud_id, VR_SETUP); }
}

void Vehicles_drawHUD(
	string vehicle,
	string vehicleWeapon1,
	string vehicleWeapon2,
	string iconAmmo1,
	vector colorAmmo1,
	string iconAmmo2,
	vector colorAmmo2,
	string crosshair)
{
	if(autocvar_r_letterbox)
		return;

	if(scoreboard_showscores)
		return;

	// Initialize
	vector hudSize = '0 0 0';
	vector hudPos  = '0 0 0';
	vector tmpSize = '0 0 0';
	vector tmpPos  = '0 0 0';

	float hudAlpha = autocvar_hud_panel_fg_alpha;
	float barAlpha = autocvar_hud_progressbar_alpha * hudAlpha;
	float blinkValue = 0.55 + sin(time * 7) * 0.45;

	float health  = getstati(STAT_VEHICLESTAT_HEALTH)  * 0.01;
	float shield  = getstati(STAT_VEHICLESTAT_SHIELD)  * 0.01;
	float energy  = getstati(STAT_VEHICLESTAT_ENERGY)  * 0.01;
	float ammo1   = getstati(STAT_VEHICLESTAT_AMMO1)   * 0.01;
	float reload1 = getstati(STAT_VEHICLESTAT_RELOAD1) * 0.01;
	float ammo2   = getstati(STAT_VEHICLESTAT_AMMO2)   * 0.01;
	float reload2 = getstati(STAT_VEHICLESTAT_RELOAD2) * 0.01;

	// HACK to deal with the inconsistent use of the vehicle stats
	ammo1 = (ammo1) ? ammo1 : energy;

	// Frame
	string frame = strcat(hud_skin_path, "/vehicle_frame");
	if (precache_pic(frame) == "")
		frame = "gfx/hud/default/vehicle_frame";

	hudSize  = draw_getimagesize(frame) * autocvar_cl_vehicles_hudscale;
	hudPos.x = (vid_conwidth - hudSize.x) / 2;
	hudPos.y = vid_conheight - hudSize.y;

	if(teamplay && autocvar_hud_panel_bg_color_team)
		drawpic(hudPos, frame, hudSize, myteamcolors * autocvar_hud_panel_bg_color_team, autocvar_hud_panel_bg_alpha, DRAWFLAG_NORMAL);
	else
		drawpic(hudPos, frame, hudSize, autocvar_hud_panel_bg_color, autocvar_hud_panel_bg_alpha, DRAWFLAG_NORMAL);

	if(!autocvar__vehicles_shownchasemessage && time < vh_notice_time)
	{
		float tmpblinkValue = 0.55 + sin(time * 3) * 0.45;
		tmpPos.x = hudPos.x + hudSize.x * (96/256) - tmpSize.x;
		tmpPos.y = hudPos.y;
		tmpSize = '1 1 1' * hud_fontsize;
		drawstring(tmpPos, sprintf(_("Press %s"), getcommandkey("dropweapon", "dropweapon")), tmpSize, '1 0 0' + '0 1 1' * tmpblinkValue, hudAlpha, DRAWFLAG_NORMAL);
	}

	// Model
	tmpSize.x = hudSize.x / 3;
	tmpSize.y = hudSize.y;
	tmpPos.x  = hudPos.x + hudSize.x / 3;
	tmpPos.y  = hudPos.y;

	if(health < 0.25)
		drawpic_skin(tmpPos, vehicle, tmpSize, '1 0 0' + '0 1 1' * blinkValue, hudAlpha, DRAWFLAG_NORMAL);
	else
		drawpic_skin(tmpPos, vehicle, tmpSize, '1 1 1' * health  + '1 0 0' * (1 - health), hudAlpha, DRAWFLAG_NORMAL);

	if(vehicleWeapon1)
		drawpic_skin(tmpPos, vehicleWeapon1, tmpSize, '1 1 1' * ammo1 + '1 0 0' * (1 - ammo1), hudAlpha, DRAWFLAG_NORMAL);
	if(vehicleWeapon2)
		drawpic_skin(tmpPos, vehicleWeapon2, tmpSize, '1 1 1' * ammo2 + '1 0 0' * (1 - ammo2), hudAlpha, DRAWFLAG_NORMAL);

	drawpic_skin(tmpPos, "vehicle_shield", tmpSize, '1 1 1' * shield + '1 0 0' * (1 - shield), hudAlpha * shield, DRAWFLAG_NORMAL);

	// Health bar
	tmpSize.y = hudSize.y / 2;
	tmpPos.x  = hudPos.x + hudSize.x * (32/768);
	tmpPos.y  = hudPos.y;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - health)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic_skin(tmpPos, "vehicle_bar_northwest", tmpSize, autocvar_hud_progressbar_health_color, barAlpha, DRAWFLAG_NORMAL);

	// Shield bar
	tmpPos.y = hudPos.y + hudSize.y / 2;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - shield)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic_skin(tmpPos, "vehicle_bar_southwest", tmpSize, autocvar_hud_progressbar_armor_color, barAlpha, DRAWFLAG_NORMAL);

	// Ammo1 bar
	tmpPos.x = hudPos.x + hudSize.x * (480/768);
	tmpPos.y = hudPos.y;

	if(ammo1)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo1, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload1, tmpSize.y);

	drawpic_skin(tmpPos, "vehicle_bar_northeast", tmpSize, colorAmmo1, barAlpha, DRAWFLAG_NORMAL);

	// Ammo2 bar
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(ammo2)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo2, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload2, tmpSize.y);

	drawpic_skin(tmpPos, "vehicle_bar_southeast", tmpSize, colorAmmo2, barAlpha, DRAWFLAG_NORMAL);
	drawresetcliparea();

	// Health icon
	tmpSize.x = hudSize.x * (80/768);
	tmpSize.y = hudSize.y * (80/256);
	tmpPos.x  = hudPos.x + hudSize.x * (64/768);
	tmpPos.y  = hudPos.y + hudSize.y * (48/256);

	if(health < 0.25)
	{
		if(alarm1time < time)
		{
			alarm1time = time + 2;
			vehicle_alarm(self, CH_PAIN_SINGLE, "vehicles/alarm.wav");
		}
		drawpic_skin(tmpPos, "vehicle_icon_health", tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm1time)
		{
			vehicle_alarm(self, CH_PAIN_SINGLE, "misc/null.wav");
			alarm1time = 0;
		}
		drawpic_skin(tmpPos, "vehicle_icon_health", tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Shield icon
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(shield < 0.25)
	{
		if(alarm2time < time)
		{
			alarm2time = time + 1;
			vehicle_alarm(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav");
		}
		drawpic_skin(tmpPos, "vehicle_icon_shield", tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm2time)
		{
			vehicle_alarm(self, CH_TRIGGER_SINGLE, "misc/null.wav");
			alarm2time = 0;
		}
		drawpic_skin(tmpPos, "vehicle_icon_shield", tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Ammo1 icon
	tmpPos.x = hudPos.x + hudSize.x * (624/768);
	tmpPos.y = hudPos.y + hudSize.y * (48/256);

	if(iconAmmo1)
	{
		if(ammo1)
			drawpic_skin(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
		else
			drawpic_skin(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);
	}

	// Ammo2 icon
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(iconAmmo2)
	{
		if(ammo2)
			drawpic_skin(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
		else
			drawpic_skin(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);
	}

	// Bumblebee gunner crosshairs
	if(hud == VEH_BUMBLEBEE.vehicleid)
	{
		tmpSize = '1 1 1' * hud_fontsize;
		tmpPos.x = hudPos.x + hudSize.x * (520/768);

		if(!AuxiliaryXhair[1].draw2d)
		{
			tmpPos.y = hudPos.y + hudSize.y * (96/256) - tmpSize.y;
			drawstring(tmpPos, _("No right gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
		}

		if(!AuxiliaryXhair[2].draw2d)
		{
			tmpPos.y = hudPos.y + hudSize.y * (160/256);
			drawstring(tmpPos, _("No left gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
		}
	}

	// Raptor bomb crosshair
	if(hud == VEH_RAPTOR.vehicleid && weapon2mode != RSM_FLARE)
	{
		vector where;

		if(!dropmark)
		{
			dropmark = spawn();
			dropmark.owner = self;
			dropmark.gravity = 1;
		}

		if(reload2 == 1)
		{
			setorigin(dropmark, pmove_org);
			dropmark.velocity = pmove_vel;
			tracetoss(dropmark, self);

			where = project_3d_to_2d(trace_endpos);

			setorigin(dropmark, trace_endpos);
			tmpSize = draw_getimagesize(vCROSS_DROP) * autocvar_cl_vehicles_crosshair_size;

			if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
			{
				where.x -= tmpSize.x * 0.5;
				where.y -= tmpSize.y * 0.5;
				where.z = 0;
				drawpic(where, vCROSS_DROP, tmpSize, '0 1 0', autocvar_crosshair_alpha * 0.9, DRAWFLAG_ADDITIVE);
				drawpic(where, vCROSS_DROP, tmpSize, '0 1 0', autocvar_crosshair_alpha * 0.6, DRAWFLAG_NORMAL); // Ensure visibility against bright bg
			}
			dropmark.cnt = time + 5;
		}
		else
		{
			if(dropmark.cnt > time)
			{
				where = project_3d_to_2d(dropmark.origin);
				tmpSize = draw_getimagesize(vCROSS_DROP) * autocvar_cl_vehicles_crosshair_size * 1.25;

				if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
				{
					where.x -= tmpSize.x * 0.5;
					where.y -= tmpSize.y * 0.5;
					where.z = 0;
					drawpic(where, vCROSS_DROP, tmpSize, '1 0 0', autocvar_crosshair_alpha * 0.9, DRAWFLAG_ADDITIVE);
					drawpic(where, vCROSS_DROP, tmpSize, '1 0 0', autocvar_crosshair_alpha * 0.6, DRAWFLAG_NORMAL); // Ensure visibility against bright bg
				}
			}
		}
	}

	// Crosshair
	if(crosshair)
	{
		tmpSize  = draw_getimagesize(crosshair) * autocvar_cl_vehicles_crosshair_size;
		tmpPos.x = (vid_conwidth - tmpSize.x) / 2;
		tmpPos.y = (vid_conheight - tmpSize.y) / 2;

		drawpic(tmpPos, crosshair, tmpSize, '1 1 1', autocvar_crosshair_alpha, DRAWFLAG_NORMAL);
	}
}
