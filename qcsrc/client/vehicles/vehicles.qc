#include "vehicles.qh"
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

const string hud_bg = "gfx/vehicles/frame.tga";
const string hud_sh = "gfx/vehicles/vh-shield.tga";

const string hud_hp_bar = "gfx/vehicles/bar_up_left.tga";
const string hud_hp_ico = "gfx/vehicles/health.tga";
const string hud_sh_bar = "gfx/vehicles/bar_dwn_left.tga";
const string hud_sh_ico = "gfx/vehicles/shield.tga";

const string hud_ammo1_bar = "gfx/vehicles/bar_up_right.tga";
const string hud_ammo1_ico = "gfx/vehicles/bullets.tga";
const string hud_ammo2_bar = "gfx/vehicles/bar_dwn_right.tga";
const string hud_ammo2_ico = "gfx/vehicles/rocket.tga";
const string hud_energy = "gfx/vehicles/energy.tga";

const int SBRM_FIRST = 1;
const int SBRM_VOLLY = 1;
const int SBRM_GUIDE = 2;
const int SBRM_ARTILLERY = 3;
const int SBRM_LAST = 3;

const int RSM_FIRST = 1;
const int RSM_BOMB = 1;
const int RSM_FLARE = 2;
const int RSM_LAST = 2;

entity dropmark;
float autocvar_cl_vehicles_hudscale = 0.5;
float autocvar_cl_vehicles_hudalpha = 0.75;

const string raptor_ico =  "gfx/vehicles/raptor.tga";
const string raptor_gun =  "gfx/vehicles/raptor_guns.tga";
const string raptor_bomb = "gfx/vehicles/raptor_bombs.tga";
const string raptor_drop = "gfx/vehicles/axh-dropcross.tga";
string raptor_xhair;



const int MAX_AXH = 4;
entity AuxiliaryXhairs[MAX_AXH];

entityclass(AuxiliaryXhair);
class(AuxiliaryXhair) .string axh_image;
class(AuxiliaryXhair) .float  axh_fadetime;
class(AuxiliaryXhair) .float  axh_drawflag;
class(AuxiliaryXhair) .float  axh_scale;

const string bumb_ico =  "gfx/vehicles/bumb.tga";
const string bumb_lgun =  "gfx/vehicles/bumb_lgun.tga";
const string bumb_rgun =  "gfx/vehicles/bumb_rgun.tga";

const string bumb_gun_ico =  "gfx/vehicles/bumb_side.tga";
const string bumb_gun_gun =  "gfx/vehicles/bumb_side_gun.tga";

const string spider_ico =  "gfx/vehicles/sbot.tga";
const string spider_rkt =  "gfx/vehicles/sbot_rpods.tga";
const string spider_mgun = "gfx/vehicles/sbot_mguns.tga";
string spider_xhair; // = "gfx/vehicles/axh-special1.tga";

const string waki_ico = "gfx/vehicles/waki.tga";
const string waki_eng = "gfx/vehicles/waki_e.tga";
const string waki_gun = "gfx/vehicles/waki_guns.tga";
const string waki_rkt = "gfx/vehicles/waki_rockets.tga";
const string waki_xhair = "gfx/vehicles/axh-special1.tga";

float alarm1time;
float alarm2time;
int weapon2mode;

void AuxiliaryXhair_Draw2D()
{
    vector loc, psize;

    psize = self.axh_scale * draw_getimagesize(self.axh_image);
    loc = project_3d_to_2d(self.move_origin) - 0.5 * psize;
    if (!(loc.z < 0 || loc.x < 0 || loc.y < 0 || loc.x > vid_conwidth || loc.y > vid_conheight))
    {
        loc.z = 0;
        psize.z = 0;
        drawpic(loc, self.axh_image, psize, self.colormod, self.alpha, self.axh_drawflag);
    }

    if(time - self.cnt > self.axh_fadetime)
        self.draw2d = func_null;
}

