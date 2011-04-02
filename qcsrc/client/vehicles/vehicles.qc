#define spider_rocket_icon "gfx/vehicles/rocket_ico.tga"
#define spider_rocket_targ "gfx/vehicles/target.tga"
//#define SPIDER_CROSS "textures/spiderbot/cross.tga"
#define SPIDER_CROSS "gfx/vehicles/sbot-xhair.tga"
#define SPIDER_CROSS2 "gfx/vehicles/sbot-xhair2.tga"

#define axh1 "gfx/vehicles/sbot-xhair2.tga"
#define axh2 "gfx/vehicles/sbot-xhair2.tga"
#define axh3 "gfx/vehicles/sbot-xhair2.tga"

#define spider_h "gfx/vehicles/hud_bg.tga"
#define spider_b "gfx/vehicles/sbot.tga"
#define spider_r "gfx/vehicles/sbot_rpods.tga"
#define spider_g "gfx/vehicles/sbot_mguns.tga"
#define spider_s "gfx/vehicles/shiled.tga"
#define spider_a1 "gfx/vehicles/sb_rocket.tga"
#define spider_a2 "gfx/vehicles/sb_bullets.tga"

#define raptor_h  "gfx/vehicles/hud_bg.tga"
#define raptor_s  "gfx/vehicles/shiled.tga"

#define raptor_b  "gfx/vehicles/raptor.tga"
#define raptor_g1 "gfx/vehicles/raptor_guns.tga"
#define raptor_g2 "gfx/vehicles/raptor_bombs.tga"
#define raptor_d  "gfx/vehicles/dropcross.tga"
#define raptor_c  "gfx/vehicles/raptor_cross.tga"

entity dropmark;

void CSQC_WAKIZASHI_HUD();
void CSQC_SPIDER_HUD();
void CSQC_RAPTOR_HUD();

#define MAX_AXH 4
entity AuxiliaryXhair[MAX_AXH];
const var void Draw_Not();

.string axh_image;
.float  axh_fadetime;
.float  axh_drawflag;
.float  axh_scale;

void AuxiliaryXhair_Draw2D()
{
    vector loc, psize;

    psize = self.axh_scale * drawgetimagesize(self.axh_image);
    loc = project_3d_to_2d(self.origin) - 0.5 * psize;
    if not (loc_z < 0 || loc_x < 0 || loc_y < 0 || loc_x > vid_conwidth || loc_y > vid_conheight)
    {
        loc_z = 0;
        psize_z = 0;
        drawpic(loc, self.axh_image, psize, self.colormod, self.alpha, self.axh_drawflag);
    }

    if(time - self.cnt > self.axh_fadetime)
        self.draw2d = Draw_Not;
}


