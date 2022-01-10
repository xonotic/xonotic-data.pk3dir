#include "cl_damagetext.qh"

// no translatable cvar description please
AUTOCVAR_SAVE(cl_damagetext,                        bool,   true,       "Draw damage dealt where you hit the enemy");
AUTOCVAR_SAVE(cl_damagetext_format,                 string, "-{total}", "How to format the damage text. {health}, {armor}, {total}, {potential}: full damage not capped to target's health, {potential_health}: health damage not capped to target's health");
AUTOCVAR_SAVE(cl_damagetext_format_verbose,         bool,   false,      "{health} shows {potential_health} too when they differ; {total} shows {potential} too when they differ");
AUTOCVAR_SAVE(cl_damagetext_format_hide_redundant,  bool,   false,      "hide {armor} if 0; hide {potential} and {potential_health} when same as actual");
STATIC_INIT(DamageText_LegacyFormat) {
    // damagetext used to be off by default and the cvar got saved in people's configs along with the old format
    // enable damagetext while updating the format for a one time effect
    if (strstrofs(autocvar_cl_damagetext_format, "{", 0) < 0) {
        localcmd("\nseta cl_damagetext 1\n");
        localcmd("\nseta cl_damagetext_format -{total}\n");
    };
}
AUTOCVAR_SAVE(cl_damagetext_color,                  vector, '1 1 0',    "Damage text color");
AUTOCVAR_SAVE(cl_damagetext_color_per_weapon,       bool,   false,      "Damage text uses weapon color");
AUTOCVAR_SAVE(cl_damagetext_size_min,               float,  10,          "Damage text font size for small damage");
AUTOCVAR_SAVE(cl_damagetext_size_min_damage,        float,  25,          "How much damage is considered small");
AUTOCVAR_SAVE(cl_damagetext_size_max,               float,  16,         "Damage text font size for large damage");
AUTOCVAR_SAVE(cl_damagetext_size_max_damage,        float,  140,        "How much damage is considered large");
AUTOCVAR_SAVE(cl_damagetext_alpha_start,            float,  1,          "Damage text initial alpha");
AUTOCVAR_SAVE(cl_damagetext_alpha_lifetime,         float,  3,          "Damage text lifetime in seconds");
AUTOCVAR_SAVE(cl_damagetext_velocity_screen,        vector, '0 0 0',    "Damage text move direction (screen coordinates)");
AUTOCVAR_SAVE(cl_damagetext_velocity_world,         vector, '0 0 20',   "Damage text move direction (world coordinates relative to player's view)");
AUTOCVAR_SAVE(cl_damagetext_offset_screen,          vector, '0 -45 0',  "Damage text offset (screen coordinates)");
AUTOCVAR_SAVE(cl_damagetext_offset_world,           vector, '0 0 0',    "Damage text offset (world coordinates relative to player's view)");
AUTOCVAR_SAVE(cl_damagetext_accumulate_range,       float,  30,         "Damage text spawned within this range is accumulated");
AUTOCVAR_SAVE(cl_damagetext_accumulate_alpha_rel,   float,  0.65,       "Only update existing damage text when it's above this much percentage (0 to 1) of the starting alpha");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire,           int,    1,          "0: never show for friendly fire, 1: when more than 0 damage, 2: always");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire_color,     vector, '1 0 0',    "Damage text color for friendlyfire");

AUTOCVAR_SAVE(cl_damagetext_2d,                     bool,   true,       "Show damagetext in 2D coordinates if the enemy's location is not known");
AUTOCVAR_SAVE(cl_damagetext_2d_pos,                 vector, '0.47 0.53 0',     "2D damage text initial position (X and Y between 0 and 1)");
AUTOCVAR_SAVE(cl_damagetext_2d_alpha_start,         float,  1,          "2D damage text initial alpha");
AUTOCVAR_SAVE(cl_damagetext_2d_alpha_lifetime,      float,  1.3,        "2D damage text lifetime (alpha fading) in seconds");
AUTOCVAR_SAVE(cl_damagetext_2d_size_lifetime,       float,  3,          "2D damage text lifetime (size shrinking) in seconds");
AUTOCVAR_SAVE(cl_damagetext_2d_velocity,            vector, '-25 0 0',  "2D damage text move direction (screen coordinates)");
AUTOCVAR_SAVE(cl_damagetext_2d_overlap_offset,      vector, '0 -15 0',  "Offset 2D damage text by this much to prevent overlapping (screen coordinates)");
AUTOCVAR_SAVE(cl_damagetext_2d_close_range,         float,  125,        "Always use 2D damagetext for hits closer that this");
AUTOCVAR_SAVE(cl_damagetext_2d_out_of_view,         bool,   true,       "Always use 2D damagetext for hits that occurred off-screen");

