#include "cl_vehicles.qh"

void vehicle_alarm(entity e, int ch, Sound s0und)
{
	TC(Sound, s0und);
	if(!autocvar_cl_vehicles_alarm)
		return;

	sound(e, ch, s0und, VOL_BASEVOICE, ATTEN_NONE);
}

void AuxiliaryXhair_Draw2D(entity this)
{
	if (scoreboard_active)
		return;

	vector pos = project_3d_to_2d(this.origin);

	if (!(pos.z < 0 || pos.x < 0 || pos.y < 0 || pos.x > vid_conwidth || pos.y > vid_conheight))
	{
		vector size = draw_getimagesize(this.axh_image) * autocvar_cl_vehicles_crosshair_size;
		pos.x -= 0.5 * size.x;
		pos.y -= 0.5 * size.y;
		pos.z = 0;
		drawpic(pos, this.axh_image, size, this.colormod, autocvar_crosshair_alpha * this.alpha, this.axh_drawflag);
	}

	if(time - this.cnt > this.axh_fadetime)
		this.draw2d = func_null;
}

NET_HANDLE(ENT_CLIENT_AUXILIARYXHAIR, bool isnew)
{
	int sf = ReadByte();

	int axh_id	= bound(0, ReadByte(), MAX_AXH);
	entity axh = AuxiliaryXhair[axh_id];

	if(axh == NULL || wasfreed(axh))
	{
		axh					= new(auxiliary_crosshair);
		axh.draw2d			= func_null;
		axh.drawmask 		= MASK_NORMAL;
		axh.axh_drawflag	= DRAWFLAG_ADDITIVE;
		axh.axh_fadetime	= 0.1;
		axh.axh_image		= vCROSS_HINT;
		axh.alpha			= 1;
		AuxiliaryXhair[axh_id] = axh;
		IL_PUSH(g_drawables_2d, axh);
	}

	if(sf & 2)
	{
		axh.origin = ReadVector();
	}

	if(sf & 4)
	{
		axh.colormod_x = ReadByte() / 255;
		axh.colormod_y = ReadByte() / 255;
		axh.colormod_z = ReadByte() / 255;
	}

	axh.cnt 			= time;
	axh.draw2d			= AuxiliaryXhair_Draw2D;
	return true;
}