void Net_AuXair2(bool bIsNew)
{
    int axh_id	= bound(0, ReadByte(), MAX_AXH);
    entity axh 		= AuxiliaryXhairs[axh_id];

    if(axh == world || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
    {
        axh					= spawn();
		axh.draw2d			= func_null;
		axh.drawmask 		= MASK_NORMAL;
		axh.axh_drawflag	= DRAWFLAG_ADDITIVE;
		axh.axh_fadetime	= 0.1;
		axh.axh_image		= "gfx/vehicles/axh-ring.tga";
		axh.axh_scale		= 1;
        axh.alpha			= 1;
		AuxiliaryXhairs[axh_id] = axh;
    }

	axh.move_origin_x = ReadCoord();
	axh.move_origin_y = ReadCoord();
	axh.move_origin_z = ReadCoord();
	axh.colormod_x = ReadByte() / 255;
	axh.colormod_y = ReadByte() / 255;
	axh.colormod_z = ReadByte() / 255;
    axh.cnt 			= time;
    axh.draw2d			= AuxiliaryXhair_Draw2D;
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

        axh					= spawn();
		axh.draw2d			= func_null;
		axh.drawmask		= MASK_NORMAL;
		axh.axh_drawflag	= DRAWFLAG_NORMAL;
		axh.axh_fadetime	= 0.1;
		axh.axh_image		= "gfx/vehicles/axh-ring.tga";
		axh.axh_scale		= 1;
        axh.alpha			= 1;
		AuxiliaryXhairs[i]	= axh;
    }

    switch(hud_id)
    {
        case HUD_SPIDERBOT:
            // Minigun1
            AuxiliaryXhairs[0].axh_image   = "gfx/vehicles/axh-ring.tga";
            AuxiliaryXhairs[0].axh_scale   = 0.25;
            // Minigun2
            AuxiliaryXhairs[1].axh_image   = "gfx/vehicles/axh-ring.tga";
            AuxiliaryXhairs[1].axh_scale   = 0.25;
            // Rocket
            AuxiliaryXhairs[2].axh_image   = "gfx/vehicles/axh-special1.tga";
            AuxiliaryXhairs[2].axh_scale   = 0.5;
            break;

        case HUD_WAKIZASHI:
            AuxiliaryXhairs[0].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhairs[0].axh_scale   = 0.25;
            break;

        case HUD_RAPTOR:
            AuxiliaryXhairs[0].axh_image   = "gfx/vehicles/axh-special2.tga";
            AuxiliaryXhairs[0].axh_scale   = 0.5;
            //AuxiliaryXhair[0].alpha       = 0.5;

            AuxiliaryXhairs[1].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhairs[1].axh_scale   = 0.25;
            //AuxiliaryXhair[1].alpha       = 0.75;
            //AuxiliaryXhair[1].axh_drawflag  = DRAWFLAG_NORMAL;
            break;

        case HUD_BUMBLEBEE:
            // Raygun-locked
            AuxiliaryXhairs[0].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhairs[0].axh_scale   = 0.5;

            // Gunner1
            AuxiliaryXhairs[1].axh_image   = "gfx/vehicles/axh-target.tga";
            AuxiliaryXhairs[1].axh_scale   = 0.75;

            // Gunner2
            AuxiliaryXhairs[2].axh_image   = "gfx/vehicles/axh-target.tga";
            AuxiliaryXhairs[2].axh_scale   = 0.75;
            break;
        case HUD_BUMBLEBEE_GUN:
            // Plasma cannons
            AuxiliaryXhairs[0].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhairs[0].axh_scale   = 0.25;
            // Raygun
            AuxiliaryXhairs[1].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhairs[1].axh_scale   = 0.25;
            break;
    }
}
#define HUD_GETSTATS \
    int vh_health       = getstati(STAT_VEHICLESTAT_HEALTH);  \
	float shield        = getstati(STAT_VEHICLESTAT_SHIELD);  \
	noref int energy    = getstati(STAT_VEHICLESTAT_ENERGY);  \
	noref float ammo1   = getstati(STAT_VEHICLESTAT_AMMO1);   \
	noref float reload1 = getstati(STAT_VEHICLESTAT_RELOAD1); \
	noref int ammo2     = getstati(STAT_VEHICLESTAT_AMMO2);   \
	noref int reload2   = getstati(STAT_VEHICLESTAT_RELOAD2);

