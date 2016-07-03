#ifndef MUTATOR_DAMAGETEXT_H
#define MUTATOR_DAMAGETEXT_H

#ifdef MENUQC
#include <menu/xonotic/tab.qh>
#endif

#endif

#ifdef IMPLEMENTATION
REGISTER_MUTATOR(damagetext, true);

#if defined(CSQC) || defined(MENUQC)
// no translatable cvar description please
AUTOCVAR_SAVE(cl_damagetext,                    bool,   false,      "Draw damage dealt where you hit the enemy");
AUTOCVAR_SAVE(cl_damagetext_format,             string, "-{total}", "How to format the damage text. {health}, {armor}, {total}");
STATIC_INIT(DamageText_LegacyFormat) {
    if (strstrofs(autocvar_cl_damagetext_format, "{", 0) < 0) autocvar_cl_damagetext_format = "-{total}";
}
AUTOCVAR_SAVE(cl_damagetext_color,              vector, '1 1 0',    "Damage text color");
AUTOCVAR_SAVE(cl_damagetext_color_per_weapon,   bool,   false,      "Damage text uses weapon color");
AUTOCVAR_SAVE(cl_damagetext_size,               float,  8,          "Damage text font size");
AUTOCVAR_SAVE(cl_damagetext_alpha_start,        float,  1,          "Damage text initial alpha");
AUTOCVAR_SAVE(cl_damagetext_alpha_lifetime,     float,  3,          "Damage text lifetime in seconds");
AUTOCVAR_SAVE(cl_damagetext_velocity,           vector, '0 0 20',   "Damage text move direction");
AUTOCVAR_SAVE(cl_damagetext_offset,             vector, '0 -40 0',  "Damage text offset");
AUTOCVAR_SAVE(cl_damagetext_accumulate_range,   float,  30,         "Damage text spawned within this range is accumulated");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire,       bool,   true,       "Show damage text for friendlyfire too");
AUTOCVAR_SAVE(cl_damagetext_friendlyfire_color, vector, '1 0 0',    "Damage text color for friendlyfire");
#endif

#ifdef CSQC
CLASS(DamageText, Object)
    ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color)
    ATTRIB(DamageText, m_color_friendlyfire, vector, autocvar_cl_damagetext_friendlyfire_color)
    ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size)
    ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start)
    ATTRIB(DamageText, fade_rate, float, 1 / autocvar_cl_damagetext_alpha_lifetime)
    ATTRIB(DamageText, velocity, vector, autocvar_cl_damagetext_velocity)
    ATTRIB(DamageText, m_group, int, 0)
    ATTRIB(DamageText, m_friendlyfire, bool, false)
    ATTRIB(DamageText, m_damage, int, 0)
    ATTRIB(DamageText, m_armordamage, int, 0)
    ATTRIB(DamageText, m_deathtype, int, 0)
    ATTRIB(DamageText, time_prev, float, time)

    void DamageText_draw2d(DamageText this) {
        float dt = time - this.time_prev;
        this.time_prev = time;
        setorigin(this, this.origin + dt * this.velocity);
        this.alpha -= dt * this.fade_rate;
        if (this.alpha < 0) remove(this);
        vector pos = project_3d_to_2d(this.origin) + autocvar_cl_damagetext_offset;
        if (pos.z >= 0 && this.m_size > 0) {
            pos.z = 0;
            vector rgb;
            if (this.m_friendlyfire) {
                rgb = this.m_color_friendlyfire;
            }
            else {
                rgb = this.m_color;
            }
            if (autocvar_cl_damagetext_color_per_weapon) {
                Weapon w = DEATH_WEAPONOF(this.m_deathtype);
                if (w != WEP_Null) rgb = w.wpcolor;
            }
            string s = autocvar_cl_damagetext_format;
            s = strreplace("{health}", sprintf("%d", this.m_damage), s);
            s = strreplace("{armor}",  sprintf("%d", this.m_armordamage), s);
            s = strreplace("{total}",  sprintf("%d", this.m_damage + this.m_armordamage), s);
            drawcolorcodedstring2_builtin(pos, s, this.m_size * '1 1 0', rgb, this.alpha, DRAWFLAG_NORMAL);
        }
    }
    ATTRIB(DamageText, draw2d, void(DamageText), DamageText_draw2d)

    void DamageText_update(DamageText this, vector _origin, int _health, int _armor, int _deathtype) {
        this.m_damage = _health;
        this.m_armordamage = _armor;
        this.m_deathtype = _deathtype;
        setorigin(this, _origin);
        this.alpha = 1;
    }

    CONSTRUCTOR(DamageText, int _group, vector _origin, int _health, int _armor, int _deathtype, bool _friendlyfire) {
        CONSTRUCT(DamageText);
        this.m_group = _group;
        this.m_friendlyfire = _friendlyfire;
        DamageText_update(this, _origin, _health, _armor, _deathtype);
    }
