#include "all.qh"
#include "../_all.qh"

#include "../movetypes.qh"
#include "../movetypes.qh"
#include "../prandom.qh"
#include "../scoreboard.qh"
#include "../t_items.qh"

#include "../../common/buffs.qh"
#include "../../common/constants.qh"
#include "../../common/stats.qh"
#include "../../common/util.qh"

#include "../../csqcmodellib/cl_model.qh"

.float cnt;

const string vNULL  = "gfx/vehicles/null.tga";
const string vFRAME = "gfx/vehicles/frame.tga";

const string vMODEL_SHIELD         = "gfx/vehicles/vh-shield.tga";
const string vMODEL_BUMBLE         = "gfx/vehicles/bumb.tga";
const string vMODEL_BUMBLE_WEAPON1 = "gfx/vehicles/bumb_lgun.tga";
const string vMODEL_BUMBLE_WEAPON2 = "gfx/vehicles/bumb_rgun.tga";
const string vMODEL_GUNNER         = "gfx/vehicles/bumb_side.tga";
const string vMODEL_GUNNER_WEAPON1 = "gfx/vehicles/bumb_side_gun.tga";
const string vMODEL_RAPTOR         = "gfx/vehicles/raptor.tga";
const string vMODEL_RAPTOR_WEAPON1 = "gfx/vehicles/raptor_guns.tga";
const string vMODEL_RAPTOR_WEAPON2 = "gfx/vehicles/raptor_bombs.tga";
const string vMODEL_SPIDER         = "gfx/vehicles/sbot.tga";
const string vMODEL_SPIDER_WEAPON1 = "gfx/vehicles/sbot_mguns.tga";
const string vMODEL_SPIDER_WEAPON2 = "gfx/vehicles/sbot_rpods.tga";
const string vMODEL_RACER          = "gfx/vehicles/waki.tga";
const string vMODEL_RACER_WEAPON1  = "gfx/vehicles/waki_guns.tga";
const string vMODEL_RACER_WEAPON2  = "gfx/vehicles/waki_rockets.tga";

const string vBAR_HEALTH = "gfx/vehicles/bar_up_left.tga";
const string vBAR_SHIELD = "gfx/vehicles/bar_dwn_left.tga";
const string vBAR_AMMO1  = "gfx/vehicles/bar_up_right.tga";
const string vBAR_AMMO2  = "gfx/vehicles/bar_dwn_right.tga";

const string vICON_HEALTH = "gfx/vehicles/health.tga";
const string vICON_SHIELD = "gfx/vehicles/shield.tga";
const string vICON_AMMO1  = "gfx/vehicles/bullets.tga";
const string vICON_AMMO2  = "gfx/vehicles/rocket.tga";

const string vCROSS_AIM  = "gfx/vehicles/axh-special1.tga";
const string vCROSS_DROP = "gfx/vehicles/axh-dropcross.tga";
const string vCROSS_HEAL = "gfx/vehicles/axh-cross.tga";
const string vCROSS_HINT = "gfx/vehicles/axh-ring.tga";
const string vCROSS_LOCK = "gfx/vehicles/axh-bracket.tga";
const string vCROSS_TAG  = "gfx/vehicles/axh-tag.tga";

const int SBRM_FIRST     = 1;
const int SBRM_VOLLY     = 1;
const int SBRM_GUIDE     = 2;
const int SBRM_ARTILLERY = 3;
const int SBRM_LAST      = 3;

const int RSM_FIRST = 1;
const int RSM_BOMB  = 1;
const int RSM_FLARE = 2;
const int RSM_LAST  = 2;

const int MAX_AXH = 4;
entity AuxiliaryXhairs[MAX_AXH];
entityclass(AuxiliaryXhair);
class(AuxiliaryXhair) .string axh_image;
class(AuxiliaryXhair) .float  axh_fadetime;
class(AuxiliaryXhair) .float  axh_drawflag;

entity dropmark;

float alarm1time;
float alarm2time;
int weapon2mode;


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
	int axh_id = bound(0, ReadByte(), MAX_AXH);
	entity axh = AuxiliaryXhairs[axh_id];

	if(axh == world || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
	{
		axh              = spawn();
		axh.draw2d       = func_null;
		axh.drawmask     = MASK_NORMAL;
		axh.axh_drawflag = DRAWFLAG_ADDITIVE;
		axh.axh_fadetime = 0.1;
		axh.axh_image    = vCROSS_HINT;
		axh.alpha        = 1;

		AuxiliaryXhairs[axh_id] = axh;
	}

	axh.move_origin_x = ReadCoord();
	axh.move_origin_y = ReadCoord();
	axh.move_origin_z = ReadCoord();
	axh.colormod_x = ReadByte() / 255;
	axh.colormod_y = ReadByte() / 255;
	axh.colormod_z = ReadByte() / 255;
	axh.cnt    = time;
	axh.draw2d = AuxiliaryXhair_Draw2D;
}

