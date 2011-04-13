// self.isactive = player is in range and coordinates/status (health and armor) are up to date
// self.origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// self.healthvalue
// self.armorvalue
// self.sameteam = player is on same team as local client
//
void Draw_ShowNames()
{
    if(!autocvar_hud_shownames)
        return;

    if(self.sameteam || (!self.sameteam && autocvar_hud_shownames_enemies))
    {
        float a;
        a = autocvar_hud_panel_fg_alpha;

        InterpolateOrigin_Do();

        // draw the sprite image
        vector o;
        o = project_3d_to_2d(self.origin);

        if not(o_z < 0 || o_x < 0 || o_y < 0 || o_x > vid_conwidth || o_y > vid_conheight)
        {
            o_z = 0;

            vector myPos, mySize;
            mySize = (eX * autocvar_hud_shownames_aspect + eY) * autocvar_hud_shownames_height;
            myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

            vector iconpos, iconsize;
            vector namepos;
            float namesize;

            iconpos = myPos;

            if(autocvar_hud_shownames_status)
            {
                if(self.sameteam)
                {
                    iconsize = eX * 2 * mySize_y + eY * mySize_y;
                    // "ghost" backgrounds
                    drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);
                    drawpic_aspect_skin(iconpos + '0.5 0 0' * iconsize_x, "armor", '1 1 0' * iconsize_y, '0 0 0', a * 0.5, DRAWFLAG_NORMAL);

                    drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, self.healthvalue/autocvar_hud_panel_healtharmor_maxhealth), vid_conwidth, myPos_y + iconsize_y);
                    drawpic_aspect_skin(iconpos, "health", '1 1 0' * iconsize_y, '1 1 1', a, DRAWFLAG_NORMAL);

                    drawsetcliparea(0, myPos_y + iconsize_y - iconsize_y * min(1, self.armorvalue/autocvar_hud_panel_healtharmor_maxarmor), vid_conwidth, myPos_y + iconsize_y);
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

            namepos = myPos + eX * 2 * iconsize_y + eY * 0.5 * (autocvar_hud_shownames_height - autocvar_hud_shownames_fontsize);
            namesize = mySize_x - 2 * iconsize_y;

            string s;
            s = GetPlayerName(self.the_entnum-1);
            s = textShortenToWidth(s, namesize, '1 1 0' * autocvar_hud_shownames_fontsize, stringwidth_colors);
            drawcolorcodedstring(namepos, s, '1 1 0' * autocvar_hud_shownames_fontsize, a, DRAWFLAG_NORMAL);

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