NET_HANDLE(TE_CSQC_VEHICLESETUP, bool isnew)
{
	int hud_id = ReadByte();
	return = true;

	// hud_id == 0 means we exited a vehicle, so stop alarm sound/s
	// note: HUD_NORMAL is set to 0 currently too, but we'll check both just in case
	if(hud_id == 0 || hud_id == HUD_NORMAL)
	{
		sound(this, CH_TRIGGER_SINGLE, SND_Null, VOL_BASEVOICE, ATTEN_NONE);
		sound(this, CH_PAIN_SINGLE, SND_Null, VOL_BASEVOICE, ATTEN_NONE);

		for(int i = 0; i < MAX_AXH; ++i)
		{
			entity axh = AuxiliaryXhair[i];

			if(axh != NULL && !wasfreed(axh))
			{
				AuxiliaryXhair[i] = NULL;
				delete(axh);
			}
		}
		return;
	}

	// Init auxiliary crosshairs
	for(int i = 0; i < MAX_AXH; ++i)
	{
		entity axh = AuxiliaryXhair[i];

		if(axh != NULL && !wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
			delete(axh);

		axh              = new(AuxiliaryXhair);
		axh.draw2d       = func_null;
		axh.drawmask     = MASK_NORMAL;
		axh.axh_drawflag = DRAWFLAG_NORMAL;
		axh.axh_fadetime = 0.1;
		axh.axh_image    = vCROSS_HINT;
		axh.alpha        = 1;
		AuxiliaryXhair[i] = axh;
		IL_PUSH(g_drawables_2d, axh);
	}

	if(hud_id == HUD_BUMBLEBEE_GUN)
	{
		AuxiliaryXhair[0].axh_image = vCROSS_BURST; // Plasma cannons
		AuxiliaryXhair[1].axh_image = vCROSS_BURST; // Raygun
	} else {
		Vehicle info = REGISTRY_GET(Vehicles, hud_id);
    	info.vr_setup(info, NULL);
	}
}

void Vehicles_drawHUD(
	string vehicle,
	string vehicleWeapon1,
	string vehicleWeapon2,
	string iconAmmo1,
	vector colorAmmo1,
	string iconAmmo2,
	vector colorAmmo2)
{
	// Initialize
	vector tmpSize = '0 0 0';
	vector tmpPos  = '0 0 0';

	float hudAlpha = autocvar_hud_panel_fg_alpha * hud_fade_alpha;
	float barAlpha = autocvar_hud_progressbar_alpha * hudAlpha;
	float blinkValue = 0.55 + sin(time * 7) * 0.45;

	float health  = STAT(VEHICLESTAT_HEALTH)  * 0.01;
	float shield  = STAT(VEHICLESTAT_SHIELD)  * 0.01;
	float energy  = STAT(VEHICLESTAT_ENERGY)  * 0.01;
	float ammo1   = STAT(VEHICLESTAT_AMMO1)   * 0.01;
	float reload1 = STAT(VEHICLESTAT_RELOAD1) * 0.01;
	float ammo2   = STAT(VEHICLESTAT_AMMO2)   * 0.01;
	float reload2 = STAT(VEHICLESTAT_RELOAD2) * 0.01;

	// HACK to deal with the inconsistent use of the vehicle stats
	ammo1 = (ammo1) ? ammo1 : energy;

	// Frame
	string frame = strcat(hud_skin_path, "/vehicle_frame");
	if (precache_pic(frame) == "")
		frame = "gfx/hud/default/vehicle_frame";

	vehicleHud_Size  = draw_getimagesize(frame) * autocvar_cl_vehicles_hudscale;
	vehicleHud_Pos.x = (vid_conwidth - vehicleHud_Size.x) / 2;
	vehicleHud_Pos.y = vid_conheight - vehicleHud_Size.y;

	if(teamplay && autocvar_hud_panel_bg_color_team)
		drawpic(vehicleHud_Pos, frame, vehicleHud_Size, myteamcolors * autocvar_hud_panel_bg_color_team, autocvar_hud_panel_bg_alpha * hud_fade_alpha, DRAWFLAG_NORMAL);
	else
		drawpic(vehicleHud_Pos, frame, vehicleHud_Size, autocvar_hud_panel_bg_color, autocvar_hud_panel_bg_alpha * hud_fade_alpha, DRAWFLAG_NORMAL);

	if(!autocvar__vehicles_shownchasemessage && time < vh_notice_time)
	{
		float tmpblinkValue = 0.55 + sin(time * 3) * 0.45;
		tmpPos.x = vehicleHud_Pos.x + vehicleHud_Size.x * (96/256) - tmpSize.x;
		tmpPos.y = vehicleHud_Pos.y;
		tmpSize = '1 1 1' * hud_fontsize;
		drawstring(tmpPos, sprintf(_("Press %s"), getcommandkey(_("drop weapon"), "dropweapon")), tmpSize, '1 0 0' + '0 1 1' * tmpblinkValue, hudAlpha, DRAWFLAG_NORMAL);
	}

	// Model
	tmpSize.x = vehicleHud_Size.x / 3;
	tmpSize.y = vehicleHud_Size.y;
	tmpPos.x  = vehicleHud_Pos.x + vehicleHud_Size.x / 3;
	tmpPos.y  = vehicleHud_Pos.y;

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
	tmpSize.y = vehicleHud_Size.y / 2;
	tmpPos.x  = vehicleHud_Pos.x + vehicleHud_Size.x * (32/768);
	tmpPos.y  = vehicleHud_Pos.y;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - health)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic_skin(tmpPos, "vehicle_bar_northwest", tmpSize, autocvar_hud_progressbar_health_color, barAlpha, DRAWFLAG_NORMAL);

	// Shield bar
	tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y / 2;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - shield)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic_skin(tmpPos, "vehicle_bar_southwest", tmpSize, autocvar_hud_progressbar_armor_color, barAlpha, DRAWFLAG_NORMAL);

	// Ammo1 bar
	tmpPos.x = vehicleHud_Pos.x + vehicleHud_Size.x * (480/768);
	tmpPos.y = vehicleHud_Pos.y;

	if(ammo1)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo1, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload1, tmpSize.y);

	drawpic_skin(tmpPos, "vehicle_bar_northeast", tmpSize, colorAmmo1, barAlpha, DRAWFLAG_NORMAL);

	// Ammo2 bar
	tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y / 2;

	if(ammo2)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo2, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload2, tmpSize.y);

	drawpic_skin(tmpPos, "vehicle_bar_southeast", tmpSize, colorAmmo2, barAlpha, DRAWFLAG_NORMAL);
	drawresetcliparea();

	// Health icon
	tmpSize.x = vehicleHud_Size.x * (80/768);
	tmpSize.y = vehicleHud_Size.y * (80/256);
	tmpPos.x  = vehicleHud_Pos.x + vehicleHud_Size.x * (64/768);
	tmpPos.y  = vehicleHud_Pos.y + vehicleHud_Size.y * (48/256);

	if(health < 0.25)
	{
		if(alarm1time < time)
		{
			alarm1time = time + 2;
			vehicle_alarm(NULL, CH_PAIN_SINGLE, SND_VEH_ALARM);
		}
		drawpic_skin(tmpPos, "vehicle_icon_health", tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm1time)
		{
			vehicle_alarm(NULL, CH_PAIN_SINGLE, SND_Null);
			alarm1time = 0;
		}
		drawpic_skin(tmpPos, "vehicle_icon_health", tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Shield icon
	tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y / 2;

	if(shield < 0.25)
	{
		if(alarm2time < time)
		{
			alarm2time = time + 1;
			vehicle_alarm(NULL, CH_TRIGGER_SINGLE, SND_VEH_ALARM_SHIELD);
		}
		drawpic_skin(tmpPos, "vehicle_icon_shield", tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm2time)
		{
			vehicle_alarm(NULL, CH_TRIGGER_SINGLE, SND_Null);
			alarm2time = 0;
		}
		drawpic_skin(tmpPos, "vehicle_icon_shield", tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Ammo1 icon
	tmpPos.x = vehicleHud_Pos.x + vehicleHud_Size.x * (624/768);
	tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y * (48/256);

	if(iconAmmo1)
	{
		if(ammo1)
			drawpic_skin(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
		else
			drawpic_skin(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);
	}

	// Ammo2 icon
	tmpPos.y = vehicleHud_Pos.y + vehicleHud_Size.y / 2;

	if(iconAmmo2)
	{
		if(ammo2)
			drawpic_skin(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
		else
			drawpic_skin(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);
	}
}

void Vehicles_drawCrosshair(string crosshair)
{
	vector tmpSize = '0 0 0';
	vector tmpPos  = '0 0 0';

	// Crosshair
	if(crosshair)
	{
		tmpSize  = draw_getimagesize(crosshair) * autocvar_cl_vehicles_crosshair_size;
		tmpPos.x = (vid_conwidth - tmpSize.x) / 2;
		tmpPos.y = (vid_conheight - tmpSize.y) / 2;

		vector wcross_color = '1 1 1';
		if(autocvar_cl_vehicles_crosshair_colorize)
			wcross_color = crosshair_getcolor(NULL, STAT(VEHICLESTAT_HEALTH));

		drawpic(tmpPos, crosshair, tmpSize, wcross_color, autocvar_crosshair_alpha, DRAWFLAG_NORMAL);
	}
}
