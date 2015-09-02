#include "../../util.qh"

#ifdef CSQC
#include "../../movetypes/movetypes.qh"
#include "../../../client/rubble.qh"
#endif

REGISTER_MUTATOR(casings, true);

#ifdef SVQC
void SpawnCasing(vector vel, float randomvel, vector ang, vector avel, float randomavel, int casingtype, entity casingowner)
{
    vector org = self.origin + self.view_ofs + self.weaponentity.spawnorigin.x * v_forward - self.weaponentity.spawnorigin.y * v_right + self.weaponentity.spawnorigin.z * v_up;

    if (!sound_allowed(MSG_BROADCAST, casingowner))
        casingtype |= 0x80;

    WriteByte(MSG_ALL, SVC_TEMPENTITY);
    WriteMutator(MSG_ALL, casings);
    WriteByte(MSG_ALL, casingtype);
    WriteCoord(MSG_ALL, org.x);
    WriteCoord(MSG_ALL, org.y);
    WriteCoord(MSG_ALL, org.z);
    WriteShort(MSG_ALL, compressShortVector(vel)); // actually compressed velocity
    WriteByte(MSG_ALL, ang.x * 256 / 360);
    WriteByte(MSG_ALL, ang.y * 256 / 360);
    WriteByte(MSG_ALL, ang.z * 256 / 360);
}
#endif

#ifdef CSQC
entityclass(Casing);
class(Casing) .float alpha;
class(Casing) .bool silent;
class(Casing) .int state;
class(Casing) .float cnt;

void Casing_Delete()
{
    remove(self);
}

void Casing_Draw()
{
    if (self.move_flags & FL_ONGROUND)
    {
        self.move_angles_x = 0;
        self.move_angles_z = 0;
        self.flags &= ~FL_ONGROUND;
    }

    Movetype_Physics_MatchTicrate(autocvar_cl_casings_ticrate, autocvar_cl_casings_sloppy);
    if (wasfreed(self))
        return; // deleted by touch function

    self.renderflags = 0;
    self.alpha = bound(0, self.cnt - time, 1);

    if (self.alpha < ALPHA_MIN_VISIBLE)
    {
        Casing_Delete();
        self.drawmask = 0;
    }
}

void Casing_Touch()
{
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
    {
        Casing_Delete();
        return;
    }

    if (!self.silent)
    if (!trace_ent || trace_ent.solid == SOLID_BSP)
    {
        if (vlen(self.velocity) > 50)
        {
            if (time >= self.nextthink)
            {
                string s;
                int f = floor(prandom() * 3) + 1;

                switch (self.state)
                {
                    case 1:
                        s = W_Sound(strcat("casings", itos(f)));
                        break;
                    default:
                        s = W_Sound(strcat("brass", itos(f)));
                        break;
                }

                sound (self, CH_SHOTS, s, VOL_BASE, ATTEN_LARGE);
            }
        }
    }

    self.nextthink = time + 0.2;
}

void Casing_Damage(float thisdmg, int hittype, vector org, vector thisforce)
{
    if (thisforce.z < 0)
        thisforce.z = 0;
    self.move_velocity = self.move_velocity + thisforce + '0 0 100';
    self.move_flags &= ~FL_ONGROUND;
}

MUTATOR_HOOKFUNCTION(casings, CSQC_Parse_TempEntity)
{
    if (MUTATOR_RETURNVALUE) return;
    if (!ReadMutatorEquals(mutator_argv_int_0, casings)) return;
    return = true;

    int _state = ReadByte();
    vector org;
    org_x = ReadCoord();
    org_y = ReadCoord();
    org_z = ReadCoord();
    vector vel = decompressShortVector(ReadShort());
    vector ang;
    ang_x = ReadByte() * 360 / 256;
    ang_y = ReadByte() * 360 / 256;
    ang_z = ReadByte() * 360 / 256;

    if (!autocvar_cl_casings) return;

    Casing casing = RubbleNew("casing");
    casing.silent = (_state & 0x80);
    casing.state = (_state & 0x7F);
    casing.origin = org;
    setorigin(casing, casing.origin);
    casing.velocity = vel;
    casing.angles = ang;
    casing.drawmask = MASK_NORMAL;

    casing.draw = Casing_Draw;
    casing.move_origin = casing.origin;
    casing.move_velocity = casing.velocity + 2 * prandomvec();
    casing.move_angles = casing.angles;
    casing.move_avelocity = '0 250 0' + 100 * prandomvec();
    casing.move_movetype = MOVETYPE_BOUNCE;
    casing.move_touch = Casing_Touch;
    casing.move_time = time;
    casing.event_damage = Casing_Damage;
    casing.solid = SOLID_TRIGGER;

    switch (casing.state)
    {
        case 1:
            setmodel(casing, "models/casing_shell.mdl");
            casing.cnt = time + autocvar_cl_casings_shell_time;
            break;
        default:
            setmodel(casing, "models/casing_bronze.iqm");
            casing.cnt = time + autocvar_cl_casings_bronze_time;
            break;
    }

    setsize(casing, '0 0 -1', '0 0 -1');

    RubbleLimit("casing", autocvar_cl_casings_maxcount, Casing_Delete);
}

STATIC_INIT(Casings)
{
    precache_model("models/casing_shell.mdl");
    precache_model("models/casing_bronze.iqm");
    precache_sound(W_Sound("brass1"));
    precache_sound(W_Sound("brass2"));
    precache_sound(W_Sound("brass3"));
    precache_sound(W_Sound("casings1"));
    precache_sound(W_Sound("casings2"));
    precache_sound(W_Sound("casings3"));
}
#endif