ENDCLASS(DamageText)
#endif

REGISTER_NET_TEMP(damagetext)

#ifdef SVQC
AUTOCVAR(sv_damagetext, int, 2, _("<= 0: disabled, >= 1: spectators, >= 2: players, >= 3: all players"));
#define SV_DAMAGETEXT_DISABLED()        (autocvar_sv_damagetext <= 0 /* disabled */)
#define SV_DAMAGETEXT_SPECTATORS_ONLY() (autocvar_sv_damagetext >= 1 /* spectators only */)
#define SV_DAMAGETEXT_PLAYERS()         (autocvar_sv_damagetext >= 2 /* players */)
#define SV_DAMAGETEXT_ALL()             (autocvar_sv_damagetext >= 3 /* all players */)
MUTATOR_HOOKFUNCTION(damagetext, PlayerDamaged) {
    if (SV_DAMAGETEXT_DISABLED()) return;
    const entity attacker = M_ARGV(0, entity);
    const entity hit = M_ARGV(1, entity); if (hit == attacker) return;
    const int health = M_ARGV(2, int);
    const int armor = M_ARGV(3, int);
    const int deathtype = M_ARGV(5, int);
    const vector location = hit.origin;
    FOREACH_CLIENT(IS_REAL_CLIENT(it), LAMBDA(
        if (
            (SV_DAMAGETEXT_ALL()) ||
            (SV_DAMAGETEXT_PLAYERS() && it == attacker) ||
            (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_SPEC(it) && it.enemy == attacker) ||
            (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_OBSERVER(it))
        ) {
            msg_entity = it;
            WriteHeader(MSG_ONE, damagetext);
            WriteShort(MSG_ONE, rint(health));
            WriteShort(MSG_ONE, rint(armor));
            WriteEntity(MSG_ONE, hit);
            WriteCoord(MSG_ONE, location.x);
            WriteCoord(MSG_ONE, location.y);
            WriteCoord(MSG_ONE, location.z);
            WriteInt24_t(MSG_ONE, deathtype);
            WriteByte(MSG_ONE, SAME_TEAM(hit, attacker));
        }
    ));
}
#endif

#ifdef CSQC
NET_HANDLE(damagetext, bool isNew)
{
    int health = ReadShort();
    int armor = ReadShort();
    int group = ReadShort();
    vector location = vec3(ReadCoord(), ReadCoord(), ReadCoord());
    int deathtype = ReadInt24_t();
    bool friendlyfire = ReadByte();
    return = true;
    if (autocvar_cl_damagetext) {
        if (friendlyfire && !autocvar_cl_damagetext_friendlyfire) {
            return;
        }
        if (autocvar_cl_damagetext_accumulate_range) {
            for (entity e = findradius(location, autocvar_cl_damagetext_accumulate_range); e; e = e.chain) {
                if (e.instanceOfDamageText && e.m_group == group) {
                    DamageText_update(e, location, e.m_damage + health, e.m_armordamage + armor, deathtype);
                    return;
                }
            }
        }
        NEW(DamageText, group, location, health, armor, deathtype, friendlyfire);
    }
}
#endif

#ifdef MENUQC
CLASS(XonoticDamageTextSettings, XonoticTab)
    #include <menu/gamesettings.qh>
    REGISTER_SETTINGS(damagetext, NEW(XonoticDamageTextSettings));
    ATTRIB(XonoticDamageTextSettings, title, string, _("Damage text"))
    ATTRIB(XonoticDamageTextSettings, intendedWidth, float, 0.9)
    ATTRIB(XonoticDamageTextSettings, rows, float, 15.5)
    ATTRIB(XonoticDamageTextSettings, columns, float, 5)
    INIT(XonoticDamageTextSettings) { this.configureDialog(this); }
    METHOD(XonoticDamageTextSettings, showNotify, void(entity this)) { loadAllCvars(this); }
    METHOD(XonoticDamageTextSettings, fill, void(entity this))
    {
    	entity e;
        this.gotoRC(this, 0, 1); this.setFirstColumn(this, this.currentColumn);
            this.TD(this, 1, 3, makeXonoticCheckBox(0, "cl_damagetext", _("Draw damage numbers")));
        this.TR(this);
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Font size:")));
                setDependent(e, "cl_damagetext", 1, 1);
            this.TD(this, 1, 2, e = makeXonoticSlider(0, 50, 1, "cl_damagetext_size"));
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
            this.TD(this, 1, 1, e = makeXonoticTextLabel(0, _("Color (Friendly Fire):")));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
            this.TD(this, 2, 2, e = makeXonoticColorpickerString("cl_damagetext_friendlyfire_color", "cl_damagetext_friendlyfire_color"));
                setDependentAND(e, "cl_damagetext", 1, 1, "cl_damagetext_friendlyfire", 1, 1);
        this.TR(this);
    }
ENDCLASS(XonoticDamageTextSettings)
#endif
#endif
