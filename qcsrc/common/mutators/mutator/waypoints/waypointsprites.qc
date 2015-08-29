#include "waypointsprites.qh"

REGISTER_MUTATOR(waypointsprites, true);

#ifdef SVQC
/** flags origin [team displayrule] [spritename] [spritename2] [spritename3] [lifetime maxdistance hideable] */
float WaypointSprite_SendEntity(entity to, float sendflags)
{
    WriteMutator(MSG_ENTITY, waypointsprites);

    sendflags = sendflags & 0x7F;

    if (g_nexball)
        sendflags &= ~0x80;
    else if (self.max_health || (self.pain_finished && (time < self.pain_finished + 0.25)))
        sendflags |= 0x80;

    WriteByte(MSG_ENTITY, sendflags);
    WriteByte(MSG_ENTITY, self.wp_extra);

    if (sendflags & 0x80)
    {
        if (self.max_health)
        {
            WriteByte(MSG_ENTITY, (self.health / self.max_health) * 191.0);
        }
        else
        {
            float dt = self.pain_finished - time;
            dt = bound(0, dt * 32, 16383);
            WriteByte(MSG_ENTITY, (dt & 0xFF00) / 256 + 192);
            WriteByte(MSG_ENTITY, (dt & 0x00FF));
        }
    }

    if (sendflags & 64)
    {
        WriteCoord(MSG_ENTITY, self.origin.x);
        WriteCoord(MSG_ENTITY, self.origin.y);
        WriteCoord(MSG_ENTITY, self.origin.z);
    }

    if (sendflags & 1)
    {
        WriteByte(MSG_ENTITY, self.team);
        WriteByte(MSG_ENTITY, self.rule);
    }

    if (sendflags & 2)
        WriteString(MSG_ENTITY, self.model1);

    if (sendflags & 4)
        WriteString(MSG_ENTITY, self.model2);

    if (sendflags & 8)
        WriteString(MSG_ENTITY, self.model3);

    if (sendflags & 16)
    {
        WriteCoord(MSG_ENTITY, self.fade_time);
        WriteCoord(MSG_ENTITY, self.teleport_time);
        WriteShort(MSG_ENTITY, self.fade_rate); // maxdist
        float f = 0;
        if (self.currentammo)
            f |= 1; // hideable
        if (self.exteriormodeltoclient == to)
            f |= 2; // my own
        if (g_onslaught)
        {
            if (self.owner.classname == "onslaught_controlpoint")
            {
                entity wp_owner = self.owner;
                entity e = WaypointSprite_getviewentity(to);
                if (SAME_TEAM(e, wp_owner) && wp_owner.goalentity.health >= wp_owner.goalentity.max_health) { f |= 2; }
                if (!ons_ControlPoint_Attackable(wp_owner, e.team)) { f |= 2; }
            }
            if (self.owner.classname == "onslaught_generator")
            {
                entity wp_owner = self.owner;
                if (wp_owner.isshielded && wp_owner.health >= wp_owner.max_health) { f |= 2; }
                if (wp_owner.health <= 0) { f |= 2; }
            }
        }
        WriteByte(MSG_ENTITY, f);
    }

    if (sendflags & 32)
    {
        WriteByte(MSG_ENTITY, self.cnt); // icon on radar
        WriteByte(MSG_ENTITY, self.colormod.x * 255.0);
        WriteByte(MSG_ENTITY, self.colormod.y * 255.0);
        WriteByte(MSG_ENTITY, self.colormod.z * 255.0);

        if (WaypointSprite_isteammate(self.owner, WaypointSprite_getviewentity(to)))
        {
            float dt = (self.waypointsprite_helpmetime - time) / 0.1;
            if (dt < 0)
                dt = 0;
            if (dt > 255)
                dt = 255;
            WriteByte(MSG_ENTITY, dt);
        }
        else
            WriteByte(MSG_ENTITY, 0);
    }

    return true;
}
#endif

#ifdef CSQC
void Ent_WaypointSprite();
MUTATOR_HOOKFUNCTION(waypointsprites, CSQC_Ent_Update) {
    if (MUTATOR_RETURNVALUE) return false;
    if (!ReadMutatorEquals(mutator_argv_int_0, waypointsprites)) return false;
    Ent_WaypointSprite();
    return true;
}

void Ent_RemoveWaypointSprite()
{
    if (self.netname) strunzone(self.netname);
    if (self.netname2) strunzone(self.netname2);
    if (self.netname3) strunzone(self.netname3);
}