CLASS(DamageText, Object)
    ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color);
    ATTRIB(DamageText, m_color_friendlyfire, vector, autocvar_cl_damagetext_friendlyfire_color);
    ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size_min);
    ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start);
    ATTRIB(DamageText, fade_rate, float, 0);
    ATTRIB(DamageText, m_shrink_rate, float, 0);
    ATTRIB(DamageText, m_group, int, 0);
    ATTRIB(DamageText, m_friendlyfire, bool, false);
    ATTRIB(DamageText, m_healthdamage, int, 0);
    ATTRIB(DamageText, m_armordamage, int, 0);
    ATTRIB(DamageText, m_potential_damage, int, 0);
    ATTRIB(DamageText, m_deathtype, int, 0);
    ATTRIB(DamageText, hit_time, float, 0);
    ATTRIB(DamageText, text, string, string_null);
    ATTRIB(DamageText, m_screen_coords, bool, false);

    STATIC_ATTRIB(DamageText, screen_first, DamageText, NULL);
    STATIC_ATTRIB(DamageText, screen_count, int, 0);

    void DamageText_draw2d(DamageText this) {
        float since_hit = time - this.hit_time;
        // can't use `dt = hit_time - prev_update_time` because shrinking wouldn't be linear
        float size = this.m_size - since_hit * this.m_shrink_rate * this.m_size;
        float alpha_ = this.alpha - since_hit * this.fade_rate;
        if (alpha_ <= 0 || size <= 0) {
            delete(this);
            return;
        }

        vector screen_pos;
        if (this.m_screen_coords) {
            screen_pos = this.origin + since_hit * autocvar_cl_damagetext_2d_velocity;
        } else {
            vector forward, right, up;
            MAKE_VECTORS(view_angles, forward, right, up);
            vector world_offset = since_hit * autocvar_cl_damagetext_velocity_world + autocvar_cl_damagetext_offset_world;
            vector world_pos = this.origin + world_offset.x * forward + world_offset.y * right + world_offset.z * up;
            screen_pos = project_3d_to_2d(world_pos) + since_hit * autocvar_cl_damagetext_velocity_screen + autocvar_cl_damagetext_offset_screen;
        }
        screen_pos.y += size / 2;

        if (screen_pos.z >= 0) {
            screen_pos.z = 0;
            vector rgb;
            if (this.m_friendlyfire) {
                rgb = this.m_color_friendlyfire;
            } else {
                rgb = this.m_color;
            }
            if (autocvar_cl_damagetext_color_per_weapon) {
                Weapon w = DEATH_WEAPONOF(this.m_deathtype);
                if (w != WEP_Null) rgb = w.wpcolor;
            }

            vector drawfontscale_save = drawfontscale;
            drawfontscale = (size / autocvar_cl_damagetext_size_max) * '1 1 0';
            screen_pos.y -= drawfontscale.x * size / 2;
            drawcolorcodedstring2_builtin(screen_pos, this.text, autocvar_cl_damagetext_size_max * '1 1 0', rgb, alpha_, DRAWFLAG_NORMAL);
            drawfontscale = drawfontscale_save;
        }
    }
    ATTRIB(DamageText, draw2d, void(DamageText), DamageText_draw2d);

    void DamageText_update(DamageText this, vector _origin, int _health, int _armor, int _potential_damage, int _deathtype) {
        this.m_healthdamage = _health;
        this.m_armordamage = _armor;
        this.m_potential_damage = _potential_damage;
        this.m_deathtype = _deathtype;
        setorigin(this, _origin);
        if (this.m_screen_coords) {
            this.alpha = autocvar_cl_damagetext_2d_alpha_start;
        } else {
            this.alpha = autocvar_cl_damagetext_alpha_start;
        }
        this.hit_time = time;

        int health = rint(this.m_healthdamage / DAMAGETEXT_PRECISION_MULTIPLIER);
        int armor = rint(this.m_armordamage / DAMAGETEXT_PRECISION_MULTIPLIER);
        int total = rint((this.m_healthdamage + this.m_armordamage) / DAMAGETEXT_PRECISION_MULTIPLIER);
        int potential = rint(this.m_potential_damage / DAMAGETEXT_PRECISION_MULTIPLIER);
        int potential_health = rint((this.m_potential_damage - this.m_armordamage) / DAMAGETEXT_PRECISION_MULTIPLIER);

        bool redundant = almost_equals_eps(this.m_healthdamage + this.m_armordamage, this.m_potential_damage, 5);

        string s = autocvar_cl_damagetext_format;
        s = strreplace("{armor}", (
            (this.m_armordamage == 0 && autocvar_cl_damagetext_format_hide_redundant)
                ? ""
                : sprintf("%d", armor)
            ), s);
        s = strreplace("{potential}", (
            (redundant && autocvar_cl_damagetext_format_hide_redundant)
                ? ""
                : sprintf("%d", potential)
            ), s);
        s = strreplace("{potential_health}", (
            (redundant && autocvar_cl_damagetext_format_hide_redundant)
                ? ""
                : sprintf("%d", potential_health)
            ), s);

        s = strreplace("{health}", (
            (health == potential_health || !autocvar_cl_damagetext_format_verbose)
                ? sprintf("%d",      health)
                : sprintf("%d (%d)", health, potential_health)
            ), s);
        s = strreplace("{total}", (
            (total == potential || !autocvar_cl_damagetext_format_verbose)
                ? sprintf("%d",      total)
                : sprintf("%d (%d)", total, potential)
            ), s);

        // futureproofing: remove any remaining (unknown) format strings in case we add new ones in the future
        // so players can use them on new servers and still have working damagetext on old ones
        while (true) {
            int opening_pos = strstrofs(s, "{", 0);
            if (opening_pos == -1) break;
            int closing_pos = strstrofs(s, "}", opening_pos);
            if (closing_pos == -1 || closing_pos <= opening_pos) break;
            s = strcat(
                substring(s, 0, opening_pos),
                substring_range(s, closing_pos + 1, strlen(s))
            );
        }

        strcpy(this.text, s);

        this.m_size = map_bound_ranges(potential,
            autocvar_cl_damagetext_size_min_damage, autocvar_cl_damagetext_size_max_damage,
            autocvar_cl_damagetext_size_min, autocvar_cl_damagetext_size_max);
    }

    CONSTRUCTOR(DamageText, int _group, vector _origin, bool _screen_coords, int _health, int _armor, int _potential_damage, int _deathtype, bool _friendlyfire) {
        CONSTRUCT(DamageText);
        this.m_group = _group;
        this.m_friendlyfire = _friendlyfire;
        this.m_screen_coords = _screen_coords;
        if (_screen_coords) {
            this.fade_rate = 1 / autocvar_cl_damagetext_2d_alpha_lifetime;
            this.m_shrink_rate = 1 / autocvar_cl_damagetext_2d_size_lifetime;
        } else {
            this.fade_rate = 1 / autocvar_cl_damagetext_alpha_lifetime;
            this.m_shrink_rate = 0;
        }
        DamageText_update(this, _origin, _health, _armor, _potential_damage, _deathtype);
        IL_PUSH(g_drawables_2d, this);
    }

    DESTRUCTOR(DamageText) {
        strfree(this.text);
        if (this == DamageText_screen_first) {
            // start from 0 offset again, hopefully, others (if any) will have faded away by now
            DamageText_screen_first = NULL;
            DamageText_screen_count = 0;
        }
    }
