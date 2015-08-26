REGISTER_MUTATOR(damagetext, true);

#ifdef CSQC
bool autocvar_cl_damagetext = false;
string autocvar_cl_damagetext_format = "-%3$d";
vector autocvar_cl_damagetext_color = '1 1 0';
float autocvar_cl_damagetext_size = 8;
float autocvar_cl_damagetext_alpha_start = 1;
float autocvar_cl_damagetext_alpha_lifetime = 3;
vector autocvar_cl_damagetext_velocity = '0 0 20';
vector autocvar_cl_damagetext_offset = '0 -40 0';
float autocvar_cl_damagetext_accumulate_range = 30;
STATIC_INIT(cl_damagetext) {
    CVAR_DESCRIBE(cl_damagetext, _("Draw damage dealt. 0: disabled, 1: enabled"));
    CVAR_DESCRIBESTR(cl_damagetext_format, _("How to format the damage text. 1$ is health, 2$ is armor, 3$ is both"));
    CVAR_DESCRIBEVEC(cl_damagetext_color, _("Default damage text color"));
    CVAR_DESCRIBE(cl_damagetext_size, _("Damage text font size"));
    CVAR_DESCRIBE(cl_damagetext_alpha_start, _("Damage text initial alpha"));
    CVAR_DESCRIBE(cl_damagetext_alpha_lifetime, _("Damage text lifetime in seconds"));
    CVAR_DESCRIBEVEC(cl_damagetext_velocity, _("Damage text move direction"));
    CVAR_DESCRIBEVEC(cl_damagetext_offset, _("Damage text offset"));
    CVAR_DESCRIBE(cl_damagetext_accumulate_range, _("Damage text spawned within this range is accumulated"));
}

CLASS(DamageText, Object)
    ATTRIB(DamageText, m_color, vector, autocvar_cl_damagetext_color)
    ATTRIB(DamageText, m_size, float, autocvar_cl_damagetext_size)
    ATTRIB(DamageText, alpha, float, autocvar_cl_damagetext_alpha_start)
    ATTRIB(DamageText, fade_rate, float, 1 / autocvar_cl_damagetext_alpha_lifetime)
    ATTRIB(DamageText, velocity, vector, autocvar_cl_damagetext_velocity)
    ATTRIB(DamageText, m_group, int, 0)
    ATTRIB(DamageText, m_damage, int, 0)
    ATTRIB(DamageText, m_armordamage, int, 0)
    ATTRIB(DamageText, time_prev, float, time)

    void DamageText_draw() {
        entity this = self;
        float dt = time - this.time_prev;
        this.time_prev = time;
        setorigin(this, this.origin + dt * this.velocity);
        this.alpha -= dt * this.fade_rate;
        if (this.alpha < 0) remove(this);
        vector pos = project_3d_to_2d(this.origin) + autocvar_cl_damagetext_offset;
        if (pos.z >= 0 && this.m_size > 0) {
            pos.z = 0;
            string s = sprintf(autocvar_cl_damagetext_format, this.m_damage, this.m_armordamage, this.m_damage + this.m_armordamage);
            drawcolorcodedstring2(pos, s, this.m_size * '1 1 0', this.m_color, this.alpha, DRAWFLAG_NORMAL);
        }
    }
    ATTRIB(DamageText, draw2d, void(), DamageText_draw)

    void DamageText_update(DamageText this, vector _origin, int _health, int _armor) {
        this.m_damage = _health;
        this.m_armordamage = _armor;
        setorigin(this, _origin);
        this.alpha = 1;
    }

    CONSTRUCTOR(DamageText, int _group, vector _origin, int _health, int _armor) {
        CONSTRUCT(DamageText);
        this.m_group = _group;
        DamageText_update(this, _origin, _health, _armor);
    }
ENDCLASS(DamageText)
#endif

#ifdef SVQC
int autocvar_sv_damagetext = 2;
STATIC_INIT(sv_damagetext) {
    CVAR_DESCRIBE(sv_damagetext, _("<= 0: disabled, >= 1: spectators, >= 2: players, >= 3: all players"));
}
#define SV_DAMAGETEXT_DISABLED()        (autocvar_sv_damagetext <= 0 /* disabled */)
#define SV_DAMAGETEXT_SPECTATORS_ONLY() (autocvar_sv_damagetext >= 1 /* spectators only */)
#define SV_DAMAGETEXT_PLAYERS()         (autocvar_sv_damagetext >= 2 /* players */)
#define SV_DAMAGETEXT_ALL()             (autocvar_sv_damagetext >= 3 /* all players */)
MUTATOR_HOOKFUNCTION(damagetext, PlayerDamaged) {
    if (SV_DAMAGETEXT_DISABLED()) return;
    const entity attacker = mutator_argv_entity_0;
    const entity hit = mutator_argv_entity_1; if (hit == attacker) return;
    const int health = mutator_argv_int_0;
    const int armor = mutator_argv_int_1;
    const vector location = hit.origin;
    entity e;
    FOR_EACH_REALCLIENT(e) if (
        (SV_DAMAGETEXT_ALL()) ||
        (SV_DAMAGETEXT_PLAYERS() && e == attacker) ||
        (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_SPEC(e) && e.enemy == attacker) ||
        (SV_DAMAGETEXT_SPECTATORS_ONLY() && IS_OBSERVER(e))
    ) {
        msg_entity = e;
        WriteByte(MSG_ONE, SVC_TEMPENTITY);
        WriteMutator(MSG_ONE, damagetext);
        WriteShort(MSG_ONE, health);
        WriteShort(MSG_ONE, armor);
        WriteEntity(MSG_ONE, hit);
        WriteCoord(MSG_ONE, location.x);
        WriteCoord(MSG_ONE, location.y);
        WriteCoord(MSG_ONE, location.z);
    }
}
#endif

#ifdef CSQC
MUTATOR_HOOKFUNCTION(damagetext, CSQC_Parse_TempEntity) {
    if (MUTATOR_RETURNVALUE) return false;
    if (!ReadMutatorEquals(mutator_argv_int_0, damagetext)) return false;
    int health = ReadShort();
    int armor = ReadShort();
    int group = ReadShort();
    vector location = vec3(ReadCoord(), ReadCoord(), ReadCoord());
    if (autocvar_cl_damagetext) {
        if (autocvar_cl_damagetext_accumulate_range) {
            for (entity e = findradius(location, autocvar_cl_damagetext_accumulate_range); e; e = e.chain) {
                if (e.instanceOfDamageText && e.m_group == group) {
                    DamageText_update(e, location, e.m_damage + health, e.m_armordamage + armor);
                    return true;
                }
            }
        }
        NEW(DamageText, group, location, health, armor);
    }
    return true;
}
#endif
