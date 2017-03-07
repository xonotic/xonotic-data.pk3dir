#include "damagetext.qh"

#include "lib/math.qh"

#define DAMAGETEXT_PRECISION_MULTIPLIER 128
#define DAMAGETEXT_SHORT_LIMIT 256 // the smallest value that we can't send as short - 2^15 (signed short) / DAMAGETEXT_PRECISION_MULTIPLIER

const int DTFLAG_SAMETEAM = BIT(0);
const int DTFLAG_BIG_HEALTH = BIT(1);
const int DTFLAG_BIG_ARMOR = BIT(2);
const int DTFLAG_BIG_POTENTIAL = BIT(3);
const int DTFLAG_NO_ARMOR = BIT(4);
const int DTFLAG_NO_POTENTIAL = BIT(5);

REGISTER_MUTATOR(damagetext, true);

// || defined(MENUQC)
#if defined(CSQC)
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
AUTOCVAR_SAVE(cl_damagetext_velocity,               vector, '0 0 20',   "Damage text move direction");
AUTOCVAR_SAVE(cl_damagetext_offset,                 vector, '0 -40 0',  "Damage text offset");
AUTOCVAR_SAVE(cl_damagetext_accumulate_range,       float,  30,         "Damage text spawned within this range is accumulated");
AUTOCVAR_SAVE(cl_damagetext_accumulate_alpha_rel,   float,  0.65,       "Only update existing damage text when it's above this much percentage (0 to 1) of the starting alpha");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire,           bool,   true,       "Show damage text for friendlyfire too");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire_color,     vector, '1 0 0',    "Damage text color for friendlyfire");
#endif

