#include "sv_ring.qh"

.float br_ring_stage;
.float br_ring_stage_strength[BR_RING_STAGE_MAX];
.float br_ring_timelimit;

void ring_link(entity this);
bool ring_send(entity this, entity to, float sf);
void ring_think(entity this);
void ring_newStage(entity this);
bool ring_parseTiming(entity this);
void ring_parseStrength(entity this, bool has_invalid);
void ring_alignPosition(entity this);

float autocvar_g_br_ring_duration = 150;
vector autocvar_g_br_ring_color = '1 0 0'; // FIXME: put visual-only cvar client side?
float autocvar_g_br_ring_alpha = 0.5; // FIXME: put visual-only cvar client side?
float autocvar_g_br_ring_fadedistance = 0.5; // FIXME: put visual-only cvar client side?
float autocvar_g_br_ring_fadedistance_min = 2000; // FIXME: put visual-only cvar client side?
float autocvar_g_br_ring_radius = -1; // useful for per map settings
string autocvar_g_br_ring_timing = "0.6 0.8 0.9";
string autocvar_g_br_ring_strength = "2.5 5 10 20 50";
float autocvar_g_br_ring_wait = 30;
float autocvar_g_br_ring_center_factor = 0.25;

entity ring_initialize()
{
    entity this = spawn();
    this.netname = BR_RING_NAME;

    setsize(this, '0 0 0', '0 0 0');
    set_movetype(this, MOVETYPE_NOCLIP);

    this.classname = "ring";
    this.br_ring_start = time;
    this.br_ring_duration = max(autocvar_g_br_ring_duration, 1);
    this.radius = (autocvar_g_br_ring_radius <= 0) ? vlen(vec2(world.maxs - world.mins)) / 2 : autocvar_g_br_ring_radius;
    this.br_ring_stage = -1;
    this.colormod = autocvar_g_br_ring_color; // TODO: color changing ring
    this.alpha = this.br_ring_alpha = bound(0.01, autocvar_g_br_ring_alpha, 1);
    this.br_ring_fadedistance = max(autocvar_g_br_ring_fadedistance, 0);
    this.br_ring_fadedistance_min = max(autocvar_g_br_ring_fadedistance_min, 1);
    this.br_ring_stage_waittime = max(autocvar_g_br_ring_wait, 0);

    bool has_invalid_timings = ring_parseTiming(this);
    ring_parseStrength(this, has_invalid_timings);

    this.strength = this.br_ring_stage_strength[0];
    if(!MoveToRandomLocationWithinBounds(this, world.mins, world.maxs, DPCONTENTS_SOLID, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 1000, 0, 0, false))
    {
        delete(this);
        return NULL;
    }
    ring_alignPosition(this);
    ring_link(this);

    return this;
}

void ring_link(entity this)
{
    Net_LinkEntity(this, false, 0, ring_send);
    this.nextthink = this.br_ring_start + this.br_ring_stage_waittime;
    this.br_ring_timelimit = this.nextthink - game_starttime;
    ring_timelimit(this);
    setthink(this, ring_think);
}

bool ring_send(entity this, entity to, float sf)
{
    WriteHeader(MSG_ENTITY, ENT_CLIENT_RING);
    WriteByte(MSG_ENTITY, sf);
    if(sf & BR_RING_SETUP)
    {
        WriteVector(MSG_ENTITY, this.origin);
        WriteCoord(MSG_ENTITY, this.br_ring_start);
        WriteCoord(MSG_ENTITY, this.br_ring_duration);
        WriteCoord(MSG_ENTITY, this.radius);
        WriteVector(MSG_ENTITY, this.colormod);
        WriteCoord(MSG_ENTITY, this.br_ring_alpha);
        WriteCoord(MSG_ENTITY, this.br_ring_fadedistance);
        WriteCoord(MSG_ENTITY, this.br_ring_fadedistance_min);

        WriteByte(MSG_ENTITY, this.br_ring_stage_count);
        WriteCoord(MSG_ENTITY, this.br_ring_stage_waittime);
        for(int i = 0; i < (this.br_ring_stage_count + 1); ++i)
            WriteCoord(MSG_ENTITY, this.br_ring_stage_timing[i]);
    }

    if(sf & BR_RING_MOVE)
    {
        WriteVector(MSG_ENTITY, this.origin);
        WriteVector(MSG_ENTITY, this.velocity);
    }

    return true;
}