void CSQC_BUMBLE_HUD()
{
/*
    drawpic(hudloc, waki_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_b, picsize, '0 1 0' * health + '1 0 0'  * (1 - health), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_r, picsize, '1 1 1' * reload1 + '1 0 0' * (1 - reload1), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_e, picsize, '1 1 1' * energy + '1 0 0'  * (1 - energy), 1, DRAWFLAG_NORMAL);
*/
	if(autocvar_r_letterbox)
        return;

    vector picsize, hudloc = '0 0 0', pic2size, picloc;

    // Fetch health & ammo stats
	HUD_GETSTATS

    picsize = draw_getimagesize(hud_bg) * autocvar_cl_vehicles_hudscale;
    hudloc.y = vid_conheight - picsize.y;
    hudloc.x = vid_conwidth * 0.5 - picsize.x * 0.5;

    drawpic(hudloc, hud_bg, picsize, '1 1 1', autocvar_cl_vehicles_hudalpha, DRAWFLAG_NORMAL);

    shield  *= 0.01;
    vh_health  *= 0.01;
    energy  *= 0.01;
    reload1 *= 0.01;

    pic2size = draw_getimagesize(bumb_ico) * (autocvar_cl_vehicles_hudscale * 0.8);
    picloc = picsize * 0.5 - pic2size * 0.5;

    if(vh_health < 0.25)
        drawpic(hudloc + picloc, bumb_ico, pic2size,  '1 0 0' + '0 1 1' * sin(time * 8),  1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, bumb_ico, pic2size,  '1 1 1' * vh_health  + '1 0 0' * (1 - vh_health),  1, DRAWFLAG_NORMAL);

    drawpic(hudloc + picloc, bumb_lgun, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, bumb_lgun, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, hud_sh, pic2size,  '1 1 1', shield, DRAWFLAG_NORMAL);

// Health bar
    picsize = draw_getimagesize(hud_hp_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - vh_health)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_hp_bar, picsize, '1 1 1', 1 , DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_hp_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '37 65 0' * autocvar_cl_vehicles_hudscale;
    if(vh_health < 0.25)
    {
        if(alarm1time < time)
        {
            alarm1time = time + 2;
            sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
        }

        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm1time)
        {
            sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm1time = 0;
        }
    }

// Shield bar
    picsize = draw_getimagesize(hud_sh_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - shield)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_sh_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picloc = '40 136 0' * autocvar_cl_vehicles_hudscale;
    picsize = draw_getimagesize(hud_sh_ico) * autocvar_cl_vehicles_hudscale;
    if(shield < 0.25)
    {
        if(alarm2time < time)
        {
            alarm2time = time + 1;
            sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm2time)
        {
            sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm2time = 0;
        }
    }

	ammo1 *= 0.01;
	ammo2 *= 0.01;