void Net_AuXair()
{
    float axh_id;
    entity axh;

    axh_id = bound(0, ReadByte(), MAX_AXH);
    axh = AuxiliaryXhair[axh_id];

    if(axh == world || wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
    {
        axh               = spawn();
		axh.draw2d        = Draw_Not;
		axh.drawmask      = MASK_NORMAL;
		axh.axh_drawflag  = DRAWFLAG_ADDITIVE;
		axh.axh_fadetime  = 0.1;
		axh.axh_image     = "gfx/vehicles/axh-ring.tga";
		axh.axh_scale     = 1;
        axh.alpha         = 1;
		AuxiliaryXhair[axh_id] = axh;
    }

    axh.draw2d   = AuxiliaryXhair_Draw2D;

	axh.origin_x = ReadCoord();
	axh.origin_y = ReadCoord();
	axh.origin_z = ReadCoord();

	axh.colormod_x = ReadByte() / 255;
	axh.colormod_y = ReadByte() / 255;
	axh.colormod_z = ReadByte() / 255;
    axh.cnt = time;
}
void Net_AuXair2(float blah)
{
    Net_AuXair();
}
void Net_VehicleSetup()
{

    float hud_id, i;
    hud_id = bound(HUD_SPIDERBOT, ReadByte(), HUD_RAPTOR);

    // Init auxiliary crosshairs
//#if 1
    entity axh;
    for(i = 0; i < MAX_AXH; ++i)
    {
        axh = AuxiliaryXhair[i];
        if(axh != world && !wasfreed(axh))  // MADNESS? THIS IS QQQQCCCCCCCCC (wasfreed, why do you exsist?)
            remove(axh);

        axh               = spawn();
		axh.draw2d        = Draw_Not;
		axh.drawmask      = MASK_NORMAL;
		axh.axh_drawflag  = DRAWFLAG_ADDITIVE;
		axh.axh_fadetime  = 0.1;
		axh.axh_image     = "gfx/vehicles/axh-ring.tga";
		axh.axh_scale     = 1;
        axh.alpha         = 1;
		AuxiliaryXhair[i] = axh;
    }
/*
#else
    for(i = 0; i < MAX_AXH; ++i)
    {
        if(AuxiliaryXhair[i] != world && !wasfreed(AuxiliaryXhair[i]))
            remove(AuxiliaryXhair[i]);

        AuxiliaryXhair[i]               = spawn();
		AuxiliaryXhair[i].draw2d        = Draw_Not;
		AuxiliaryXhair[i].drawmask      = MASK_NORMAL;
		AuxiliaryXhair[i].axh_drawflag  = DRAWFLAG_ADDITIVE;
		AuxiliaryXhair[i].axh_fadetime  = 0.1;
		AuxiliaryXhair[i].axh_image     = "gfx/vehicles/axh-ring.tga";
		AuxiliaryXhair[i].axh_scale     = 1;
		AuxiliaryXhair[i].alpha         = 1;
    }
#endif
*/
    switch(hud_id)
    {
        case HUD_SPIDERBOT:
            // Minigun1
            AuxiliaryXhair[0].axh_image   = "gfx/vehicles/axh-ring.tga";
            AuxiliaryXhair[0].axh_scale   = 0.25;
            // Minigun2
            AuxiliaryXhair[1].axh_image   = "gfx/vehicles/axh-ring.tga";
            AuxiliaryXhair[1].axh_scale   = 0.25;
            // Rocket
            AuxiliaryXhair[2].axh_image   = "gfx/vehicles/axh-special1.tga";
            AuxiliaryXhair[2].axh_scale   = 0.5;
            break;
        case HUD_WAKIZASHI:
            AuxiliaryXhair[0].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhair[0].axh_scale   = 0.25;
            break;
        case HUD_RAPTOR:
            AuxiliaryXhair[0].axh_image   = "gfx/vehicles/axh-cross.tga";
            AuxiliaryXhair[0].axh_scale   = 0.5;
            AuxiliaryXhair[0].alpha       = 0.25;

            AuxiliaryXhair[1].axh_image   = "gfx/vehicles/axh-bracket.tga";
            AuxiliaryXhair[1].axh_scale   = 0.25;
            AuxiliaryXhair[1].alpha       = 0.75;
            AuxiliaryXhair[1].axh_drawflag  = DRAWFLAG_NORMAL;

            break;
    }
}

void Vehicles_Precache()
{
	//precache_model("models/ax_shell.mdl");
	//precache_sound("weapons/brass1.wav");
}


void CSQC_SPIDER_HUD()
{
	float rockets, reload, heat, hp, shield;
	vector picsize, hudloc;

    // Fetch health & ammo stats
    hp      = bound(0,getstatf(STAT_VEHICLESTAT_HEALTH), 1);
	shield  = bound(0,getstatf(STAT_VEHICLESTAT_SHIELD), 1);
	heat    = min(getstatf(STAT_VEHICLESTAT_RELOAD1), 2);
	rockets =     getstati(STAT_VEHICLESTAT_AMMO2);
	reload  = min(getstatf(STAT_VEHICLESTAT_RELOAD2), 1);


    hudloc_y = 4;
    hudloc_x = 4;
    drawfill('130 28 0', ('115 0 0' * hp) + '0 10 0', hp * '0 1 0' + (1 - hp) * '1 0 0', 0.5, DRAWFLAG_NORMAL);
    picsize = drawgetimagesize(spider_h) * 0.5;
    drawpic(hudloc, spider_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a2) * 0.5;
    drawpic(hudloc + '120 96  0', spider_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '145 19  0', strcat(ftos(rint(hp * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '136 102  0', strcat(ftos(100 - rint(heat * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a1) * 0.85;
    if(rockets == 9)
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69 0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(9 - rockets), "/8"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(spider_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, spider_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_b, picsize, '0 1 0' * hp + '1 0 0' * (1 - hp), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_r, picsize, '1 1 1' * reload + '1 0 0' * (1 - reload), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, spider_g, picsize, '1 1 1' * (1 - heat) + '1 0 0' *  heat, 1, DRAWFLAG_NORMAL);


	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
    }
    else
    {
        picsize = drawgetimagesize(SPIDER_CROSS);
        picsize_x *= autocvar_cl_vehicle_spiderbot_cross_size;
        picsize_y *= autocvar_cl_vehicle_spiderbot_cross_size;

        drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), SPIDER_CROSS, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_ADDITIVE);
    }
}


void CSQC_RAPTOR_HUD()
{
	if(autocvar_r_letterbox)
        return;

	float reload, hp, shield, energy;
	vector picsize, hudloc, vel;
	float movedt;
    vector where;

    // Fetch health & ammo stats
    hp      = bound(0,getstatf(STAT_VEHICLESTAT_HEALTH), 1);
	shield  = bound(0,getstatf(STAT_VEHICLESTAT_SHIELD), 1);
	reload  = min(getstatf(STAT_VEHICLESTAT_RELOAD1), 1);
	energy  = min(getstatf(STAT_VEHICLESTAT_ENERGY),  1);

    // Draw the crosshairs
    picsize = drawgetimagesize("gfx/vehicles/axh-cross.tga");
    picsize_x *= 0.75;
    picsize_y *= 0.75;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), "gfx/vehicles/axh-cross.tga", picsize, '1 0 0' + '0 1 1' * energy, 0.5, DRAWFLAG_ADDITIVE);

    hudloc_y = 4;
    hudloc_x = 4;

    picsize = drawgetimagesize(raptor_h) * 0.5;
    drawpic(hudloc, raptor_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(spider_a2) * 0.5;
    drawpic(hudloc + '120 96  0', spider_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '145 19  0', strcat(ftos(rint(hp * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '136 102 0', strcat(ftos(rint(energy * 100)), "%"),'15 15 0','0.5 0.5 1', 1, DRAWFLAG_NORMAL);


    picsize = drawgetimagesize(spider_a1) * 0.85;
    if(reload == 1)
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','0 1 0', 0.5, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '132 54  0', spider_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '179 69  0', strcat(ftos(rint(reload * 100)), "%"),'14 14 0','0 0 1', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(raptor_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, raptor_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_b, picsize, '0 1 0' * hp + '1 0 0' * (1 - hp), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_g1, picsize, '1 1 1' * energy + '1 0 0' * (1 - energy), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, raptor_g2, picsize, '1 1 1' * reload + '1 0 0' *  (1 - reload), 1, DRAWFLAG_NORMAL);

    if(!dropmark)
    {
        dropmark = spawn();
        dropmark.owner = self;
        dropmark.gravity = 1;
    }

    if(reload == 1)
    {
        where = dropmark.origin;
        setorigin(dropmark, pmove_org);
        dropmark.velocity = pmove_vel;
        tracetoss(dropmark, self);

        where = project_3d_to_2d(trace_endpos);

        setorigin(dropmark, trace_endpos);
        picsize = drawgetimagesize(raptor_d) * 0.2;

        if not (where_z < 0 || where_x < 0 || where_y < 0 || where_x > vid_conwidth || where_y > vid_conheight)
        {
            where_x -= picsize_x * 0.5;
            where_y -= picsize_y * 0.5;
            where_z = 0;
            drawpic(where, raptor_d, picsize, '0 2 0', 1, DRAWFLAG_ADDITIVE);
        }
        dropmark.cnt = time + 5;
    }
    else
    {
        if(dropmark.cnt > time)
        {
            where = project_3d_to_2d(dropmark.origin);
            picsize = drawgetimagesize(raptor_d) * 0.25;

            if not (where_z < 0 || where_x < 0 || where_y < 0 || where_x > vid_conwidth || where_y > vid_conheight)
            {
                where_x -= picsize_x * 0.5;
                where_y -= picsize_y * 0.5;
                where_z = 0;
                drawpic(where, raptor_d, picsize, '2 0 0', 1, DRAWFLAG_ADDITIVE);
            }
        }
    }

	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}

#define waki_h "gfx/vehicles/hud_bg.tga"
#define waki_b "gfx/vehicles/waki.tga"
#define waki_e "gfx/vehicles/waki_e.tga"
#define waki_g "gfx/vehicles/waki_guns.tga"
#define waki_r "gfx/vehicles/waki_rockets.tga"
#define waki_s "gfx/vehicles/shiled.tga"

#define waki_a1 "gfx/vehicles/sb_rocket.tga"
#define waki_a2 "gfx/vehicles/sb_cells.tga"

void CSQC_WAKIZASHI_HUD()
{
	// 0--1 floats. 1 = 100%, 0.6 = 50%.
	float health, shield, energy, rockets;
	vector picsize, hudloc;

    picsize = drawgetimagesize(SPIDER_CROSS);
    picsize_x *= autocvar_cl_vehicle_spiderbot_cross_size;
    picsize_y *= autocvar_cl_vehicle_spiderbot_cross_size;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), SPIDER_CROSS, picsize, '1 1 1', autocvar_cl_vehicle_spiderbot_cross_alpha, DRAWFLAG_NORMAL);

    health  = min(getstatf(STAT_VEHICLESTAT_HEALTH),  1);
	shield  = min(getstatf(STAT_VEHICLESTAT_SHIELD),  1);
	energy  = min(getstatf(STAT_VEHICLESTAT_ENERGY),  1);
	rockets = bound(0,getstatf(STAT_VEHICLESTAT_RELOAD1), 1);

    hudloc_y =  4;
    hudloc_x = 4;

    picsize = drawgetimagesize(waki_h) * 0.5;
    drawpic(hudloc, waki_h, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(waki_a2) * 0.7;
    drawpic(hudloc + '116 92  0', waki_a2, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);


    drawstring(hudloc + '145 19  0', strcat(ftos(rint(health * 100)), "%"),'15 15 0','0 1 0', 1, DRAWFLAG_NORMAL);
    drawstring(hudloc + '175 34  0', strcat(ftos(rint(shield * 100)), "%"),'15 15 0','0 0 1', 1, DRAWFLAG_NORMAL);

    drawstring(hudloc + '136 102  0', strcat(ftos(rint(energy * 100)), "%"),'14 14 0','1 1 1', 1, DRAWFLAG_NORMAL);

    picsize = drawgetimagesize(waki_a1) * 0.75;
    if(rockets == 1)
    {
        drawpic(hudloc + '140 55  0', waki_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
        drawpic(hudloc + '144 59  0', waki_a1, picsize, '1 1 1', 1, DRAWFLAG_NORMAL);
    }
    else
    {
        drawpic(hudloc + '140 55  0', waki_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawpic(hudloc + '144 59  0', waki_a1, picsize, '-1 -1 -1', 1, DRAWFLAG_NORMAL);
        drawstring(hudloc + '165 69 0', strcat(ftos(rint(rockets * 100)), "%"),'14 14 0','1 1 0', 1, DRAWFLAG_NORMAL);
    }

    picsize = drawgetimagesize(waki_b) * 0.5;
    hudloc_y = 10.5;
    hudloc_x = 10.5;

    drawpic(hudloc, waki_s, picsize, '1 1 1', shield, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_b, picsize, '0 1 0' * health + '1 0 0' * (1 - health), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_r, picsize, '1 1 1' * rockets + '1 0 0' * (1 - rockets), 1, DRAWFLAG_NORMAL);
    drawpic(hudloc, waki_e, picsize, '1 1 1' * energy + '1 0 0' *  (1 - energy), 1, DRAWFLAG_NORMAL);

	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}