/** flags origin [team displayrule] [spritename] [spritename2] [spritename3] [lifetime maxdistance hideable] */
void Ent_WaypointSprite()
{
    int sendflags = ReadByte();
    self.wp_extra = ReadByte();

    if (!self.spawntime)
        self.spawntime = time;

    self.draw2d = Draw_WaypointSprite;

    InterpolateOrigin_Undo();
    self.iflags |= IFLAG_ORIGIN;

    if (sendflags & 0x80)
    {
        int t = ReadByte();
        if (t < 192)
        {
            self.health = t / 191.0;
            self.build_finished = 0;
        }
        else
        {
            t = (t - 192) * 256 + ReadByte();
            self.build_started = servertime;
            if (self.build_finished)
                self.build_starthealth = bound(0, self.health, 1);
            else
                self.build_starthealth = 0;
            self.build_finished = servertime + t / 32;
        }
    }
    else
    {
        self.health = -1;
        self.build_finished = 0;
    }

    if (sendflags & 64)
    {
        // unfortunately, this needs to be exact (for the 3D display)
        self.origin_x = ReadCoord();
        self.origin_y = ReadCoord();
        self.origin_z = ReadCoord();
        setorigin(self, self.origin);
    }

    if (sendflags & 1)
    {
        self.team = ReadByte();
        self.rule = ReadByte();
    }

    if (sendflags & 2)
    {
        if (self.netname)
            strunzone(self.netname);
        self.netname = strzone(ReadString());
    }

    if (sendflags & 4)
    {
        if (self.netname2)
            strunzone(self.netname2);
        self.netname2 = strzone(ReadString());
    }

    if (sendflags & 8)
    {
        if (self.netname3)
            strunzone(self.netname3);
        self.netname3 = strzone(ReadString());
    }

    if (sendflags & 16)
    {
        self.lifetime = ReadCoord();
        self.fadetime = ReadCoord();
        self.maxdistance = ReadShort();
        self.hideflags = ReadByte();
    }

    if (sendflags & 32)
    {
        int f = ReadByte();
        self.teamradar_icon = (f & 0x7F);
        if (f & 0x80)
        {
            self.(teamradar_times[self.teamradar_time_index]) = time;
            self.teamradar_time_index = (self.teamradar_time_index + 1) % MAX_TEAMRADAR_TIMES;
        }
        self.teamradar_color_x = ReadByte() / 255.0;
        self.teamradar_color_y = ReadByte() / 255.0;
        self.teamradar_color_z = ReadByte() / 255.0;
        self.helpme = ReadByte() * 0.1;
        if (self.helpme > 0)
            self.helpme += servertime;
    }

    InterpolateOrigin_Note();

    self.entremove = Ent_RemoveWaypointSprite;
}
#endif

#ifdef CSQC
float spritelookupblinkvalue(string s)
{
    if (s == WP_Weapon.netname) {
        if (get_weaponinfo(self.wp_extra).spawnflags & WEP_FLAG_SUPERWEAPON)
            return 2;
    }
    if (s == WP_Item.netname) return ITEMS[self.wp_extra].m_waypointblink;

    switch (s)
    {
        case "item-invis":       return 2;
        case "item-extralife":   return 2;
        case "item-speed":       return 2;
        default:                 return 1;
    }
}

vector spritelookupcolor(string s, vector def)
{
    if (s == WP_Weapon.netname) return get_weaponinfo(self.wp_extra).wpcolor;
    if (s == WP_Item.netname) return ITEMS[self.wp_extra].m_color;
    if (s == WP_Buff.netname) return BUFFS[self.wp_extra].m_color;
    return def;
}

string spritelookuptext(string s)
{
    if (s == WP_RaceStartFinish.netname) return (race_checkpointtime || race_mycheckpointtime) ? _("Finish") : _("Start");
    if (s == WP_Weapon.netname) return get_weaponinfo(self.wp_extra).message;
    if (s == WP_Item.netname) return ITEMS[self.wp_extra].m_waypoint;
    if (s == WP_Buff.netname) return BUFFS[self.wp_extra].m_prettyName;
    if (s == WP_Monster.netname) return get_monsterinfo(self.wp_extra).monster_name;

    // need to loop, as our netname could be one of three
    FOREACH(WAYPOINTS, it.netname == s, LAMBDA(
        return it.m_name;
    ));

    switch (s)
    {
        case "item-invis": return _("Invisibility");
        case "item-extralife": return _("Extra life");
        case "item-speed": return _("Speed");
        default: return s;
    }
}
#endif

#ifdef CSQC
void drawrotpic(vector org, float rot, string pic, vector sz, vector hotspot, vector rgb, float a, float f)
{
    vector v1, v2, v3, v4;

    hotspot = -1 * hotspot;

    // hotspot-relative coordinates of the corners
    v1 = hotspot;
    v2 = hotspot + '1 0 0' * sz.x;
    v3 = hotspot + '1 0 0' * sz.x + '0 1 0' * sz.y;
    v4 = hotspot                  + '0 1 0' * sz.y;

    // rotate them, and make them absolute
    rot = -rot; // rotate by the opposite angle, as our coordinate system is reversed
    v1 = rotate(v1, rot) + org;
    v2 = rotate(v2, rot) + org;
    v3 = rotate(v3, rot) + org;
    v4 = rotate(v4, rot) + org;

    // draw them
    R_BeginPolygon(pic, f);
    R_PolygonVertex(v1, '0 0 0', rgb, a);
    R_PolygonVertex(v2, '1 0 0', rgb, a);
    R_PolygonVertex(v3, '1 1 0', rgb, a);
    R_PolygonVertex(v4, '0 1 0', rgb, a);
    R_EndPolygon();
}

