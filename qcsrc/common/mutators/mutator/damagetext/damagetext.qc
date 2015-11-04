#ifndef MUTATOR_DAMAGETEXT_H
#define MUTATOR_DAMAGETEXT_H

#ifdef MENUQC
#include "../../../../menu/xonotic/tab.qc"
#endif

#endif

#ifdef IMPLEMENTATION
REGISTER_MUTATOR(damagetext, true);

#if defined(CSQC) || defined(MENUQC)
AUTOCVAR_SAVE(cl_damagetext,                    bool,   false,      _("Draw damage dealt. 0: disabled, 1: enabled"));
AUTOCVAR_SAVE(cl_damagetext_format,             string, "-%3$d",    _("How to format the damage text. 1$ is health, 2$ is armor, 3$ is both"));
AUTOCVAR_SAVE(cl_damagetext_color,              vector, '1 1 0',    _("Default damage text color"));
AUTOCVAR_SAVE(cl_damagetext_color_per_weapon,   bool,   false,      _("Damage text uses weapon color"));
AUTOCVAR_SAVE(cl_damagetext_size,               float,  8,          _("Damage text font size"));
AUTOCVAR_SAVE(cl_damagetext_alpha_start,        float,  1,          _("Damage text initial alpha"));
AUTOCVAR_SAVE(cl_damagetext_alpha_lifetime,     float,  3,          _("Damage text lifetime in seconds"));
AUTOCVAR_SAVE(cl_damagetext_velocity,           vector, '0 0 20',   _("Damage text move direction"));
AUTOCVAR_SAVE(cl_damagetext_offset,             vector, '0 -40 0',  _("Damage text offset"));
AUTOCVAR_SAVE(cl_damagetext_accumulate_range,   float,  30,         _("Damage text spawned within this range is accumulated"));
#endif

#ifdef CSQC
CLASS(DamageText, Object)
    ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color)
    ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size)
    ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start)
    ATTRIB(DamageText, fade_rate, float, 1 / autocvar_cl_damagetext_alpha_lifetime)
    ATTRIB(DamageText, velocity, vector, autocvar_cl_damagetext_velocity)
    ATTRIB(DamageText, m_group, int, 0)
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
            vector rgb = this.m_color;
            if (autocvar_cl_damagetext_color_per_weapon) {
                Weapon w = DEATH_WEAPONOF(this.m_deathtype);
                if (w != WEP_Null) rgb = w.wpcolor;
            }
            string s = sprintf(autocvar_cl_damagetext_format, this.m_damage, this.m_armordamage, this.m_damage + this.m_armordamage);
            drawcolorcodedstring2(pos, s, this.m_size * '1 1 0', rgb, this.alpha, DRAWFLAG_NORMAL);
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

    CONSTRUCTOR(DamageText, int _group, vector _origin, int _health, int _armor, int _deathtype) {
        CONSTRUCT(DamageText);
        this.m_group = _group;
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
    const entity attacker = MUTATOR_ARGV(0, entity);
    const entity hit = MUTATOR_ARGV(1, entity); if (hit == attacker) return;
    const int health = MUTATOR_ARGV(0, int);
    const int armor = MUTATOR_ARGV(1, int);
    const int deathtype = MUTATOR_ARGV(2, int);
    const vector location = hit.origin;
    entity e;
    FOR_EACH_REALCLIENT(e) if (
        (SV_DAMAGETEXT_ALL()) ||
        (SV_DAMAGETEXT_PLAYERS() && e == attacker) ||
        (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_SPEC(e) && e.enemy == attacker) ||
        (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_OBSERVER(e))
    ) {
        msg_entity = e;
        WriteHeader(MSG_ONE, damagetext);
        WriteShort(MSG_ONE, health);
        WriteShort(MSG_ONE, armor);
        WriteEntity(MSG_ONE, hit);
        WriteCoord(MSG_ONE, location.x);
        WriteCoord(MSG_ONE, location.y);
        WriteCoord(MSG_ONE, location.z);
        WriteInt24_t(MSG_ONE, deathtype);
    }
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
    return = true;
    if (autocvar_cl_damagetext) {
        if (autocvar_cl_damagetext_accumulate_range) {
            for (entity e = findradius(location, autocvar_cl_damagetext_accumulate_range); e; e = e.chain) {
                if (e.instanceOfDamageText && e.m_group == group) {
                    DamageText_update(e, location, e.m_damage + health, e.m_armordamage + armor, deathtype);
                    return;
                }
            }
        }
        NEW(DamageText, group, location, health, armor, deathtype);
    }
}
#endif

#ifdef MENUQC
CLASS(XonoticDamageTextSettings, XonoticTab)
    #include "../../../../menu/gamesettings.qh"
    REGISTER_SETTINGS(damagetext, NEW(XonoticDamageTextSettings));
    ATTRIB(XonoticDamageTextSettings, title, string, _("Damage text"))
    ATTRIB(XonoticDamageTextSettings, intendedWidth, float, 0.9)
    ATTRIB(XonoticDamageTextSettings, rows, float, 13)
    ATTRIB(XonoticDamageTextSettings, columns, float, 5)
    INIT(XonoticDamageTextSettings) { this.configureDialog(this); }
    METHOD(XonoticDamageTextSettings, showNotify, void(entity this)) { loadAllCvars(this); }
    METHOD(XonoticDamageTextSettings, fill, void(entity this))
    {
        this.gotoRC(this, 0, 1); this.setFirstColumn(this, this.currentColumn);
            this.TD(this, 1, 3, makeXonoticCheckBox(0, "cl_damagetext", _("Draw damage numbers")));
        this.TR(this);
            this.TD(this, 1, 1, makeXonoticTextLabel(0, _("Font size:")));
            this.TD(this, 1, 2, makeXonoticSlider(0, 50, 1, "cl_damagetext_size"));
        this.TR(this);
            this.TD(this, 1, 1, makeXonoticTextLabel(0, _("Accumulate range:")));
            this.TD(this, 1, 2, makeXonoticSlider(0, 500, 1, "cl_damagetext_accumulate_range"));
        this.TR(this);
            this.TD(this, 1, 1, makeXonoticTextLabel(0, _("Lifetime:")));
            this.TD(this, 1, 2, makeXonoticSlider(0, 10, 1, "cl_damagetext_alpha_lifetime"));
        this.TR(this);
            this.TD(this, 1, 1, makeXonoticTextLabel(0, _("Color:")));
            this.TD(this, 2, 2, makeXonoticColorpickerString("cl_damagetext_color", "cl_damagetext_color"));
    }
ENDCLASS(XonoticDamageTextSettings)
#endif
#endif