void Net_VehicleSetup()
{
	int hud_id = ReadByte();

	// Weapon update?
	if(hud_id > HUD_VEHICLE_LAST)
	{
		weapon2mode = hud_id - HUD_VEHICLE_LAST;
		return;
	}

	// hud_id == 0 means we exited a vehicle, so stop alarm sound/s
	if(hud_id == 0)
	{
		sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
		sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
		return;
	}

	hud_id  = bound(HUD_VEHICLE_FIRST, hud_id, HUD_VEHICLE_LAST);

	// Init auxiliary crosshairs
	int i;
	for(i = 0; i < MAX_AXH; ++i)
	{
		entity axh = AuxiliaryXhairs[i];

		if(axh != world && !wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
			remove(axh);

		axh              = spawn();
		axh.draw2d       = func_null;
		axh.drawmask     = MASK_NORMAL;
		axh.axh_drawflag = DRAWFLAG_NORMAL;
		axh.axh_fadetime = 0.1;
		axh.axh_image    = vCROSS_HINT;
		axh.alpha        = 1;
		AuxiliaryXhairs[i] = axh;
	}

	switch(hud_id)
	{
		case HUD_SPIDERBOT:
			AuxiliaryXhairs[0].axh_image = vCROSS_HINT; // Minigun1
			AuxiliaryXhairs[1].axh_image = vCROSS_HINT; // Minigun2
			break;

		case HUD_WAKIZASHI:
			AuxiliaryXhairs[0].axh_image = vCROSS_LOCK; // Rocket
			break;

		case HUD_RAPTOR:
			AuxiliaryXhairs[1].axh_image = vCROSS_LOCK;
			break;

		case HUD_BUMBLEBEE:
			AuxiliaryXhairs[0].axh_image = vCROSS_LOCK; // Raygun-locked
			AuxiliaryXhairs[1].axh_image = vCROSS_TAG; // Gunner1
			AuxiliaryXhairs[2].axh_image = vCROSS_TAG; // Gunner2
			break;

		case HUD_BUMBLEBEE_GUN:
			AuxiliaryXhairs[0].axh_image = vCROSS_TAG; // Plasma cannons
			AuxiliaryXhairs[1].axh_image = vCROSS_TAG; // Raygun
			break;
	}
}

void Vehicles_drawHUD(
	string modelBase,
	string modelWeapon1,
	string modelWeapon2,
	string iconAmmo1,
	vector colorAmmo1,
	string iconAmmo2,
	vector colorAmmo2,
	string crosshair,
	bool shouldDrawBumbleGunnerCrosshair,
	bool shouldDrawRaptorBombCrosshair)
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

	// HACK to deal with the inconcistent use of the vehicle stats
	ammo1 = (ammo1) ? ammo1 : energy;

	// Frame
	hudSize  = draw_getimagesize(vFRAME) * autocvar_cl_vehicles_hudscale;
	hudPos.x = (vid_conwidth - hudSize.x) / 2;
	hudPos.y = vid_conheight - hudSize.y;

	if(teamplay && autocvar_hud_panel_bg_color_team)
		drawpic(hudPos, vFRAME, hudSize, myteamcolors * autocvar_hud_panel_bg_color_team, autocvar_hud_panel_bg_alpha, DRAWFLAG_NORMAL);
	else
		drawpic(hudPos, vFRAME, hudSize, autocvar_hud_panel_bg_color, autocvar_hud_panel_bg_alpha, DRAWFLAG_NORMAL);

	// Model
	tmpSize.x = hudSize.x / 3;
	tmpSize.y = hudSize.y;
	tmpPos.x  = hudPos.x + hudSize.x / 3;
	tmpPos.y  = hudPos.y;

	if(health < 0.25)
		drawpic(tmpPos, modelBase, tmpSize, '1 0 0' + '0 1 1' * blinkValue, hudAlpha, DRAWFLAG_NORMAL);
	else
		drawpic(tmpPos, modelBase, tmpSize, '1 1 1' * health  + '1 0 0' * (1 - health), hudAlpha, DRAWFLAG_NORMAL);

	drawpic(tmpPos, modelWeapon1, tmpSize, '1 1 1' * ammo1 + '1 0 0' * (1 - ammo1), hudAlpha, DRAWFLAG_NORMAL);
	drawpic(tmpPos, modelWeapon2, tmpSize, '1 1 1' * ammo2 + '1 0 0' * (1 - ammo2), hudAlpha, DRAWFLAG_NORMAL);
	drawpic(tmpPos, vMODEL_SHIELD, tmpSize, '1 1 1' * shield + '1 0 0' * (1 - shield), hudAlpha * shield, DRAWFLAG_NORMAL);

	// Health bar
	tmpSize.y = hudSize.y / 2;
	tmpPos.x  = hudPos.x + hudSize.x * (32/768);
	tmpPos.y  = hudPos.y;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - health)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic(tmpPos, vBAR_HEALTH, tmpSize, autocvar_hud_progressbar_health_color, barAlpha, DRAWFLAG_NORMAL);

	// Shield bar
	tmpPos.y = hudPos.y + hudSize.y / 2;

	drawsetcliparea(tmpPos.x + (tmpSize.x * (1 - shield)), tmpPos.y, tmpSize.x, tmpSize.y);
	drawpic(tmpPos, vBAR_SHIELD, tmpSize, autocvar_hud_progressbar_armor_color, barAlpha, DRAWFLAG_NORMAL);

	// Ammo1 bar
	tmpPos.x = hudPos.x + hudSize.x * (480/768);
	tmpPos.y = hudPos.y;

	if(ammo1)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo1, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload1, tmpSize.y);

	drawpic(tmpPos, vBAR_AMMO1, tmpSize, colorAmmo1, barAlpha, DRAWFLAG_NORMAL);

	// Ammo2 bar
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(ammo2)
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * ammo2, tmpSize.y);
	else
		drawsetcliparea(tmpPos.x, tmpPos.y, tmpSize.x * reload2, tmpSize.y);

	drawpic(tmpPos, vBAR_AMMO2, tmpSize, colorAmmo2, barAlpha, DRAWFLAG_NORMAL);
	drawresetcliparea();

	// Health icon
	tmpSize.x = hudSize.x * (80/768);
	tmpSize.y = hudSize.y * (80/256);
	tmpPos.x  = hudPos.x + hudSize.x * (56/768);
	tmpPos.y  = hudPos.y + hudSize.y * (48/256);

	if(health < 0.25)
	{
		if(alarm1time < time)
		{
			alarm1time = time + 2;
			sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
		}
		drawpic(tmpPos, vICON_HEALTH, tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm1time)
		{
			sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
			alarm1time = 0;
		}
		drawpic(tmpPos, vICON_HEALTH, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Shield icon
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(shield < 0.25)
	{
		if(alarm2time < time)
		{
			alarm2time = time + 1;
			sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
		}
		drawpic(tmpPos, vICON_SHIELD, tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
	}
	else
	{
		if(alarm2time)
		{
			sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
			alarm2time = 0;
		}
		drawpic(tmpPos, vICON_SHIELD, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	}

	// Ammo1 icon
	tmpPos.x = hudPos.x + hudSize.x * (632/768);
	tmpPos.y = hudPos.y + hudSize.y * (48/256);

	if(ammo1)
		drawpic(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	else
		drawpic(tmpPos, iconAmmo1, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);

	// Ammo2 icon
	tmpPos.y = hudPos.y + hudSize.y / 2;

	if(ammo2)
		drawpic(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha, DRAWFLAG_NORMAL);
	else
		drawpic(tmpPos, iconAmmo2, tmpSize, '1 1 1', hudAlpha * 0.2, DRAWFLAG_NORMAL);

	// Bumblebee gunner crosshairs
	if(shouldDrawBumbleGunnerCrosshair)
	{
		tmpSize = '1 1 1' * hud_fontsize;
		tmpPos.x = hudPos.x + hudSize.x * (520/768);

		if(!AuxiliaryXhairs[1].draw2d)
		{
			tmpPos.y = hudPos.y + hudSize.y * (96/256) - tmpSize.y;
			drawstring(tmpPos, _("No right gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
		}

		if(!AuxiliaryXhairs[2].draw2d)
		{
			tmpPos.y = hudPos.y + hudSize.y * (160/256);
			drawstring(tmpPos, _("No left gunner!"), tmpSize, '1 1 1', hudAlpha * blinkValue, DRAWFLAG_NORMAL);
		}
	}

	// Raptor bomb crosshair
	if(shouldDrawRaptorBombCrosshair && weapon2mode != RSM_FLARE)
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
	tmpSize  = draw_getimagesize(crosshair) * autocvar_cl_vehicles_crosshair_size;
	tmpPos.x = (vid_conwidth - tmpSize.x) / 2;
	tmpPos.y = (vid_conheight - tmpSize.y) / 2;

	drawpic(tmpPos, crosshair, tmpSize, '1 1 1', autocvar_crosshair_alpha, DRAWFLAG_NORMAL);
}

void CSQC_BUMBLE_HUD()
{
	Vehicles_drawHUD(vMODEL_BUMBLE, vMODEL_BUMBLE_WEAPON1, vMODEL_BUMBLE_WEAPON2,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vCROSS_HEAL, TRUE, FALSE);
}

void CSQC_BUMBLE_GUN_HUD()
{
	Vehicles_drawHUD(vMODEL_GUNNER, vMODEL_GUNNER_WEAPON1, vNULL,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vNULL, '0 0 0',
		vNULL, FALSE, FALSE);
}

void CSQC_SPIDER_HUD()
{
	string crosshair;

	switch(weapon2mode)
	{
		case SBRM_VOLLY: crosshair = vCROSS_LOCK; break;
		case SBRM_GUIDE: crosshair = vCROSS_AIM;  break;
		default:         crosshair = vCROSS_TAG;
	}

	Vehicles_drawHUD(vMODEL_SPIDER, vMODEL_SPIDER_WEAPON1, vMODEL_SPIDER_WEAPON2,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vICON_AMMO2, autocvar_hud_progressbar_vehicles_ammo2_color,
		crosshair, FALSE, FALSE);
}

void CSQC_RAPTOR_HUD()
{
	string crosshair;

	switch(weapon2mode)
	{
		case RSM_FLARE: crosshair = vCROSS_LOCK; break;
		default:        crosshair = vCROSS_AIM;
	}

	Vehicles_drawHUD(vMODEL_RAPTOR, vMODEL_RAPTOR_WEAPON1, vMODEL_RAPTOR_WEAPON2,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vICON_AMMO2, autocvar_hud_progressbar_vehicles_ammo2_color,
		crosshair, FALSE, TRUE);
}

void CSQC_WAKIZASHI_HUD()
{
	Vehicles_drawHUD(vMODEL_RACER, vMODEL_RACER_WEAPON1, vMODEL_RACER_WEAPON2,
		vICON_AMMO1, autocvar_hud_progressbar_vehicles_ammo1_color,
		vICON_AMMO2, autocvar_hud_progressbar_vehicles_ammo2_color,
		vCROSS_AIM, FALSE, FALSE);
}

void Vehicles_Precache()
{
	precache_model("models/vehicles/bomblet.md3");
	precache_model("models/vehicles/clusterbomb.md3");
	precache_model("models/vehicles/clusterbomb_fragment.md3");
	precache_model("models/vehicles/rocket01.md3");
	precache_model("models/vehicles/rocket02.md3");

	precache_sound("vehicles/alarm.wav");
	precache_sound("vehicles/alarm_shield.wav");
}

void RaptorCBShellfragDraw()
{
	if(wasfreed(self))
		return;

	Movetype_Physics_MatchTicrate(autocvar_cl_gibs_ticrate, autocvar_cl_gibs_sloppy);
	self.move_avelocity += randomvec() * 15;
	self.renderflags = 0;

	if(self.cnt < time)
		self.alpha = bound(0, self.nextthink - time, 1);

	if(self.alpha < ALPHA_MIN_VISIBLE)
		remove(self);
}

void RaptorCBShellfragToss(vector _org, vector _vel, vector _ang)
{
	entity sfrag;

	sfrag = spawn();
	setmodel(sfrag, "models/vehicles/clusterbomb_fragment.md3");
	setorigin(sfrag, _org);

	sfrag.move_movetype = MOVETYPE_BOUNCE;
	sfrag.gravity = 0.15;
	sfrag.solid = SOLID_CORPSE;

	sfrag.draw = RaptorCBShellfragDraw;

	sfrag.move_origin = sfrag.origin = _org;
	sfrag.move_velocity = _vel;
	sfrag.move_avelocity = prandomvec() * vlen(sfrag.move_velocity);
	sfrag.angles = self.move_angles = _ang;

	sfrag.move_time = time;
	sfrag.damageforcescale = 4;

	sfrag.nextthink = time + 3;
	sfrag.cnt = time + 2;
	sfrag.alpha = 1;
	sfrag.drawmask = MASK_NORMAL;
}