void drawquad(vector o, vector ri, vector up, string pic, vector rgb, float a, float f)
{
    R_BeginPolygon(pic, f);
    R_PolygonVertex(o, '0 0 0', rgb, a);
    R_PolygonVertex(o + ri, '1 0 0', rgb, a);
    R_PolygonVertex(o + up + ri, '1 1 0', rgb, a);
    R_PolygonVertex(o + up, '0 1 0', rgb, a);
    R_EndPolygon();
}

void drawhealthbar(vector org, float rot, float h, vector sz, vector hotspot, float width, float theheight, float margin, float border, float align, vector rgb, float a, vector hrgb, float ha, float f)
{
    vector o, ri, up;
    float owidth; // outer width

    hotspot = -1 * hotspot;

    // hotspot-relative coordinates of the healthbar corners
    o = hotspot;
    ri = '1 0 0';
    up = '0 1 0';

    rot = -rot; // rotate by the opposite angle, as our coordinate system is reversed
    o = rotate(o, rot) + org;
    ri = rotate(ri, rot);
    up = rotate(up, rot);

    owidth = width + 2 * border;
    o = o - up * (margin + border + theheight) + ri * (sz.x - owidth) * 0.5;

    drawquad(o - up * border,                               ri * owidth,    up * border,    "", rgb,  a,  f);
    drawquad(o + up * theheight,                            ri * owidth,    up * border,    "", rgb,  a,  f);
    drawquad(o,                                             ri * border,    up * theheight, "", rgb,  a,  f);
    drawquad(o + ri * (owidth - border),                    ri * border,    up * theheight, "", rgb,  a,  f);
    drawquad(o + ri * (border + align * ((1 - h) * width)), ri * width * h, up * theheight, "", hrgb, ha, f);
}

// returns location of sprite text
vector drawspritearrow(vector o, float ang, vector rgb, float a, float t)
{
    float size   = 9.0 * t;
    float border = 1.5 * t;
    float margin = 4.0 * t;

    float borderDiag = border * 1.414;
    vector arrowX  = eX * size;
    vector arrowY  = eY * (size+borderDiag);
    vector borderX = eX * (size+borderDiag);
    vector borderY = eY * (size+borderDiag+border);

    R_BeginPolygon("", DRAWFLAG_NORMAL);
    R_PolygonVertex(o,                                  '0 0 0', '0 0 0', a);
    R_PolygonVertex(o + rotate(arrowY  - borderX, ang), '0 0 0', '0 0 0', a);
    R_PolygonVertex(o + rotate(borderY - borderX, ang), '0 0 0', '0 0 0', a);
    R_PolygonVertex(o + rotate(borderY + borderX, ang), '0 0 0', '0 0 0', a);
    R_PolygonVertex(o + rotate(arrowY  + borderX, ang), '0 0 0', '0 0 0', a);
    R_EndPolygon();

    R_BeginPolygon("", DRAWFLAG_ADDITIVE);
    R_PolygonVertex(o + rotate(eY * borderDiag, ang), '0 0 0', rgb, a);
    R_PolygonVertex(o + rotate(arrowY - arrowX, ang), '0 0 0', rgb, a);
    R_PolygonVertex(o + rotate(arrowY + arrowX, ang), '0 0 0', rgb, a);
    R_EndPolygon();

    return o + rotate(eY * (borderDiag+size+margin), ang);
}

// returns location of sprite healthbar
vector drawspritetext(vector o, float ang, float minwidth, vector rgb, float a, vector fontsize, string s)
{
    float algnx, algny;
    float sw, w, h;
    float aspect, sa, ca;

    sw = stringwidth(s, false, fontsize);
    if (sw > minwidth)
        w = sw;
    else
        w = minwidth;
    h = fontsize.y;

    // how do corners work?
    aspect = vid_conwidth / vid_conheight;
    sa = sin(ang);
    ca = cos(ang) * aspect;
    if (fabs(sa) > fabs(ca))
    {
        algnx = (sa < 0);
        algny = 0.5 - 0.5 * ca / fabs(sa);
    }
    else
    {
        algnx = 0.5 - 0.5 * sa / fabs(ca);
        algny = (ca < 0);
    }

    // align
    o.x -= w * algnx;
    o.y -= h * algny;

    // we want to be onscreen
    if (o.x < 0)
        o.x = 0;
    if (o.y < 0)
        o.y = 0;
    if (o.x > vid_conwidth - w)
        o.x = vid_conwidth - w;
    if (o.y > vid_conheight - h)
        o.x = vid_conheight - h;

    o.x += 0.5 * (w - sw);

    drawstring(o, s, fontsize, rgb, a, DRAWFLAG_NORMAL);

    o.x += 0.5 * sw;
    o.y += 0.5 * h;

    return o;
}