ENDCLASS(DamageText)

float current_alpha(entity damage_text) {
    // alpha doesn't change - actual alpha is always calculated from the initial value
    return damage_text.alpha - (time - damage_text.hit_time) * damage_text.fade_rate;
}

NET_HANDLE(damagetext, bool isNew)
{
    make_pure(this);
    int server_entity_index = ReadByte();
    int deathtype = ReadInt24_t();
    int flags = ReadByte();
    bool friendlyfire = flags & DTFLAG_SAMETEAM;

    int health, armor, potential_damage;
    if (flags & DTFLAG_BIG_HEALTH) health = ReadInt24_t();
    else health = ReadShort();
    if (flags & DTFLAG_NO_ARMOR) armor = 0;
    else if (flags & DTFLAG_BIG_ARMOR) armor = ReadInt24_t();
    else armor = ReadShort();
    if (flags & DTFLAG_NO_POTENTIAL) potential_damage = health + armor;
    else if (flags & DTFLAG_BIG_POTENTIAL) potential_damage = ReadInt24_t();
    else potential_damage = ReadShort();

    return = true;
    if (!isNew) return;
    if (autocvar_cl_damagetext == 0) return;
    if (friendlyfire) {
        if (autocvar_cl_damagetext_friendlyfire == 0) return;
        if (autocvar_cl_damagetext_friendlyfire == 1 && health == 0 && armor == 0) return;
    }

    int client_entity_index = server_entity_index - 1;
    entity entcs = entcs_receiver(client_entity_index);

    bool can_use_3d = entcs && entcs.has_origin;
    bool too_close = vdist(entcs.origin - view_origin, <, autocvar_cl_damagetext_2d_close_range);
    bool prefer_in_view = autocvar_cl_damagetext_2d_out_of_view && !projected_on_screen(project_3d_to_2d(entcs.origin));
    bool prefer_2d = spectatee_status != -1 && autocvar_cl_damagetext_2d && (too_close || prefer_in_view);

    if (can_use_3d && !prefer_2d) {
        // world coords
        // 1 as min because shotgun sends damagetext per pellet (see https://gitlab.com/xonotic/xonotic-data.pk3dir/issues/1994).
        for (entity e = findradius(entcs.origin, max(autocvar_cl_damagetext_accumulate_range, 1)); e; e = e.chain) {
            if (e.instanceOfDamageText
                && !e.m_screen_coords // we're using origin for both world coords and screen coords so avoid mismatches
                && e.m_group == server_entity_index
                && current_alpha(e) > autocvar_cl_damagetext_accumulate_alpha_rel * autocvar_cl_damagetext_alpha_start) {
                DamageText_update(e, entcs.origin, e.m_healthdamage + health, e.m_armordamage + armor, e.m_potential_damage + potential_damage, deathtype);
                return;
            }
        }
        make_impure(NEW(DamageText, server_entity_index, entcs.origin, false, health, armor, potential_damage, deathtype, friendlyfire));
    } else if (autocvar_cl_damagetext_2d && spectatee_status != -1) {
        // screen coords only
        vector screen_pos = vec2(vid_conwidth * autocvar_cl_damagetext_2d_pos.x, vid_conheight * autocvar_cl_damagetext_2d_pos.y);
        IL_EACH(g_drawables_2d, it.instanceOfDamageText && it.m_screen_coords && it.m_group == server_entity_index, {
            DamageText_update(it, screen_pos, it.m_healthdamage + health, it.m_armordamage + armor, it.m_potential_damage + potential_damage, deathtype);
            return;
        });

        // when hitting multiple enemies, dmgtext would overlap
        if (DamageText_screen_first == NULL) {
            DamageText dt = NEW(DamageText, server_entity_index, screen_pos, true, health, armor, potential_damage, deathtype, friendlyfire);
            make_impure(dt);
            DamageText_screen_first = dt;
            DamageText_screen_count = 1;
        } else {
            screen_pos += autocvar_cl_damagetext_2d_overlap_offset * DamageText_screen_count;
            DamageText_screen_count++;
            make_impure(NEW(DamageText, server_entity_index, screen_pos, true, health, armor, potential_damage, deathtype, friendlyfire));
        }
    }
}
