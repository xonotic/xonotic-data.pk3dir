// playerslots[i].isactive = player is in range and coordinates/status (health and armor) are up to date
// playerslots[i].origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// playerslots[i].healthvalue
// playerslots[i].armorvalue
// playerslots[i].sameteam = player is on same team as local client
//
void View_ShowNames()
{
    if(!autocvar_hud_shownames)
        return;

    float i;
    for(i = 0; i <= 255; ++i) // 255 players is engine limit
    {
        if(playerslots[i].isactive) // are the player coordinates/status current?
        if(playerslots[i].sameteam || (!playerslots[i].sameteam && autocvar_hud_shownames_enemies))
        {
            float t;

            float a;
            a = autocvar_hud_panel_fg_alpha;

            t = GetPlayerColor(player_localentnum - 1) + 1;

            float dist;
            dist = vlen(self.origin - view_origin);
            

            if(self.maxdistance > waypointsprite_normdistance)
                a *= pow(bound(0, (self.maxdistance - dist) / (self.maxdistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent);
            else if(self.maxdistance > 0)
                a *= pow(bound(0, (waypointsprite_fadedistance - dist) / (waypointsprite_fadedistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent) * (1 - waypointsprite_minalpha) + waypointsprite_minalpha;

            if(a <= 0)
                return;
            
            entity oldself;
            oldself = self;
            self = playerslots[i];
            InterpolateOrigin_Do();
            self = oldself;

            // draw the sprite image
            vector o;
            o = project_3d_to_2d(playerslots[i].origin);

            o_z = 0;

            vector myPos, mySize;
            mySize = (eX * autocvar_hud_shownames_aspect + eY) * autocvar_hud_shownames_height;
            myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

            vector iconpos, iconsize;
            vector namepos, namesize;

            iconpos = myPos;

            if(autocvar_hud_shownames_status)
            {
                if(playerslots[i].sameteam)
                {
                    iconsize = eX * 2 * mySize_y + eY * mySize_y;
                    // "ghost" backgrounds
                    drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);

                    drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, playerslots[i].healthvalue/autocvar_hud_panel_healtharmor_maxhealth), vid_conwidth, myPos_y + iconsize_y);
                    drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '1 1 1', a, DRAWFLAG_NORMAL);

                    drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, playerslots[i].armorvalue/autocvar_hud_panel_healtharmor_maxarmor), vid_conwidth, myPos_y + iconsize_y);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '1 1 1', a, DRAWFLAG_NORMAL);
                    drawresetcliparea();
                }
                else if(autocvar_hud_shownames_status == 2)
                {
                    iconsize = eX * 2 * mySize_y + eY * mySize_y;
                    drawpic_aspect_skin(iconpos, "health_unknown", '1 1 0' * iconsize_y, '0 0 0', a, DRAWFLAG_NORMAL);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor_unknown", '1 1 0' * iconsize_y, '0 0 0', a, DRAWFLAG_NORMAL);
                }
            }

            namepos = myPos + eX * 2 * iconsize_y;
            namesize = eX * mySize_x - eX * 2 * iconsize_y + eY * mySize_y;

            drawcolorcodedstring_aspect(namepos, GetPlayerName(i), namesize, a, DRAWFLAG_NORMAL);

            /* Or maybe a health bar instead?
             *
            if(self.health >= 0)
            {
                float align;
                if(self.build_finished)
                    align = 0.5;
                else
                    align = 0;
                drawhealthbar(o, rot * 90 * DEG2RAD, self.health, SPRITE_SIZE * t, SPRITE_HOTSPOT * t, SPRITE_HEALTHBAR_WIDTH * t, SPRITE_HEALTHBAR_HEIGHT * t, SPRITE_HEALTHBAR_MARGIN * t, SPRITE_HEALTHBAR_BORDER * t, align, self.teamradar_color, a * SPRITE_HEALTHBAR_BORDERALPHA, self.teamradar_color, a * SPRITE_HEALTHBAR_HEALTHALPHA, DRAWFLAG_NORMAL);
            }
            */
        }
    }
}