vector fixrgbexcess_move(vector rgb, vector src, vector dst)
{
    vector yvec = '0.299 0.587 0.114';
    return rgb + dst * ((src * yvec) / (dst * yvec)) * ((rgb - '1 1 1') * src);
}

vector fixrgbexcess(vector rgb)
{
    if (rgb.x > 1) {
        rgb = fixrgbexcess_move(rgb, '1 0 0', '0 1 1');
        if (rgb.y > 1) {
            rgb = fixrgbexcess_move(rgb, '0 1 0', '0 0 1');
            if (rgb.z > 1) rgb.z = 1;
        } else if (rgb.z > 1) {
            rgb = fixrgbexcess_move(rgb, '0 0 1', '0 1 0');
            if (rgb.y > 1) rgb.y = 1;
        }
    } else if (rgb.y > 1) {
        rgb = fixrgbexcess_move(rgb, '0 1 0', '1 0 1');
        if (rgb.x > 1) {
            rgb = fixrgbexcess_move(rgb, '1 0 0', '0 0 1');
            if (rgb.z > 1) rgb.z = 1;
        } else if (rgb.z > 1) {
            rgb = fixrgbexcess_move(rgb, '0 0 1', '1 0 0');
            if (rgb.x > 1) rgb.x = 1;
        }
    } else if (rgb.z > 1) {
        rgb = fixrgbexcess_move(rgb, '0 0 1', '1 1 0');
        if (rgb.x > 1) {
            rgb = fixrgbexcess_move(rgb, '1 0 0', '0 1 0');
            if (rgb.y > 1) rgb.y = 1;
        } else if (rgb.y > 1) {
            rgb = fixrgbexcess_move(rgb, '0 1 0', '1 0 0');
            if (rgb.x > 1) rgb.x = 1;
        }
    }
    return rgb;
}

