// self.isactive = player is in range and coordinates/status (health and armor) are up to date
// self.origin = player origin TODO: should maybe move this so it's the origin of the shownames tag already in SSQC for culling?
// self.healthvalue
// self.armorvalue
// self.sameteam = player is on same team as local client
//
const float SHOWNAMES_FADESPEED = 4;
void Draw_ShowNames()
{
    if(!autocvar_hud_shownames)
        return;

    if(self.sv_entnum == player_localentnum && !autocvar_chase_active)
        return;

    if(self.sameteam || (!self.sameteam && autocvar_hud_shownames_enemies))
    {
        self.origin = getplayerorigin(self.sv_entnum-1);
        self.origin_z += autocvar_hud_shownames_offset;

        if(!self.sameteam)
        {
            /* WIP, why does trace_ent != self not work as intended here?
            if(autocvar_hud_shownames_enemies != 2) // player has to point at enemy if so
            {
                traceline(view_origin, view_origin + view_forward * MAX_SHOT_DISTANCE, MOVETYPE_FLY, world);
                print("trace_endpos: ", vtos(trace_endpos), " view_origin: ", vtos(view_origin), "\n");
                if(trace_ent != self)
                    return;
            }*/

            traceline(self.origin, view_origin, 1, self);
        }

        vector o, eo;
        o = project_3d_to_2d(self.origin);
        float overlap;

        if(autocvar_hud_shownames_antioverlap)
        {
            // fade tag out if another tag that is closer to you overlaps
            entity e;
            for(e = world; (e = find(e, classname, "shownames_tag")); )
            {
                if(e == self)
                    continue;
                eo = project_3d_to_2d(e.origin);
                if not(eo_z < 0 || eo_x < 0 || eo_y < 0 || eo_x > vid_conwidth || eo_y > vid_conheight)
                {
                    eo_z = 0;
                    if(vlen((eX * o_x + eY * o_y) - eo) < autocvar_hud_shownames_antioverlap_distance && vlen(self.origin - view_origin) > vlen(e.origin - view_origin))
                    {
                        overlap = TRUE;
                        break;
                    }
                }
            }
        }

        if(!self.sameteam && trace_endpos != view_origin) // out of view, fade out
            self.alpha = max(0, self.alpha - SHOWNAMES_FADESPEED * frametime);
        else if(!self.healthvalue) // dead player, fade out slowly
            self.alpha = max(0, self.alpha - SHOWNAMES_FADESPEED * 0.25 * frametime);
        else if(overlap) // tag overlap detected, fade out
            self.alpha = max(0, self.alpha - SHOWNAMES_FADESPEED * frametime);
        else // fade in
            self.alpha = min(1, self.alpha + SHOWNAMES_FADESPEED * frametime);

        if(!self.alpha)
            return;

        float dist;
        dist = vlen(self.origin - view_origin);

        float a;
        a = autocvar_hud_shownames_alpha;
        a *= self.alpha;
        if(autocvar_hud_shownames_maxdistance)
        {
            if(dist >= autocvar_hud_shownames_maxdistance)
                return;
            a *= ((autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance) - max(0, dist - autocvar_hud_shownames_mindistance)) / (autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance);
        }

        if(!a)
            return;

        float resize;
        resize = 1;
        if(autocvar_hud_shownames_resize) // limit resize so its never smaller than 0.5... gets unreadable
            resize = 0.5 + 0.5 * ((autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance) - max(0, dist - autocvar_hud_shownames_mindistance)) / (autocvar_hud_shownames_maxdistance - autocvar_hud_shownames_mindistance);

        // draw the sprite image
        if not(o_z < 0 || o_x < 0 || o_y < 0 || o_x > vid_conwidth || o_y > vid_conheight)
        {
            o_z = 0;

            vector myPos, mySize;
            mySize = (eX * autocvar_hud_shownames_aspect + eY) * autocvar_hud_shownames_fontsize;
            myPos = o - '0.5 0 0' * mySize_x - '0 1 0' * mySize_y;

            // size scaling
            mySize_x *= resize;
            mySize_y *= resize;

            myPos_x += 0.5 * (mySize_x / resize - mySize_x);
            myPos_y += (mySize_y / resize - mySize_y);

            vector namepos; // this is where the origin of the string
            float namewidth;

            namepos = myPos;
            namewidth = mySize_x;

            if(autocvar_hud_shownames_status && teamplay)
            {
                if(self.sameteam)
                {
                    if(self.healthvalue > 0)
                    {
                        HUD_Panel_DrawProgressBar(namepos + '0 1 0' * autocvar_hud_shownames_fontsize * resize, eX * 0.5 * mySize_x + eY * resize * autocvar_hud_shownames_statusbar_height, "nametag_statusbar", self.healthvalue/autocvar_hud_panel_healtharmor_maxhealth, 0, 1, '1 0 0', a, DRAWFLAG_NORMAL);

                        if(self.armorvalue > 0)
                            HUD_Panel_DrawProgressBar(namepos + '0 1 0' * autocvar_hud_shownames_fontsize * resize + eX * 0.5 * mySize_x, eX * 0.5 * mySize_x + eY * resize * autocvar_hud_shownames_statusbar_height, "nametag_statusbar", self.armorvalue/autocvar_hud_panel_healtharmor_maxarmor, 0, 0, '0 1 0', a, DRAWFLAG_NORMAL);
                    }
                }
            }

            string s;
            s = GetPlayerName(self.sv_entnum-1);
            if((autocvar_hud_shownames_decolorize == 1 && teamplay) || autocvar_hud_shownames_decolorize == 2)
                s = playername(s, GetPlayerColor(self.sv_entnum-1));

            drawfontscale = '1 1 0' * resize;
            s = textShortenToWidth(s, namewidth, '1 1 0' * autocvar_hud_shownames_fontsize, stringwidth_colors);

            float width;
            width = stringwidth(s, TRUE, '1 1 0' * autocvar_hud_shownames_fontsize);

            if (width != namewidth)
                namepos_x += (namewidth - width) / 2;
            drawcolorcodedstring(namepos, s, '1 1 0' * autocvar_hud_shownames_fontsize, a, DRAWFLAG_NORMAL);
            drawfontscale = '1 1 0';
        }
    }
}
