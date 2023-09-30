#include "casings.qh"

#include <common/replicate.qh>
#include <common/util.qh>

#ifdef CSQC
#include <common/physics/movetypes/movetypes.qh>
#include "rubble.qh"
#endif

REGISTER_NET_TEMP(casings)

REPLICATE(cvar_cl_casings, bool, "cl_casings");
REPLICATE(cvar_r_drawviewmodel, int, "r_drawviewmodel");

#ifdef SVQC
void SpawnCasing(vector vel, vector ang, int casingtype, entity casingowner, .entity weaponentity)
{
	vector org = casingowner.(weaponentity).spawnorigin;
	org = casingowner.origin + casingowner.view_ofs + org.x * v_forward - org.y * v_right + org.z * v_up;

	FOREACH_CLIENT(true, {
		if (!(CS_CVAR(it).cvar_cl_casings))
			continue;

		casingtype &= 0x3F; // reset any bitflags that were set for the previous client

		if (it == casingowner || (IS_SPEC(it) && it.enemy == casingowner))
		{
			if (!(CS_CVAR(it).cvar_r_drawviewmodel))
				continue;

			casingtype |= 0x40; // client will apply autocvar_cl_gunoffset in first person
		}
		else if (1 & ~checkpvs(it.origin + it.view_ofs, casingowner)) // 1 or 3 means visible
			continue;

		msg_entity = it; // sound_allowed checks this
		if (!sound_allowed(MSG_ONE, it))
			casingtype |= 0x80; // silent

		WriteHeader(MSG_ONE, casings);
		WriteByte(MSG_ONE, casingtype);
		WriteVector(MSG_ONE, org);
		WriteShort(MSG_ONE, compressShortVector(vel)); // actually compressed velocity
		WriteByte(MSG_ONE, ang.x * 256 / 360);
		WriteByte(MSG_ONE, ang.y * 256 / 360);
		// weapons only have pitch and yaw, so no need to send ang.z
	});
}
#endif

#ifdef CSQC
entityclass(Casing);
classfield(Casing) .float alpha;
classfield(Casing) .bool silent;
classfield(Casing) .int state;
classfield(Casing) .float cnt;

// this is only needed because LimitedChildrenRubble() takes a func pointer
void Casing_Delete(entity this)
{
    delete(this);
}

void Casing_Draw(entity this)
{
    if (IS_ONGROUND(this))
    {
        this.angles_x = 0;
        this.angles_z = 0;
        //UNSET_ONGROUND(this);
    }

    this.renderflags = 0;
    this.alpha = bound(0, this.cnt - time, 1);

    if (this.alpha < ALPHA_MIN_VISIBLE)
    {
        delete(this);
        this.drawmask = 0;
        return;
    }

    trace_startsolid = 0; // due to cl_casings_ticrate, traces are not always performed
    Movetype_Physics_MatchTicrate(this, autocvar_cl_casings_ticrate, autocvar_cl_casings_sloppy);
    //if (wasfreed(this))
    //    return; // deleted by touch function

    // prevent glitchy casings when the gun model is poking into a wall
    // doing this here is cheaper than doing it on the server as the client performs the trace anyway
    if (trace_startsolid)
    {
        delete(this);
        this.drawmask = 0;
        return;
    }
}

SOUND(BRASS1, W_Sound("brass1"));
SOUND(BRASS2, W_Sound("brass2"));
SOUND(BRASS3, W_Sound("brass3"));
Sound SND_BRASS_RANDOM() {
    return REGISTRY_GET(Sounds, SND_BRASS1.m_id + floor(prandom() * 3));
}
SOUND(CASINGS1, W_Sound("casings1"));
SOUND(CASINGS2, W_Sound("casings2"));
SOUND(CASINGS3, W_Sound("casings3"));
Sound SND_CASINGS_RANDOM() {
    return REGISTRY_GET(Sounds, SND_CASINGS1.m_id + floor(prandom() * 3));
}

void Casing_Touch(entity this, entity toucher)
{
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
    {
        delete(this);
        return;
    }

    if (!this.silent)
    if (!trace_ent || trace_ent.solid == SOLID_BSP)
    {
        if(vdist(this.velocity, >, 50))
        {
            if (time >= this.nextthink)
            {
                Sound s;
                switch (this.state)
                {
                    case 1:
                        s = SND_CASINGS_RANDOM();
                        break;
                    default:
                        s = SND_BRASS_RANDOM();
                        break;
                }

                sound (this, CH_SHOTS, s, VOL_BASE, ATTEN_LARGE);
            }
        }
    }

    this.nextthink = time + 0.2;
}

void Casing_Damage(entity this, float thisdmg, int hittype, vector org, vector thisforce)
{
    if (thisforce.z < 0)
        thisforce.z = 0;
    this.velocity = this.velocity + thisforce + '0 0 100';
    UNSET_ONGROUND(this);
}

NET_HANDLE(casings, bool isNew)
{
    Casing casing = ListNewChildRubble(CasingsNGibs, new(casing));

    casing.state = ReadByte();
    casing.origin = ReadVector();
    casing.velocity = decompressShortVector(ReadShort());
    casing.angles_x = ReadByte() * 360 / 256;
    casing.angles_y = ReadByte() * 360 / 256;

    return = true;

    casing.silent = casing.state & 0x80;
    if ((casing.state & 0x40) && !autocvar_chase_active)
        casing.origin += autocvar_cl_gunoffset.x * v_forward
                       - autocvar_cl_gunoffset.y * v_right
                       + autocvar_cl_gunoffset.z * v_up;
    casing.state &= 0x3F; // the 2 most significant bits are reserved for the silent and casingowner bitflags

    setorigin(casing, casing.origin);
    casing.drawmask = MASK_NORMAL;
    casing.draw = Casing_Draw;
    if (isNew) IL_PUSH(g_drawables, casing);
    casing.velocity += 2 * prandomvec();
    casing.avelocity = '0 10 0' + 100 * prandomvec();
    set_movetype(casing, MOVETYPE_BOUNCE);
    settouch(casing, Casing_Touch);
    casing.move_time = time;
    casing.event_damage = Casing_Damage;
    casing.solid = SOLID_TRIGGER;

    switch (casing.state)
    {
        case 1:
            setmodel(casing, MDL_CASING_SHELL);
            casing.bouncefactor = 0.25;
            casing.cnt = time + autocvar_cl_casings_shell_time;
            break;
        default:
            setmodel(casing, MDL_CASING_BULLET);
            casing.bouncefactor = 0.5;
            casing.cnt = time + autocvar_cl_casings_bronze_time;
            break;
    }

    LimitedChildrenRubble(CasingsNGibs, "casing", autocvar_cl_casings_maxcount, Casing_Delete, NULL);
}

#endif