void Draw_WaypointSprite()
{
    if (self.lifetime)
        self.alpha = pow(bound(0, (self.fadetime - time) / self.lifetime, 1), waypointsprite_timealphaexponent);
    else
        self.alpha = 1;

    if (self.hideflags & 2)
        return; // radar only

    if (autocvar_cl_hidewaypoints >= 2)
        return;

    if (self.hideflags & 1)
        if (autocvar_cl_hidewaypoints)
            return; // fixed waypoint

    InterpolateOrigin_Do();

    float t = GetPlayerColor(player_localnum) + 1;

    string spriteimage = "";

    // choose the sprite
    switch (self.rule)
    {
        case SPRITERULE_SPECTATOR:
            if (!(
                (autocvar_g_waypointsprite_itemstime == 1 && t == NUM_SPECTATOR + 1)
            ||	(autocvar_g_waypointsprite_itemstime == 2 && (t == NUM_SPECTATOR + 1 || warmup_stage))
                ))
                return;
            spriteimage = self.netname;
            break;
        case SPRITERULE_DEFAULT:
            if (self.team)
            {
                if (self.team == t)
                    spriteimage = self.netname;
                else
                    spriteimage = "";
            }
            else
                spriteimage = self.netname;
            break;
        case SPRITERULE_TEAMPLAY:
            if (t == NUM_SPECTATOR + 1)
                spriteimage = self.netname3;
            else if (self.team == t)
                spriteimage = self.netname2;
            else
                spriteimage = self.netname;
            break;
        default:
            error("Invalid waypointsprite rule!");
            break;
    }

    if (spriteimage == "")
        return;

    ++waypointsprite_newcount;

    float dist;
    dist = vlen(self.origin - view_origin);

    float a;
    a = self.alpha * autocvar_hud_panel_fg_alpha;

    if (self.maxdistance > waypointsprite_normdistance)
        a *= pow(bound(0, (self.maxdistance - dist) / (self.maxdistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent);
    else if (self.maxdistance > 0)
        a *= pow(bound(0, (waypointsprite_fadedistance - dist) / (waypointsprite_fadedistance - waypointsprite_normdistance), 1), waypointsprite_distancealphaexponent) * (1 - waypointsprite_minalpha) + waypointsprite_minalpha;

    vector rgb = spritelookupcolor(spriteimage, self.teamradar_color);
    if (rgb == '0 0 0')
    {
        self.teamradar_color = '1 0 1';
        LOG_INFOF("WARNING: sprite of name %s has no color, using pink so you notice it\n", spriteimage);
    }

    if (time - floor(time) > 0.5)
    {
        if (self.helpme && time < self.helpme)
            a *= SPRITE_HELPME_BLINK;
        else if (!self.lifetime) // fading out waypoints don't blink
            a *= spritelookupblinkvalue(spriteimage);
    }

    if (a > 1)
    {
        rgb *= a;
        a = 1;
    }

    if (a <= 0.003)
        return;

    rgb = fixrgbexcess(rgb);

    vector o;
    float ang;

    o = project_3d_to_2d(self.origin);
    if (o.z < 0
    || o.x < (vid_conwidth * waypointsprite_edgeoffset_left)
    || o.y < (vid_conheight * waypointsprite_edgeoffset_top)
    || o.x > (vid_conwidth - (vid_conwidth * waypointsprite_edgeoffset_right))
    || o.y > (vid_conheight - (vid_conheight * waypointsprite_edgeoffset_bottom)))
    {
        // scale it to be just in view
        vector d;
        float f1, f2;

        d = o - '0.5 0 0' * vid_conwidth - '0 0.5 0' * vid_conheight;
        ang = atan2(-d.x, -d.y);
        if (o.z < 0)
            ang += M_PI;

        f1 = d.x / vid_conwidth;
        f2 = d.y / vid_conheight;

        if (max(f1, -f1) > max(f2, -f2)) {
            if (d.z * f1 > 0) {
                // RIGHT edge
                d = d * ((0.5 - waypointsprite_edgeoffset_right) / f1);
            } else {
                // LEFT edge
                d = d * (-(0.5 - waypointsprite_edgeoffset_left) / f1);
            }
        } else {
            if (d.z * f2 > 0) {
                // BOTTOM edge
                d = d * ((0.5 - waypointsprite_edgeoffset_bottom) / f2);
            } else {
                // TOP edge
                d = d * (-(0.5 - waypointsprite_edgeoffset_top) / f2);
            }
        }

        o = d + '0.5 0 0' * vid_conwidth + '0 0.5 0' * vid_conheight;
    }
    else
    {
#if 1
        ang = M_PI;
#else
        vector d;
        d = o - '0.5 0 0' * vid_conwidth - '0 0.5 0' * vid_conheight;
        ang = atan2(-d.x, -d.y);
#endif
    }
    o.z = 0;

    float edgedistance_min = min((o.y - (vid_conheight * waypointsprite_edgeoffset_top)),
    (o.x - (vid_conwidth * waypointsprite_edgeoffset_left)),
    (vid_conwidth - (vid_conwidth * waypointsprite_edgeoffset_right)) - o.x,
    (vid_conheight - (vid_conheight * waypointsprite_edgeoffset_bottom)) - o.y);

    float vidscale = max(vid_conwidth / vid_width, vid_conheight / vid_height);

    float crosshairdistance = sqrt( pow(o.x - vid_conwidth/2, 2) + pow(o.y - vid_conheight/2, 2) );

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
    if (crosshairdistance < waypointsprite_crosshairfadedistance) {
        a = a * (1 - (1 - waypointsprite_crosshairfadealpha) * (1 - bound(0, crosshairdistance/waypointsprite_crosshairfadedistance, 1)));
        t = t * (1 - (1 - waypointsprite_crosshairfadescale) * (1 - bound(0, crosshairdistance/waypointsprite_crosshairfadedistance, 1)));
    }

    if (self.build_finished)
    {
        if (time < self.build_finished + 0.25)
        {
            if (time < self.build_started)
                self.health = self.build_starthealth;
            else if (time < self.build_finished)
                self.health = (time - self.build_started) / (self.build_finished - self.build_started) * (1 - self.build_starthealth) + self.build_starthealth;
            else
                self.health = 1;
        }
        else
            self.health = -1;
    }

    o = drawspritearrow(o, ang, rgb, a, SPRITE_ARROW_SCALE * t);

    string txt;
    if (autocvar_g_waypointsprite_spam && waypointsprite_count >= autocvar_g_waypointsprite_spam)
        txt = _("Spam");
    else
        txt = spritelookuptext(spriteimage);
    if (self.helpme && time < self.helpme)
        txt = sprintf(_("%s needing help!"), txt);
    if (autocvar_g_waypointsprite_uppercase)
        txt = strtoupper(txt);

    draw_beginBoldFont();
    if (self.health >= 0)
    {
        o = drawspritetext(o, ang, (SPRITE_HEALTHBAR_WIDTH + 2 * SPRITE_HEALTHBAR_BORDER) * t, rgb, a, waypointsprite_fontsize * '1 1 0', txt);

        float align, marg;
        if (self.build_finished)
            align = 0.5;
        else
            align = 0;
        if (cos(ang) > 0)
            marg = -(SPRITE_HEALTHBAR_MARGIN + SPRITE_HEALTHBAR_HEIGHT + 2 * SPRITE_HEALTHBAR_BORDER) * t - 0.5 * waypointsprite_fontsize;
        else
            marg = SPRITE_HEALTHBAR_MARGIN * t + 0.5 * waypointsprite_fontsize;
        drawhealthbar(
                o,
                0,
                self.health,
                '0 0 0',
                '0 0 0',
                SPRITE_HEALTHBAR_WIDTH * t,
                SPRITE_HEALTHBAR_HEIGHT * t,
                marg,
                SPRITE_HEALTHBAR_BORDER * t,
                align,
                rgb,
                a * SPRITE_HEALTHBAR_BORDERALPHA,
                rgb,
                a * SPRITE_HEALTHBAR_HEALTHALPHA,
                DRAWFLAG_NORMAL
                 );
    }
    else
    {
        o = drawspritetext(o, ang, 0, rgb, a, waypointsprite_fontsize * '1 1 0', txt);
    }
    draw_endBoldFont();
}

void WaypointSprite_Load_Frames(string ext)
{
    int dh = search_begin(strcat("models/sprites/*_frame*", ext), false, false);
    if (dh < 0) return;
    int ext_len = strlen(ext);
    int n = search_getsize(dh);
    for (int i = 0; i < n; ++i)
    {
        string s = search_getfilename(dh, i);
        s = substring(s, 15, strlen(s) - 15 - ext_len); // strip models/sprites/ and extension

        int o = strstrofs(s, "_frame", 0);
        string sname = strcat("/spriteframes/", substring(s, 0, o));
        string sframes = substring(s, o + 6, strlen(s) - o - 6);
        int f = stof(sframes) + 1;
        db_put(tempdb, sname, ftos(max(f, stof(db_get(tempdb, sname)))));
    }
    search_end(dh);
}

void WaypointSprite_Load();
STATIC_INIT(WaypointSprite_Load) {
    WaypointSprite_Load();
    WaypointSprite_Load_Frames(".tga");
    WaypointSprite_Load_Frames(".jpg");
}
void WaypointSprite_Load()
{
    waypointsprite_fadedistance = vlen(mi_scale);
    waypointsprite_normdistance = autocvar_g_waypointsprite_normdistance;
    waypointsprite_minscale = autocvar_g_waypointsprite_minscale;
    waypointsprite_minalpha = autocvar_g_waypointsprite_minalpha;
    waypointsprite_distancealphaexponent = autocvar_g_waypointsprite_distancealphaexponent;
    waypointsprite_timealphaexponent = autocvar_g_waypointsprite_timealphaexponent;
    waypointsprite_scale = autocvar_g_waypointsprite_scale;
    waypointsprite_fontsize = autocvar_g_waypointsprite_fontsize;
    waypointsprite_edgefadealpha = autocvar_g_waypointsprite_edgefadealpha;
    waypointsprite_edgefadescale = autocvar_g_waypointsprite_edgefadescale;
    waypointsprite_edgefadedistance = autocvar_g_waypointsprite_edgefadedistance;
    waypointsprite_edgeoffset_bottom = autocvar_g_waypointsprite_edgeoffset_bottom;
    waypointsprite_edgeoffset_left = autocvar_g_waypointsprite_edgeoffset_left;
    waypointsprite_edgeoffset_right = autocvar_g_waypointsprite_edgeoffset_right;
    waypointsprite_edgeoffset_top = autocvar_g_waypointsprite_edgeoffset_top;
    waypointsprite_crosshairfadealpha = autocvar_g_waypointsprite_crosshairfadealpha;
    waypointsprite_crosshairfadescale = autocvar_g_waypointsprite_crosshairfadescale;
    waypointsprite_crosshairfadedistance = autocvar_g_waypointsprite_crosshairfadedistance;
    waypointsprite_distancefadealpha = autocvar_g_waypointsprite_distancefadealpha;
    waypointsprite_distancefadescale = autocvar_g_waypointsprite_distancefadescale;
    waypointsprite_distancefadedistance = waypointsprite_fadedistance * autocvar_g_waypointsprite_distancefadedistancemultiplier;
    waypointsprite_alpha = autocvar_g_waypointsprite_alpha * (1 - autocvar__menu_alpha);

    waypointsprite_count = waypointsprite_newcount;
    waypointsprite_newcount = 0;
}
#endif

#ifdef SVQC
void WaypointSprite_UpdateSprites(entity e, entity _m1, entity _m2, entity _m3)
{
    string m1 = _m1.netname;
    string m2 = _m2.netname;
    string m3 = _m3.netname;
    if (m1 != e.model1)
    {
        e.model1 = m1;
        e.SendFlags |= 2;
    }
    if (m2 != e.model2)
    {
        e.model2 = m2;
        e.SendFlags |= 4;
    }
    if (m3 != e.model3)
    {
        e.model3 = m3;
        e.SendFlags |= 8;
    }
}

void WaypointSprite_UpdateHealth(entity e, float f)
{
    f = bound(0, f, e.max_health);
    if (f != e.health || e.pain_finished)
    {
        e.health = f;
        e.pain_finished = 0;
        e.SendFlags |= 0x80;
    }
}

void WaypointSprite_UpdateMaxHealth(entity e, float f)
{
    if (f != e.max_health || e.pain_finished)
    {
        e.max_health = f;
        e.pain_finished = 0;
        e.SendFlags |= 0x80;
    }
}

void WaypointSprite_UpdateBuildFinished(entity e, float f)
{
    if (f != e.pain_finished || e.max_health)
    {
        e.max_health = 0;
        e.pain_finished = f;
        e.SendFlags |= 0x80;
    }
}

void WaypointSprite_UpdateOrigin(entity e, vector o)
{
    if (o != e.origin)
    {
        setorigin(e, o);
        e.SendFlags |= 64;
    }
}

void WaypointSprite_UpdateRule(entity e, float t, float r)
{
    // no check, as this is never called without doing an actual change (usually only once)
    e.rule = r;
    e.team = t;
    e.SendFlags |= 1;
}

void WaypointSprite_UpdateTeamRadar(entity e, float icon, vector col)
{
    // no check, as this is never called without doing an actual change (usually only once)
    e.cnt = (icon & 0x7F) | (e.cnt & 0x80);
    e.colormod = col;
    e.SendFlags |= 32;
}

void WaypointSprite_Ping(entity e)
{
    // anti spam
    if (time < e.waypointsprite_pingtime) return;
    e.waypointsprite_pingtime = time + 0.3;
    // ALWAYS sends (this causes a radar circle), thus no check
    e.cnt |= 0x80;
    e.SendFlags |= 32;
}

void WaypointSprite_HelpMePing(entity e)
{
    WaypointSprite_Ping(e);
    e.waypointsprite_helpmetime = time + waypointsprite_deployed_lifetime;
    e.SendFlags |= 32;
}

void WaypointSprite_FadeOutIn(entity e, float t)
{
    if (!e.fade_time)
    {
        e.fade_time = t;
        e.teleport_time = time + t;
    }
    else if (t < (e.teleport_time - time))
    {
        // accelerate the waypoint's dying
        // ensure:
        //   (e.teleport_time - time) / wp.fade_time stays
        //   e.teleport_time = time + fadetime
        float current_fadetime;
        current_fadetime = e.teleport_time - time;
        e.teleport_time = time + t;
        e.fade_time = e.fade_time * t / current_fadetime;
    }

    e.SendFlags |= 16;
}

void WaypointSprite_Init()
{
    waypointsprite_limitedrange = autocvar_sv_waypointsprite_limitedrange;
    waypointsprite_deployed_lifetime = autocvar_sv_waypointsprite_deployed_lifetime;
    waypointsprite_deadlifetime = autocvar_sv_waypointsprite_deadlifetime;
}

void WaypointSprite_InitClient(entity e)
{
}

void WaypointSprite_Kill(entity wp)
{
    if (!wp) return;
    if (wp.owner) wp.owner.(wp.owned_by_field) = world;
    remove(wp);
}

void WaypointSprite_Disown(entity wp, float fadetime)
{
    if (!wp) return;
    if (wp.classname != "sprite_waypoint")
    {
        backtrace("Trying to disown a non-waypointsprite");
        return;
    }
    if (wp.owner)
    {
        if (wp.exteriormodeltoclient == wp.owner)
            wp.exteriormodeltoclient = world;
        wp.owner.(wp.owned_by_field) = world;
        wp.owner = world;

        WaypointSprite_FadeOutIn(wp, fadetime);
    }
}

void WaypointSprite_Think()
{
    bool doremove = false;

    if (self.fade_time && time >= self.teleport_time)
    {
        doremove = true;
    }

    if (self.exteriormodeltoclient)
        WaypointSprite_UpdateOrigin(self, self.exteriormodeltoclient.origin + self.view_ofs);

    if (doremove)
        WaypointSprite_Kill(self);
    else
        self.nextthink = time; // WHY?!?
}

float WaypointSprite_visible_for_player(entity e)
{
    // personal waypoints
    if (self.enemy && self.enemy != e)
        return false;

    // team waypoints
    if (self.rule == SPRITERULE_SPECTATOR)
    {
        if (!autocvar_sv_itemstime)
            return false;
        if (!warmup_stage && IS_PLAYER(e))
            return false;
    }
    else if (self.team && self.rule == SPRITERULE_DEFAULT)
    {
        if (self.team != e.team)
            return false;
        if (!IS_PLAYER(e))
            return false;
    }

    return true;
}

entity WaypointSprite_getviewentity(entity e)
{
    if (IS_SPEC(e)) e = e.enemy;
    /* TODO idea (check this breaks nothing)
    else if (e.classname == "observer")
        e = world;
    */
    return e;
}

float WaypointSprite_isteammate(entity e, entity e2)
{
    if (teamplay)
        return e2.team == e.team;
    return e2 == e;
}

float WaypointSprite_Customize()
{
    // this is not in SendEntity because it shall run every frame, not just every update

    // make spectators see what the player would see
    entity e = WaypointSprite_getviewentity(other);

    if (MUTATOR_CALLHOOK(CustomizeWaypoint, self, other))
        return false;

    return self.waypointsprite_visible_for_player(e);
}

float WaypointSprite_SendEntity(entity to, float sendflags);

void WaypointSprite_Reset()
{
    // if a WP wants to time out, let it time out immediately; other WPs ought to be reset/killed by their owners

    if (self.fade_time) // there was there before: || g_keyhunt, do we really need this?
        WaypointSprite_Kill(self);
}

entity WaypointSprite_Spawn(
    entity spr, // sprite
    float _lifetime, float maxdistance, // lifetime, max distance
    entity ref, vector ofs, // position
    entity showto, float t, // show to whom? Use a flag to indicate a team
    entity own, .entity ownfield, // remove when own gets killed
    float hideable, // true when it should be controlled by cl_hidewaypoints
    float icon // initial icon
)
{
    entity wp = new(sprite_waypoint);
    wp.teleport_time = time + _lifetime;
    wp.fade_time = _lifetime;
    wp.exteriormodeltoclient = ref;
    if (ref)
    {
        wp.view_ofs = ofs;
        setorigin(wp, ref.origin + ofs);
    }
    else
        setorigin(wp, ofs);
    wp.enemy = showto;
    wp.team = t;
    wp.owner = own;
    wp.currentammo = hideable;
    if (own)
    {
        if (own.(ownfield))
            remove(own.(ownfield));
        own.(ownfield) = wp;
        wp.owned_by_field = ownfield;
    }
    wp.fade_rate = maxdistance;
    wp.think = WaypointSprite_Think;
    wp.nextthink = time;
    wp.model1 = spr.netname;
    wp.customizeentityforclient = WaypointSprite_Customize;
    wp.waypointsprite_visible_for_player = WaypointSprite_visible_for_player;
    wp.reset2 = WaypointSprite_Reset;
    wp.cnt = icon;
    wp.colormod = spr.m_color;
    Net_LinkEntity(wp, false, 0, WaypointSprite_SendEntity);
    return wp;
}

entity WaypointSprite_SpawnFixed(
    entity spr,
    vector ofs,
    entity own,
    .entity ownfield,
    float icon // initial icon
)
{
    return WaypointSprite_Spawn(spr, 0, 0, world, ofs, world, 0, own, ownfield, true, icon);
}

entity WaypointSprite_DeployFixed(
    entity spr,
    float limited_range,
    vector ofs,
    float icon // initial icon
)
{
    float t;
    if (teamplay)
        t = self.team;
    else
        t = 0;
    float maxdistance;
    if (limited_range)
        maxdistance = waypointsprite_limitedrange;
    else
        maxdistance = 0;
    return WaypointSprite_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, world, ofs, world, t, self, waypointsprite_deployed_fixed, false, icon);
}

entity WaypointSprite_DeployPersonal(
    entity spr,
    vector ofs,
    float icon // initial icon
)
{
    return WaypointSprite_Spawn(spr, 0, 0, world, ofs, world, 0, self, waypointsprite_deployed_personal, false, icon);
}

entity WaypointSprite_Attach(
    entity spr,
    float limited_range,
    float icon // initial icon
)
{
    float t;
    if (self.waypointsprite_attachedforcarrier)
        return world; // can't attach to FC
    if (teamplay)
        t = self.team;
    else
        t = 0;
    float maxdistance;
    if (limited_range)
        maxdistance = waypointsprite_limitedrange;
    else
        maxdistance = 0;
    return WaypointSprite_Spawn(spr, waypointsprite_deployed_lifetime, maxdistance, self, '0 0 64', world, t, self, waypointsprite_attached, false, icon);
}

entity WaypointSprite_AttachCarrier(
    entity spr,
    entity carrier,
    float icon // initial icon and color
)
{
    WaypointSprite_Kill(carrier.waypointsprite_attached); // FC overrides attached
    entity e = WaypointSprite_Spawn(spr, 0, 0, carrier, '0 0 64', world, carrier.team, carrier, waypointsprite_attachedforcarrier, false, icon);
    if (e)
    {
        WaypointSprite_UpdateMaxHealth(e, '1 0 0' * healtharmor_maxdamage(start_health, start_armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON) * 2);
        WaypointSprite_UpdateHealth(e, '1 0 0' * healtharmor_maxdamage(carrier.health, carrier.armorvalue, autocvar_g_balance_armor_blockpercent, DEATH_WEAPON));
    }
    return e;
}

void WaypointSprite_DetachCarrier(entity carrier)
{
    WaypointSprite_Disown(carrier.waypointsprite_attachedforcarrier, waypointsprite_deadlifetime);
}

void WaypointSprite_ClearPersonal()
{
    WaypointSprite_Kill(self.waypointsprite_deployed_personal);
}

void WaypointSprite_ClearOwned()
{
    WaypointSprite_Kill(self.waypointsprite_deployed_fixed);
    WaypointSprite_Kill(self.waypointsprite_deployed_personal);
    WaypointSprite_Kill(self.waypointsprite_attached);
}

void WaypointSprite_PlayerDead()
{
    WaypointSprite_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
    WaypointSprite_DetachCarrier(self);
}

void WaypointSprite_PlayerGone()
{
    WaypointSprite_Disown(self.waypointsprite_deployed_fixed, waypointsprite_deadlifetime);
    WaypointSprite_Kill(self.waypointsprite_deployed_personal);
    WaypointSprite_Disown(self.waypointsprite_attached, waypointsprite_deadlifetime);
    WaypointSprite_DetachCarrier(self);
}
#endif
