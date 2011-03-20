#define spider_rocket_icon "gfx/vehicles/rocket_ico.tga"
#define spider_rocket_targ "gfx/vehicles/target.tga"
//#define SPIDER_CROSS "textures/spiderbot/cross.tga"
#define SPIDER_CROSS "gfx/vehicles/sbot-xhair.tga"
#define SPIDER_CROSS2 "gfx/vehicles/sbot-xhair2.tga"

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
vector lastpos;


void CSQC_WAKIZASHI_HUD();
void CSQC_SPIDER_HUD();
void CSQC_RAPTOR_HUD();

entity AuxiliaryXhair;
void AuxiliaryXhair_Draw2D()
{
    vector loc, psize;

    psize = 0.5 * drawgetimagesize(SPIDER_CROSS2);
    loc = project_3d_to_2d(self.origin) - 0.5 * psize;
    loc_z = 0;
    psize_z = 0;
    drawpic(loc, SPIDER_CROSS2, psize, '0 1 1', 1, DRAWFLAG_ADDITIVE);

}

void Ent_AuxiliaryXhair(float isNew)
{
	entity ax;

    if(isNew)
    {
        AuxiliaryXhair = spawn();
		AuxiliaryXhair.draw2d = AuxiliaryXhair_Draw2D;
        setmodel(AuxiliaryXhair, "null");
		setsize(AuxiliaryXhair, '0 0 -1', '0 0 -1');
    }

	AuxiliaryXhair.origin_x = ReadCoord();
	AuxiliaryXhair.origin_y = ReadCoord();
	AuxiliaryXhair.origin_z = ReadCoord();
    AuxiliaryXhair.drawmask = MASK_NORMAL;
    //AuxiliaryXhair.solid = SOLID_NOT;
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

        /*
        float movedt, vel;
        movedt = time - self.move_time;
        self.move_time = time;
        vel = (view_origin - lastpos) * (1 / movedt);
        lastpos  = view_origin;
        dprint("vel: ", ftos(vel), "  angles: ", vtos(self.angles), "\n");
        */

        /*
        dprint("aim1: ", vtos(aim1), "  aim2: ", vtos(aim2), "\n");
        aim2_x *= -1;
        makevectors(aim2);
        te_lightning1(self, view_origin, view_origin + v_forward * MAX_SHOT_DISTANCE);
        traceline(view_origin, view_origin + v_forward * MAX_SHOT_DISTANCE, MOVE_WORLDONLY, self);
        aim2 = trace_endpos;


        aim1 = aim1 + view_origin;

        // Draw the crosshairs
        aim1 = project_3d_to_2d(aim1);
        aim2 = project_3d_to_2d(aim2);

        picsize = 0.5 * drawgetimagesize(SPIDER_CROSS2);
        aim2 = aim2 - 0.5 * picsize;
        aim2_z = 0;
        picsize_z = 0;
        drawpic(aim2, SPIDER_CROSS2, picsize, '0 1 1', 1, DRAWFLAG_ADDITIVE);

        picsize = 0.5 * drawgetimagesize(SPIDER_CROSS2);
        aim1 = aim1 - 0.5 * picsize;
        aim1_z = 0;
        picsize_z = 0;
        drawpic(aim1, SPIDER_CROSS2, picsize, '1 0 0', 1, DRAWFLAG_ADDITIVE);

        */
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

    if(!dropmark)
    {
        dropmark = spawn();
        dropmark.owner = self;
    }

	movedt = time - dropmark.move_time;
	dropmark.move_time = time;
    vel = (view_origin - lastpos) * (1 / movedt);
    lastpos  = view_origin;

    // Fetch health & ammo stats
    hp      = bound(0,getstatf(STAT_VEHICLESTAT_HEALTH), 1);
	shield  = bound(0,getstatf(STAT_VEHICLESTAT_SHIELD), 1);
	reload  = min(getstatf(STAT_VEHICLESTAT_RELOAD1), 1);
	energy  = min(getstatf(STAT_VEHICLESTAT_ENERGY),  1);

    // Draw the crosshairs
    picsize = drawgetimagesize(raptor_c);
    picsize_x *= 0.2;
    picsize_y *= 0.2;
    drawpic('0.5 0 0' * (vid_conwidth - picsize_x) + '0 0.5 0' * (vid_conheight - picsize_y), raptor_c, picsize, '1 0 0' + '0 1 1' * energy, 0.5, DRAWFLAG_ADDITIVE);

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

    if(reload == 1)
    {
        where = dropmark.origin;
        setorigin(dropmark, view_origin);
        dropmark.velocity = vel;
        tracetoss(dropmark, self);

        // Blend old with new predicted impact to smooth out jumpyness
        where = project_3d_to_2d(trace_endpos * 0.2 + where * 0.8);

        setorigin(dropmark, trace_endpos);
        picsize = drawgetimagesize(raptor_d) * 0.2;

        if not (where_z < 0 || where_x < 0 || where_y < 0 || where_x > vid_conwidth || where_y > vid_conheight)
        {
            where_x -= picsize_x * 0.5;
            where_y -= picsize_y * 0.5;
            where_z = 0;
            drawpic(where, raptor_d, picsize, '0 2 0', 1, DRAWFLAG_ADDITIVE);
        }
        dropmark.cnt = time + 2;
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

/*
const float STAT_VEHICLESTAT_HEALTH  = 60;
const float STAT_VEHICLESTAT_SHIELD  = 61;
const float STAT_VEHICLESTAT_ENERGY  = 62;
const float STAT_VEHICLESTAT_AMMO1   = 63;
const float STAT_VEHICLESTAT_RELAOD1 = 64;
const float STAT_VEHICLESTAT_AMMO2   = 65;
const float STAT_VEHICLESTAT_RELOAD2 = 66;
*/
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



	/*
	p = '0.5 0 0' * (vid_conwidth - (rkt_size * 8));
	p = p + '0 1 0' * vid_conheight - '0 32 0';

	// Draw health bar
	p_y += 8;
	drawfill(p, '256 0 0' * health + '0 8 0' , '0 0.7 0', 0.75, DRAWFLAG_NORMAL);
	p_x += 256 * health;
	drawfill(p, '256 0 0' * (1 - health) + '0 8 0' , '0 0 0', 0.75, DRAWFLAG_NORMAL);

	// Draw shiled bar
	p_x -= 256 * health;
	p_y += 4;
	drawfill(p, '256 0 0' * shield + '0 4 0' , '0.25 0.25 1', 0.5, DRAWFLAG_NORMAL);

	// Draw energy
	//p_x -= 256 * health;
	p_y -= 8;
	drawfill(p, '256 0 0' * energy + '0 4 0' , '1 1 1', 0.75, DRAWFLAG_NORMAL);

	// Draw rockets bar
	p_y += 12;
	drawfill(p, '256 0 0' * rockets + '0 4 0' , '1 0 0', 0.75, DRAWFLAG_NORMAL);
	*/




	if (scoreboard_showscores)
	{
		HUD_DrawScoreboard();
		HUD_DrawCenterPrint();
	}

}