#ifdef CSQC
CLASS(DamageText, Object)
    ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color);
    ATTRIB(DamageText, m_color_friendlyfire, vector, autocvar_cl_damagetext_friendlyfire_color);
    ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size_min);
    ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start);
    ATTRIB(DamageText, fade_rate, float, 1 / autocvar_cl_damagetext_alpha_lifetime);
    ATTRIB(DamageText, velocity, vector, autocvar_cl_damagetext_velocity);
    ATTRIB(DamageText, m_group, int, 0);
    ATTRIB(DamageText, m_friendlyfire, bool, false);
    ATTRIB(DamageText, m_healthdamage, int, 0);
    ATTRIB(DamageText, m_armordamage, int, 0);
    ATTRIB(DamageText, m_potential_damage, int, 0);
    ATTRIB(DamageText, m_deathtype, int, 0);
    ATTRIB(DamageText, time_prev, float, time);
    ATTRIB(DamageText, text, string, string_null);

    void DamageText_draw2d(DamageText this) {
        float dt = time - this.time_prev;
        this.time_prev = time;
        setorigin(this, this.origin + dt * this.velocity);
        this.alpha -= dt * this.fade_rate;
        if (this.alpha < 0) delete(this);
        vector pos = project_3d_to_2d(this.origin) + autocvar_cl_damagetext_offset;
        if (pos.z >= 0 && this.m_size > 0) {
            pos.z = 0;
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
            drawfontscale = (this.m_size / autocvar_cl_damagetext_size_max) * '1 1 0';
            drawcolorcodedstring2_builtin(pos, this.text, autocvar_cl_damagetext_size_max * '1 1 0', rgb, this.alpha, DRAWFLAG_NORMAL);
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
        this.alpha = autocvar_cl_damagetext_alpha_start;

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

        if (this.text) strunzone(this.text);
        this.text = strzone(s);

        float size_range = autocvar_cl_damagetext_size_max - autocvar_cl_damagetext_size_min;
        float damage_range = autocvar_cl_damagetext_size_max_damage - autocvar_cl_damagetext_size_min_damage;
        float scale_factor = size_range / damage_range;
        this.m_size = bound(
            autocvar_cl_damagetext_size_min,
            (potential - autocvar_cl_damagetext_size_min_damage) * scale_factor + autocvar_cl_damagetext_size_min,
            autocvar_cl_damagetext_size_max);
    }

    CONSTRUCTOR(DamageText, int _group, vector _origin, int _health, int _armor, int _potential_damage, int _deathtype, bool _friendlyfire) {
        CONSTRUCT(DamageText);
        this.m_group = _group;
        this.m_friendlyfire = _friendlyfire;
        DamageText_update(this, _origin, _health, _armor, _potential_damage, _deathtype);
		IL_PUSH(g_drawables_2d, this);
    }

    DESTRUCTOR(DamageText) {
        if (this.text) strunzone(this.text);
    }
ENDCLASS(DamageText)
#endif

REGISTER_NET_TEMP(damagetext)

#ifdef SVQC
AUTOCVAR(sv_damagetext, int, 2, "<= 0: disabled, >= 1: spectators, >= 2: players, >= 3: all players");
#define SV_DAMAGETEXT_DISABLED()        (autocvar_sv_damagetext <= 0 /* disabled */)
#define SV_DAMAGETEXT_SPECTATORS_ONLY() (autocvar_sv_damagetext >= 1 /* spectators only */)
#define SV_DAMAGETEXT_PLAYERS()         (autocvar_sv_damagetext >= 2 /* players */)
#define SV_DAMAGETEXT_ALL()             (autocvar_sv_damagetext >= 3 /* all players */)
MUTATOR_HOOKFUNCTION(damagetext, PlayerDamaged) {
    if (SV_DAMAGETEXT_DISABLED()) return;
    const entity attacker = M_ARGV(0, entity);
    const entity hit = M_ARGV(1, entity); if (hit == attacker) return;
    const float health = M_ARGV(2, float);
    const float armor = M_ARGV(3, float);
    const int deathtype = M_ARGV(5, int);
    const float potential_damage = M_ARGV(6, float);
    const vector location = hit.origin;
    FOREACH_CLIENT(IS_REAL_CLIENT(it), LAMBDA(
        if (
            (SV_DAMAGETEXT_ALL()) ||
            (SV_DAMAGETEXT_PLAYERS() && it == attacker) ||
            (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_SPEC(it) && it.enemy == attacker) ||
            (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_OBSERVER(it))
        ) {
            int flags = 0;
            if (SAME_TEAM(hit, attacker)) flags |= DTFLAG_SAMETEAM;
            if (health >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_HEALTH;
            if (armor >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_ARMOR;
            if (potential_damage >= DAMAGETEXT_SHORT_LIMIT) flags |= DTFLAG_BIG_POTENTIAL;
            if (!armor) flags |= DTFLAG_NO_ARMOR;
            if (almost_equals_eps(armor + health, potential_damage, 5)) flags |= DTFLAG_NO_POTENTIAL;

            msg_entity = it;
            WriteHeader(MSG_ONE, damagetext);
            WriteEntity(MSG_ONE, hit);
            WriteCoord(MSG_ONE, location.x);
            WriteCoord(MSG_ONE, location.y);
            WriteCoord(MSG_ONE, location.z);
            WriteInt24_t(MSG_ONE, deathtype);
            WriteByte(MSG_ONE, flags);

            // we need to send a few decimal places to minimize errors when accumulating damage
            // sending them multiplied saves bandwidth compared to using WriteCoord,
            // however if the multiplied damage would be too much for (signed) short, we send an int24
            if (flags & DTFLAG_BIG_HEALTH) WriteInt24_t(MSG_ONE, health * DAMAGETEXT_PRECISION_MULTIPLIER);
            else WriteShort(MSG_ONE, health * DAMAGETEXT_PRECISION_MULTIPLIER);
            if (!(flags & DTFLAG_NO_ARMOR))
            {
                if (flags & DTFLAG_BIG_ARMOR) WriteInt24_t(MSG_ONE, armor * DAMAGETEXT_PRECISION_MULTIPLIER);
                else WriteShort(MSG_ONE, armor * DAMAGETEXT_PRECISION_MULTIPLIER);
            }
            if (!(flags & DTFLAG_NO_POTENTIAL))
            {
                if (flags & DTFLAG_BIG_POTENTIAL) WriteInt24_t(MSG_ONE, potential_damage * DAMAGETEXT_PRECISION_MULTIPLIER);
                else WriteShort(MSG_ONE, potential_damage * DAMAGETEXT_PRECISION_MULTIPLIER);
			}
        }
    ));
}
#endif

#ifdef CSQC
NET_HANDLE(damagetext, bool isNew)
{
    int group = ReadShort();
    vector location = vec3(ReadCoord(), ReadCoord(), ReadCoord());
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
    if (autocvar_cl_damagetext) {
        if (friendlyfire && !autocvar_cl_damagetext_friendlyfire) {
            return;
        }
        if (autocvar_cl_damagetext_accumulate_range) {
            for (entity e = findradius(location, autocvar_cl_damagetext_accumulate_range); e; e = e.chain) {
                if (e.instanceOfDamageText && e.m_group == group && e.alpha > autocvar_cl_damagetext_accumulate_alpha_rel * autocvar_cl_damagetext_alpha_start) {
                    DamageText_update(e, location, e.m_healthdamage + health, e.m_armordamage + armor, e.m_potential_damage + potential_damage, deathtype);
                    return;
                }
            }
        }
        make_impure(NEW(DamageText, group, location, health, armor, potential_damage, deathtype, friendlyfire));
    }
}
#endif

#ifdef MENUQC

#include <menu/gamesettings.qh>

CLASS(XonoticDamageTextSettings, XonoticTab)
    REGISTER_SETTINGS(damagetext, NEW(XonoticDamageTextSettings));
    ATTRIB(XonoticDamageTextSettings, title, string, _("Damage text"));
    ATTRIB(XonoticDamageTextSettings, intendedWidth, float, 0.9);
    ATTRIB(XonoticDamageTextSettings, rows, float, 15.5);
    ATTRIB(XonoticDamageTextSettings, columns, float, 5);
    INIT(XonoticDamageTextSettings) { this.configureDialog(this); }
    METHOD(XonoticDamageTextSettings, showNotify, void(entity this)) { loadAllCvars(this); }
    METHOD(XonoticDamageTextSettings, fill, void(entity this))
    {
    	entity e;
        this.gotoRC(this, 0, 1); this.setFirstColumn(this, this.currentColumn);
            this.TD(this, 1, 3, makeXonoticCheckBox(0, "cl_damagetext", _("Draw damage numbers")));
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Font size minimum:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_min"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Font size maximum:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size_max"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Accumulate range:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 500, 1, "cl_damagetext_accumulate_range"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Lifetime:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 10, 1, "cl_damagetext_alpha_lifetime"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_color", "cl_damagetext_color"));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
        this.TR(this);
        // friendly fire
            this.TD(this, 1, 3, e = makeXonoticCheckBox(0, "cl_damagetext_friendlyfire", _("Draw damage numbers for friendly fire")));
                setDependent(e, "cl_damagetext", 1, 1);
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color:")));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_friendlyfire_color", "cl_damagetext_friendlyfire_color"));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
        this.TR(this);
    }
ENDCLASS(XonoticDamageTextSettings)
#endif
