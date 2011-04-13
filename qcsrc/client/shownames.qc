void Draw_WaypointSprite()
{
    if(!autocvar_hud_shownames)
        return;

    string spriteimage;
    float t;

    if(self.lifetime)
        self.alpha = pow(bound(0, (self.fadetime - time) / self.lifetime, 1), waypointsprite_timealphaexponent);
    else
        self.alpha = 1;

    if(self.hideflags & 2)
        return; // radar only

    if(autocvar_cl_hidewaypoints >= 2)
        return;

    if(self.hideflags & 1)
        if(autocvar_cl_hidewaypoints)
            return; // fixed waypoint

    InterpolateOrigin_Do();

    t = GetPlayerColor(player_localentnum - 1) + 1;

    spriteimage = "";

    // choose the sprite
    switch(self.rule)
    {
        case SPRITERULE_DEFAULT:
            if(self.team)
            {
                if(self.team == t)
                    spriteimage = self.netname;
                else
                    spriteimage = "";
            }
            else
                spriteimage = self.netname;
            break;
        case SPRITERULE_TEAMPLAY:
            if(t == COLOR_SPECTATOR + 1)
                spriteimage = self.netname3;
            else if(self.team == t)
                spriteimage = self.netname2;
            else
                spriteimage = self.netname;
            break;
        default:
            error("Invalid waypointsprite rule!");
            break;
    }

    if(spriteimage == "")
        return;
    
    float dist;
    dist = vlen(self.origin - view_origin);
    
    float a;
    a = self.alpha * autocvar_hud_panel_fg_alpha;

    if(self.maxdistance > waypointsprite_normdistance)
        a *= pow(bound(0, (self.maxdistance - dist) / (self.maxdistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent);
    else if(self.maxdistance > 0)
        a *= pow(bound(0, (waypointsprite_fadedistance - dist) / (waypointsprite_fadedistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent) * (1 - waypointsprite_minalpha) + waypointsprite_minalpha;

    if(a <= 0)
        return;
    
    // draw the sprite image
    vector o;
    float rot;
    o = project_3d_to_2d(self.origin);
    rot = 0;

    if(o_z < 0 || o_x < 0 || o_y < 0 || o_x > vid_conwidth || o_y > vid_conheight)
    {
        // scale it to be just in view
        vector d;
        float f1, f2;

        // get the waypoint angle vector
        /*
        d_x = view_right * (self.origin - view_origin) * vid_conwidth / vid_width;
        d_y = -view_up * (self.origin - view_origin) * vid_conheight / (vid_height * vid_pixelheight);
        d_z = 0;
        */
        
        d = o - '0.5 0 0' * vid_conwidth - '0 0.5 0' * vid_conheight;

        /*
        if(autocvar_v_flipped)
            d_x = -d_x;
        */

        f1 = d_x / vid_conwidth;
        f2 = d_y / vid_conheight;

        if(max(f1, -f1) > max(f2, -f2))
        {
            if(d_z * f1 > 0)
            {
                // RIGHT edge
                d = d * (0.5 / f1);
                rot = 3;
            }
            else
            {
                // LEFT edge
                d = d * (-0.5 / f1);
                rot = 1;
            }
        }
        else
        {
            if(d_z * f2 > 0)
            {
                // BOTTOM edge
                d = d * (0.5 / f2);
                rot = 0;
            }
            else
            {
                // TOP edge
                d = d * (-0.5 / f2);
                rot = 2;
            }
        }

        o = d + '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight;
    }
    o_z = 0;

    float vidscale;
    vidscale = max(vid_conwidth / vid_width, vid_conheight / vid_height);

    t = stof(db_get(tempdb, strcat("/spriteframes/", spriteimage)));
    if(t == 0)
        spriteimage = strcat("models/sprites/", spriteimage);
    else
        spriteimage = strcat("models/sprites/", spriteimage, "_frame", ftos(mod(floor((max(0, time - self.spawntime)) * 2), t)));

    float edgedistance_min, crosshairdistance;
    edgedistance_min = min4(o_y, o_x,vid_conwidth - o_x, vid_conheight - o_y);

    crosshairdistance = sqrt( pow(o_x - vid_conwidth/2, 2) + pow(o_y - vid_conheight/2, 2) );

    t = waypointsprite_scale * vidscale;
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
    drawrotpic(o, rot * 90 * DEG2RAD, spriteimage, SPRITE_SIZE * t, SPRITE_HOTSPOT * t, '1 1 1', a, DRAWFLAG_MIPMAP);

    if(self.build_finished)
    {
        if(time < self.build_finished + 0.25)
        {
            if(time < self.build_started)
                self.health = self.build_starthealth;
            else if(time < self.build_finished)
                self.health = (time - self.build_started) / (self.build_finished - self.build_started) * (1 - self.build_starthealth) + self.build_starthealth;
            else
                self.health = 1;
        }
        else
            self.health = -1;
    }

    if(self.health >= 0)
    {
        float align;
        if(self.build_finished)
            align = 0.5;
        else
            align = 0;
        drawhealthbar(o, rot * 90 * DEG2RAD, self.health, SPRITE_SIZE * t, SPRITE_HOTSPOT * t, SPRITE_HEALTHBAR_WIDTH * t, SPRITE_HEALTHBAR_HEIGHT * t, SPRITE_HEALTHBAR_MARGIN * t, SPRITE_HEALTHBAR_BORDER * t, align, self.teamradar_color, a * SPRITE_HEALTHBAR_BORDERALPHA, self.teamradar_color, a * SPRITE_HEALTHBAR_HEALTHALPHA, DRAWFLAG_NORMAL);
    }
}

float shownames_alpha;
void HUD_ShowNames(void)
{
    // for each playerslot etc

    vector iconpos, iconsize;
    vector namepos, namesize;
    if(mySize_x/mySize_y > 6)
    {
        iconpos = myPos;
        iconsize = eX * 2 * mySize_y + eY * mySize_y;

        namepos = myPos + eX * 2 * mySize_y;
        namesize = eX * mySize_x - eX * 2 * mySize_y + eY * mySize_y;
    }
    else
    {
        iconpos = myPos + eX * 0.5 * mySize_x - eX * 0.5 * mySize_y;
        iconsize = eX * mySize_y + eY * 0.5 * mySize_y;

        namepos = myPos + eY * 0.5 * mySize_y;
        namesize = eX * mySize_x + eY * 0.5 * mySize_y;
    }

    if(shownames_health > 0) // otherwise player is an enemy
    {
        // "ghost" backgrounds
        drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '0 0 0', panel_fg_alpha * 0.5, DRAWFLAG_NORMAL);
        drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '0 0 0', panel_fg_alpha * 0.5, DRAWFLAG_NORMAL);

        drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, shownames_health/autocvar_hud_panel_healtharmor_maxhealth), vid_conwidth, myPos_y + iconsize_y);
        drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);

        drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, shownames_armor/autocvar_hud_panel_healtharmor_maxarmor), vid_conwidth, myPos_y + iconsize_y);
        drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL);
        drawresetcliparea();
    }
    else
    {
        drawpic_aspect_skin(iconpos, "health_unknown", '1 1 0' * iconsize_y, '0 0 0', panel_fg_alpha, DRAWFLAG_NORMAL);
        drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor_unknown", '1 1 0' * iconsize_y, '0 0 0', panel_fg_alpha, DRAWFLAG_NORMAL);
    }

    if(autocvar__hud_configure)
        drawcolorcodedstring_aspect(namepos, "Player1234", namesize, panel_fg_alpha, DRAWFLAG_NORMAL);
    else
        drawcolorcodedstring_aspect(namepos, shownames_netname, namesize, panel_fg_alpha, DRAWFLAG_NORMAL);
}