void ring_think(entity this)
{
    float time_elapsed = time - this.br_ring_start;

    if(time_elapsed >= (this.br_ring_duration + this.br_ring_stage_waittime * this.br_ring_stage_count))
    {
        this.velocity = '0 0 0';
        this.SendFlags |= BR_RING_MOVE; // not really necessary but for completeness sake
        this.nextthink = 0; // ring reached its final state, no further thinking required
    }
    else
    {
        for(int stage = this.br_ring_stage_count - 1; stage >= 0; --stage)
        {
            float stage_duration_current = this.br_ring_duration * this.br_ring_stage_timing[stage];
            stage_duration_current += this.br_ring_stage_waittime * stage;

            float stage_duration_next = this.br_ring_duration * this.br_ring_stage_timing[stage + 1];
            stage_duration_next += this.br_ring_stage_waittime * (stage + 1);

            if(time_elapsed >= (stage_duration_current + this.br_ring_stage_waittime))
            {
                if(stage != this.br_ring_stage)
                {
                    this.br_ring_stage = stage;
                    ring_newStage(this);
                    this.SendFlags |= BR_RING_MOVE;

                    Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_BR_RING_CLOSE, stage + 1);
                }
                this.nextthink = this.br_ring_start + stage_duration_next;
                break;
            }
            else if(time_elapsed >= stage_duration_current)
            {
                if(vlen(this.velocity) > 0)
                {
                    this.velocity = '0 0 0';
                    this.SendFlags |= BR_RING_MOVE;
                }
                this.nextthink = this.br_ring_start + stage_duration_current + this.br_ring_stage_waittime;
                this.br_ring_timelimit = this.nextthink - game_starttime;
                ring_timelimit(this);
                break;
            }
        }
    }
}

void ring_newStage(entity this)
{
    this.strength = this.br_ring_stage_strength[this.br_ring_stage + 1];
    if(this.br_ring_stage > 0) // first stage should center the ring a bit, no moving required
        this.velocity = (this.radius / this.br_ring_duration) * normalize(eX * (random() * 2 - 1) + eY * (random() * 2 - 1));
}

bool ring_parseTiming(entity this)
{
    int num_timings = tokenize(autocvar_g_br_ring_timing);
    if(num_timings > (BR_RING_STAGE_MAX - 2))
    {
        LOG_INFO("too many stages defined by g_br_ring_timing");
        num_timings = BR_RING_STAGE_MAX - 2;
    }
    int invalid_timings = 0;
    for(int i = 0; i < num_timings; ++i)
    {
        float current_timing = stof(argv(i));
        if((current_timing > this.br_ring_stage_timing[i - invalid_timings]) && (current_timing < 1))
            this.br_ring_stage_timing[i + 1 - invalid_timings] = current_timing;
        else
        {
            ++invalid_timings;
            LOG_INFO("invalid timing value \"", argv(i), "\" at position ", itos(i + 1), " in g_br_ring_timing was discarded");
        }
    }
    this.br_ring_stage_count = num_timings + 1 - invalid_timings;
    this.br_ring_stage_timing[0] = 0;
    this.br_ring_stage_timing[this.br_ring_stage_count] = 1;

    return (invalid_timings > 0);
}

void ring_parseStrength(entity this, bool has_invalid)
{
    int num_strength = tokenize(autocvar_g_br_ring_strength);
    if(!has_invalid) // don't warn about this if we already got errors in the timing list
    {
        if(num_strength < (this.br_ring_stage_count + 1))
        {
            LOG_INFO("not enough strength values in g_br_ring_strength for the defined stages in g_br_ring_timing");
        }
        if(num_strength > (this.br_ring_stage_count + 1))
        {
            LOG_INFO("too many strength values in g_br_ring_strength for the defined stages in g_br_ring_timing");
        }
    }
    for(int i = 0; i < (this.br_ring_stage_count + 1); ++i)
    {
        float current_strength;
        float prev_strength = ((i > 0) ? this.br_ring_stage_strength[i - 1] : 1);
        if(i < num_strength)
            current_strength = stof(argv(i));
        else
            current_strength = prev_strength;

        if(current_strength > 0)
            this.br_ring_stage_strength[i] = current_strength;
        else
        {
            this.br_ring_stage_strength[i] = prev_strength;
            LOG_INFO("invalid strength value \"", argv(i), "\" at position ", itos(i + 1), " in g_br_ring_strength replaced with preceeding value \"", ftos(prev_strength), "\"");
        }
    }
}

void ring_timelimit(entity this)
{
    WriteByte(MSG_ALL, 3); // svc_updatestat
    WriteByte(MSG_ALL, 236); // STAT_TIMELIMIT
    WriteCoord(MSG_ALL, this.br_ring_timelimit / 60);
}

void ring_alignPosition(entity this)
{
    float f = bound(0, autocvar_g_br_ring_center_factor, 1);
    vector ringorigin = world.mins + (world.maxs - world.mins) * ((0.5 - f/2) + random() * f);
    ringorigin.z = this.origin.z;

    setorigin(this, ringorigin);
}