// Gunner1 bar
    picsize = draw_getimagesize(hud_ammo1_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * ammo1, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo1_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();

// Right gunner slot occupied?
	if(!AuxiliaryXhairs[1].draw2d)
	{
		shield = (picsize.x * 0.5) - (0.5 * stringwidth(_("No right gunner!"), false, '1 0 0' * picsize.y + '0 1 0' * picsize.y));
		drawfill(hudloc + picloc - '0.2 0.2 0', picsize + '0.4 0.4 0', '0.25 0.25 0.25', 0.75, DRAWFLAG_NORMAL);
		drawstring(hudloc + picloc + '1 0 0' * shield, _("No right gunner!"), '1 0 0' * picsize.y + '0 1 0' * picsize.y, '1 0 0' + '0 1 1' * sin(time * 10), 1, DRAWFLAG_NORMAL);
	}

// ..  and icon
    picsize = 1.5 * draw_getimagesize(hud_energy) * autocvar_cl_vehicles_hudscale;
    picloc = '664 60 0' * autocvar_cl_vehicles_hudscale;
    if(ammo1 < 0.2)
        drawpic(hudloc + picloc, hud_energy, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_energy, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

// Gunner2 bar
    picsize = draw_getimagesize(hud_ammo2_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * ammo2, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo2_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// Left gunner slot occupied?
	if(!AuxiliaryXhairs[2].draw2d)
	{
		shield = (picsize.x * 0.5) - (0.5 * stringwidth(_("No left gunner!"), false, '1 0 0' * picsize.y + '0 1 0' * picsize.y));
		drawfill(hudloc + picloc - '0.2 0.2 0', picsize + '0.4 0.4 0', '0.25 0.25 0.25', 0.75, DRAWFLAG_NORMAL);
		drawstring(hudloc + picloc + '1 0 0' * shield, _("No left gunner!"), '1 0 0' * picsize.y + '0 1 0' * picsize.y, '1 0 0' + '0 1 1' * sin(time * 10), 1, DRAWFLAG_NORMAL);
	}

// ..  and icon
    picsize = 1.5 * draw_getimagesize(hud_energy) * autocvar_cl_vehicles_hudscale;
    picloc = '664 130 0' * autocvar_cl_vehicles_hudscale;
    if(ammo2 < 0.2)
        drawpic(hudloc + picloc, hud_energy, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_energy, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

	if (scoreboard_showscores)
		HUD_DrawScoreboard();
    else
    {
        picsize = draw_getimagesize(waki_xhair);
        picsize.x *= 0.5;
        picsize.y *= 0.5;
        drawpic('0.5 0 0' * (vid_conwidth - picsize.x) + '0 0.5 0' * (vid_conheight - picsize.y), waki_xhair, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }

}

void CSQC_BUMBLE_GUN_HUD()
{

	if(autocvar_r_letterbox)
        return;

    vector picsize, hudloc = '0 0 0', pic2size, picloc;

    // Fetch health & ammo stats
	HUD_GETSTATS

    picsize = draw_getimagesize(hud_bg) * autocvar_cl_vehicles_hudscale;
    hudloc.y = vid_conheight - picsize.y;
    hudloc.x = vid_conwidth * 0.5 - picsize.x * 0.5;

    drawpic(hudloc, hud_bg, picsize, '1 1 1', autocvar_cl_vehicles_hudalpha, DRAWFLAG_NORMAL);

    shield  *= 0.01;
    vh_health  *= 0.01;
    energy  *= 0.01;
    reload1 *= 0.01;

    pic2size = draw_getimagesize(bumb_gun_ico) * (autocvar_cl_vehicles_hudscale * 0.8);
    picloc = picsize * 0.5 - pic2size * 0.5;

    if(vh_health < 0.25)
        drawpic(hudloc + picloc, bumb_gun_ico, pic2size,  '1 0 0' + '0 1 1' * sin(time * 8),  1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, bumb_gun_ico, pic2size,  '1 1 1' * vh_health  + '1 0 0' * (1 - vh_health),  1, DRAWFLAG_NORMAL);

    drawpic(hudloc + picloc, bumb_gun_gun, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, hud_sh, pic2size,  '1 1 1', shield, DRAWFLAG_NORMAL);

// Health bar
    picsize = draw_getimagesize(hud_hp_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - vh_health)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_hp_bar, picsize, '1 1 1', 1 , DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_hp_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '37 65 0' * autocvar_cl_vehicles_hudscale;
    if(vh_health < 0.25)
    {
        if(alarm1time < time)
        {
            alarm1time = time + 2;
            sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
        }

        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm1time)
        {
            sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm1time = 0;
        }
    }

// Shield bar
    picsize = draw_getimagesize(hud_sh_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - shield)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_sh_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picloc = '40 136 0' * autocvar_cl_vehicles_hudscale;
    picsize = draw_getimagesize(hud_sh_ico) * autocvar_cl_vehicles_hudscale;
    if(shield < 0.25)
    {
        if(alarm2time < time)
        {
            alarm2time = time + 1;
            sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm2time)
        {
            sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm2time = 0;
        }
    }

// Gun bar
    picsize = draw_getimagesize(hud_ammo1_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * energy, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo1_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();

// ..  and icon
    picsize = 1.5 * draw_getimagesize(hud_energy) * autocvar_cl_vehicles_hudscale;
    picloc = '664 60 0' * autocvar_cl_vehicles_hudscale;
    if(energy < 0.2)
        drawpic(hudloc + picloc, hud_energy, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_energy, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

	if (scoreboard_showscores)
		HUD_DrawScoreboard();
    /*
    else
    {
        picsize = draw_getimagesize(waki_xhair);
        picsize_x *= 0.5;
        picsize_y *= 0.5;


        drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), waki_xhair, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }
    */
}



void CSQC_SPIDER_HUD()
{
	if(autocvar_r_letterbox)
        return;

    vector picsize, hudloc = '0 0 0', pic2size, picloc;
    int i;

    // Fetch health & ammo stats
	HUD_GETSTATS

    picsize = draw_getimagesize(hud_bg) * autocvar_cl_vehicles_hudscale;
    hudloc.y = vid_conheight - picsize.y;
    hudloc.x = vid_conwidth * 0.5 - picsize.x * 0.5;

    drawpic(hudloc, hud_bg, picsize, '1 1 1', autocvar_cl_vehicles_hudalpha, DRAWFLAG_NORMAL);

    ammo1   *= 0.01;
    shield  *= 0.01;
    vh_health  *= 0.01;
    reload2 *= 0.01;

    pic2size = draw_getimagesize(spider_ico) * (autocvar_cl_vehicles_hudscale * 0.8);
    picloc = picsize * 0.5 - pic2size * 0.5;
    if(vh_health < 0.25)
        drawpic(hudloc + picloc, spider_ico, pic2size,  '1 0 0' + '0 1 1' * sin(time * 8),  1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, spider_ico, pic2size,  '1 1 1' * vh_health  + '1 0 0' * (1 - vh_health),  1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, spider_rkt, pic2size,  '1 1 1' * reload2 + '1 0 0' * (1 - reload2), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, spider_mgun, pic2size, '1 1 1' * ammo1   + '1 0 0' * (1 - ammo1),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, hud_sh, pic2size,  '1 1 1', shield, DRAWFLAG_NORMAL);

// Health bar
    picsize = draw_getimagesize(hud_hp_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - vh_health)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_hp_bar, picsize, '1 1 1', 1 , DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_hp_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '37 65 0' * autocvar_cl_vehicles_hudscale;
    if(vh_health < 0.25)
    {
        if(alarm1time < time)
        {
            alarm1time = time + 2;
            sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm1time)
        {
            sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm1time = 0;
        }
    }
// Shield bar
    picsize = draw_getimagesize(hud_sh_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - shield)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_sh_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picloc = '40 136 0' * autocvar_cl_vehicles_hudscale;
    picsize = draw_getimagesize(hud_sh_ico) * autocvar_cl_vehicles_hudscale;
    if(shield < 0.25)
    {
        if(alarm2time < time)
        {
            alarm2time = time + 1;
            sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm2time)
        {
            sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm2time = 0;
        }
    }

// Minigun bar
    picsize = draw_getimagesize(hud_ammo1_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * ammo1, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo1_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_ammo1_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 60 0' * autocvar_cl_vehicles_hudscale;
    if(ammo1 < 0.2)
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

// Rocket ammo bar
    picsize = draw_getimagesize(hud_ammo2_bar) * autocvar_cl_vehicles_hudscale;
    ammo1 = picsize.x / 8;
    picloc = '450 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, hudloc.y + picloc.y, picsize.x * reload2, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo2_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();

// ..  and icons
    pic2size = 0.35 * draw_getimagesize(hud_ammo2_ico) * autocvar_cl_vehicles_hudscale;
    picloc.x -= pic2size.x;
    picloc.y += pic2size.y * 2.25;
    if(ammo2 == 9)
    {
        for(i = 1; i < 9; ++i)
        {
            picloc.x += ammo1;
            drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, ((8 * reload2 <= i) ? '0 0 0' : '1 1 1'), 0.75, DRAWFLAG_NORMAL);
        }
    }
    else
    {
        for(i = 1; i < 9; ++i)
        {
            picloc.x += ammo1;
            drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, ((i >= ammo2) ? '1 1 1' : '0 0 0'), 0.75, DRAWFLAG_NORMAL);
        }
    }
    pic2size = draw_getimagesize(hud_ammo2_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 130 0' * autocvar_cl_vehicles_hudscale;
    if(ammo2 == 9)
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 1 1', 1, DRAWFLAG_NORMAL);

	if (scoreboard_showscores)
		HUD_DrawScoreboard();
    else
    {
        switch(weapon2mode)
        {
            case SBRM_VOLLY:
                spider_xhair = "gfx/vehicles/axh-bracket.tga";
                break;
            case SBRM_GUIDE:
                spider_xhair = "gfx/vehicles/axh-cross.tga";
                break;
            case SBRM_ARTILLERY:
                spider_xhair = "gfx/vehicles/axh-tag.tga";
                break;
            default:
                spider_xhair= "gfx/vehicles/axh-tag.tga";
        }

        picsize = draw_getimagesize(spider_xhair);
        picsize.x *= autocvar_cl_vehicle_spiderbot_cross_size;
        picsize.y *= autocvar_cl_vehicle_spiderbot_cross_size;

        drawpic('0.5 0 0' * (vid_conwidth - picsize.x) + '0 0.5 0' * (vid_conheight - picsize.y), spider_xhair, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_ADDITIVE);
    }
}

void CSQC_RAPTOR_HUD()
{
	if(autocvar_r_letterbox)
        return;

    vector picsize, hudloc = '0 0 0', pic2size, picloc;

    // Fetch health & ammo stats
	HUD_GETSTATS

    picsize = draw_getimagesize(hud_bg) * autocvar_cl_vehicles_hudscale;
    hudloc.y = vid_conheight - picsize.y;
    hudloc.x = vid_conwidth * 0.5 - picsize.x * 0.5;

    drawpic(hudloc, hud_bg, picsize, '1 1 1', autocvar_cl_vehicles_hudalpha, DRAWFLAG_NORMAL);

    ammo1   *= 0.01;
    ammo2   *= 0.01;
    shield  *= 0.01;
    vh_health  *= 0.01;
    energy  *= 0.01;
    reload1 = reload2 * 0.01;
    //reload2 *= 0.01;

    pic2size = draw_getimagesize(spider_ico) * (autocvar_cl_vehicles_hudscale * 0.8);
    picloc = picsize * 0.5 - pic2size * 0.5;
    if(vh_health < 0.25)
        drawpic(hudloc + picloc, raptor_ico, pic2size,  '1 0 0' + '0 1 1' * sin(time * 8),  1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, raptor_ico, pic2size,  '1 1 1' * vh_health  + '1 0 0' * (1 - vh_health),  1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, raptor_bomb, pic2size,  '1 1 1' * reload1 + '1 0 0' * (1 - reload1), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, raptor_gun, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, hud_sh, pic2size,  '1 1 1', shield, DRAWFLAG_NORMAL);

// Health bar
    picsize = draw_getimagesize(hud_hp_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - vh_health)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_hp_bar, picsize, '1 1 1', 1 , DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_hp_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '37 65 0' * autocvar_cl_vehicles_hudscale;
    if(vh_health < 0.25)
    {
        if(alarm1time < time)
        {
            alarm1time = time + 2;
            sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
        }

        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm1time)
        {
            sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm1time = 0;
        }
    }

// Shield bar
    picsize = draw_getimagesize(hud_sh_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - shield)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_sh_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picloc = '40 136 0' * autocvar_cl_vehicles_hudscale;
    picsize = draw_getimagesize(hud_sh_ico) * autocvar_cl_vehicles_hudscale;
    if(shield < 0.25)
    {
        if(alarm2time < time)
        {
            alarm2time = time + 1;
            sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm2time)
        {
            sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm2time = 0;
        }
    }

// Gun bar
    picsize = draw_getimagesize(hud_ammo1_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * energy, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo1_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_ammo1_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 60 0' * autocvar_cl_vehicles_hudscale;
    if(energy < 0.2)
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

// Bomb bar
    picsize = draw_getimagesize(hud_ammo2_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, hudloc.y + picloc.y, picsize.x * reload1, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo2_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    pic2size = draw_getimagesize(hud_ammo2_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 130 0' * autocvar_cl_vehicles_hudscale;
    if(reload1 != 1)
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 1 1', 1, DRAWFLAG_NORMAL);

    if(weapon2mode == RSM_FLARE)
    {
        raptor_xhair =  "gfx/vehicles/axh-bracket.tga";
    }
    else
    {
        raptor_xhair =  "gfx/vehicles/axh-ring.tga";

        // Bombing crosshair
        if(!dropmark)
        {
            dropmark = spawn();
            dropmark.owner = self;
            dropmark.gravity = 1;
        }

        if(reload2 == 100)
        {
            vector where;

            setorigin(dropmark, pmove_org);
            dropmark.velocity = pmove_vel;
            tracetoss(dropmark, self);

            where = project_3d_to_2d(trace_endpos);

            setorigin(dropmark, trace_endpos);
            picsize = draw_getimagesize(raptor_drop) * 0.2;

            if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
            {
                where.x -= picsize.x * 0.5;
                where.y -= picsize.y * 0.5;
                where.z = 0;
                drawpic(where, raptor_drop, picsize, '0 2 0', 1, DRAWFLAG_ADDITIVE);
            }
            dropmark.cnt = time + 5;
        }
        else
        {
            vector where;
            if(dropmark.cnt > time)
            {
                where = project_3d_to_2d(dropmark.origin);
                picsize = draw_getimagesize(raptor_drop) * 0.25;

                if (!(where.z < 0 || where.x < 0 || where.y < 0 || where.x > vid_conwidth || where.y > vid_conheight))
                {
                    where.x -= picsize.x * 0.5;
                    where.y -= picsize.y * 0.5;
                    where.z = 0;
                    drawpic(where, raptor_drop, picsize, '2 0 0', 1, DRAWFLAG_ADDITIVE);
                }
            }
        }
    }

	if (scoreboard_showscores)
		HUD_DrawScoreboard();
    else
    {
        picsize = draw_getimagesize(raptor_xhair);
        picsize.x *= 0.5;
        picsize.y *= 0.5;

        drawpic('0.5 0 0' * (vid_conwidth - picsize.x) + '0 0.5 0' * (vid_conheight - picsize.y), raptor_xhair, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }
}

void CSQC_WAKIZASHI_HUD()
{
/*
    drawpic(hudloc, waki_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_b, picsize, '0 1 0' * health + '1 0 0'  * (1 - health), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_r, picsize, '1 1 1' * reload1 + '1 0 0' * (1 - reload1), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_e, picsize, '1 1 1' * energy + '1 0 0'  * (1 - energy), 1, DRAWFLAG_NORMAL);
*/
	if(autocvar_r_letterbox)
        return;

    vector picsize, hudloc = '0 0 0', pic2size, picloc;

    // Fetch health & ammo stats
	HUD_GETSTATS

    picsize = draw_getimagesize(hud_bg) * autocvar_cl_vehicles_hudscale;
    hudloc.y = vid_conheight - picsize.y;
    hudloc.x = vid_conwidth * 0.5 - picsize.x * 0.5;

    drawpic(hudloc, hud_bg, picsize, '1 1 1', autocvar_cl_vehicles_hudalpha, DRAWFLAG_NORMAL);

    shield  *= 0.01;
    vh_health  *= 0.01;
    energy  *= 0.01;
    reload1 *= 0.01;

    pic2size = draw_getimagesize(spider_ico) * (autocvar_cl_vehicles_hudscale * 0.8);
    picloc = picsize * 0.5 - pic2size * 0.5;
    if(vh_health < 0.25)
        drawpic(hudloc + picloc, waki_ico, pic2size,  '1 0 0' + '0 1 1' * sin(time * 8),  1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, waki_ico, pic2size,  '1 1 1' * vh_health  + '1 0 0' * (1 - vh_health),  1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, waki_eng, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, waki_gun, pic2size, '1 1 1' * energy   + '1 0 0' * (1 - energy),   1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, waki_rkt, pic2size,  '1 1 1' * reload1 + '1 0 0' * (1 - reload1), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc + picloc, hud_sh, pic2size,  '1 1 1', shield, DRAWFLAG_NORMAL);

// Health bar
    picsize = draw_getimagesize(hud_hp_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - vh_health)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_hp_bar, picsize, '1 1 1', 1 , DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_hp_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '37 65 0' * autocvar_cl_vehicles_hudscale;
    if(vh_health < 0.25)
    {
        if(alarm1time < time)
        {
            alarm1time = time + 2;
            sound(self, CH_PAIN_SINGLE, "vehicles/alarm.wav", VOL_BASEVOICE, ATTEN_NONE);
        }

        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_hp_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm1time)
        {
            sound(self, CH_PAIN_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm1time = 0;
        }
    }


// Shield bar
    picsize = draw_getimagesize(hud_sh_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '69 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x + (picsize.x * (1 - shield)), 0, vid_conwidth, vid_conheight);
    drawpic(hudloc + picloc, hud_sh_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picloc = '40 136 0' * autocvar_cl_vehicles_hudscale;
    picsize = draw_getimagesize(hud_sh_ico) * autocvar_cl_vehicles_hudscale;
    if(shield < 0.25)
    {
        if(alarm2time < time)
        {
            alarm2time = time + 1;
            sound(self, CH_TRIGGER_SINGLE, "vehicles/alarm_shield.wav", VOL_BASEVOICE, ATTEN_NONE);
        }
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + picloc, hud_sh_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        if(alarm2time)
        {
            sound(self, CH_TRIGGER_SINGLE, "misc/null.wav", VOL_BASEVOICE, ATTEN_NONE);
            alarm2time = 0;
        }
    }

// Gun bar
    picsize = draw_getimagesize(hud_ammo1_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 69 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, picloc.y, picsize.x * energy, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo1_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    picsize = draw_getimagesize(hud_ammo1_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 60 0' * autocvar_cl_vehicles_hudscale;
    if(energy < 0.2)
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo1_ico, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

// Bomb bar
    picsize = draw_getimagesize(hud_ammo2_bar) * autocvar_cl_vehicles_hudscale;
    picloc = '450 140 0' * autocvar_cl_vehicles_hudscale;
    drawsetcliparea(hudloc.x + picloc.x, hudloc.y + picloc.y, picsize.x * reload1, vid_conheight);
    drawpic(hudloc + picloc, hud_ammo2_bar, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    drawresetcliparea();
// ..  and icon
    pic2size = draw_getimagesize(hud_ammo2_ico) * autocvar_cl_vehicles_hudscale;
    picloc = '664 130 0' * autocvar_cl_vehicles_hudscale;
    if(reload1 != 1)
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 0 0' + '0 1 1' * sin(time * 8), 1, DRAWFLAG_NORMAL);
    else
        drawpic(hudloc + picloc, hud_ammo2_ico, pic2size, '1 1 1', 1, DRAWFLAG_NORMAL);

	if (scoreboard_showscores)
		HUD_DrawScoreboard();
    else
    {
        picsize = draw_getimagesize(waki_xhair);
        picsize.x *= 0.5;
        picsize.y *= 0.5;


        drawpic('0.5 0 0' * (vid_conwidth - picsize.x) + '0 0.5 0' * (vid_conheight - picsize.y), waki_xhair, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }
}

void Vehicles_Precache()
{
	precache_model("models/vehicles/bomblet.md3");
	precache_model("models/vehicles/clusterbomb.md3");
	precache_model("models/vehicles/clusterbomb_fragment.md3");
	precache_model("models/vehicles/rocket01.md3");
	precache_model("models/vehicles/rocket02.md3");

	precache_sound ("vehicles/alarm.wav");
	precache_sound ("vehicles/alarm_shield.wav");
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
