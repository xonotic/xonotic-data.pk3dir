#ifdef IMPLEMENTATION
#ifdef SVQC
	#include "../../../../server/antilag.qh"
#endif
#include "../../../physics.qh"


#if defined(SVQC)
REGISTER_MUTATOR(multijump, cvar("g_multijump"));
#elif defined(CSQC)
REGISTER_MUTATOR(multijump, true);
#endif

#define PHYS_MULTIJUMP 				STAT(MULTIJUMP, self)
#define PHYS_MULTIJUMP_SPEED 		STAT(MULTIJUMP_SPEED, self)
#define PHYS_MULTIJUMP_ADD 			STAT(MULTIJUMP_ADD, self)
#define PHYS_MULTIJUMP_MAXSPEED 	STAT(MULTIJUMP_MAXSPEED, self)
#define PHYS_MULTIJUMP_DODGING 		STAT(MULTIJUMP_DODGING, self)
#define PHYS_MULTIJUMP_COUNT(s) 	STAT(MULTIJUMP_COUNT, s)

.bool multijump_ready;

#ifdef CSQC
bool autocvar_cl_multijump = false;

	#define PHYS_MULTIJUMP_CLIENT(s)	autocvar_cl_multijump
#elif defined(SVQC)
.bool cvar_cl_multijump;

	#define PHYS_MULTIJUMP_CLIENT(s)	(s).cvar_cl_multijump
#endif

bool PM_multijump_checkjump(entity this)
{
	if(!PHYS_MULTIJUMP) { return false; }

	int client_multijump = PHYS_MULTIJUMP_CLIENT(this);
	if(client_multijump > 1)
		return false; // nope

	if (!IS_JUMP_HELD(this) && !IS_ONGROUND(this) && client_multijump) // jump button pressed this frame and we are in midair
		this.multijump_ready = true;  // this is necessary to check that we released the jump button and pressed it again
	else
		this.multijump_ready = false;

	int phys_multijump = PHYS_MULTIJUMP;

	if(!player_multijump && this.multijump_ready && (PHYS_MULTIJUMP_COUNT(this) < phys_multijump || phys_multijump == -1) && this.velocity_z > PHYS_MULTIJUMP_SPEED && (!PHYS_MULTIJUMP_MAXSPEED || vlen(this.velocity) <= PHYS_MULTIJUMP_MAXSPEED))
	{
		if (PHYS_MULTIJUMP)
		{
			if (!PHYS_MULTIJUMP_ADD) // in this case we make the z velocity == jumpvelocity
			{
				if (this.velocity_z < PHYS_JUMPVELOCITY(this))
				{
					player_multijump = true;
					this.velocity_z = 0;
				}
			}
			else
				player_multijump = true;

			if(player_multijump)
			{
				if(PHYS_MULTIJUMP_DODGING)
				if(this.movement_x != 0 || this.movement_y != 0) // don't remove all speed if player isnt pressing any movement keys
				{
					float curspeed;
					vector wishvel, wishdir;

/*#ifdef SVQC
					curspeed = max(
						vlen(vec2(this.velocity)), // current xy speed
						vlen(vec2(antilag_takebackavgvelocity(this, max(this.lastteleporttime + sys_frametime, time - 0.25), time))) // average xy topspeed over the last 0.25 secs
					);
#elif defined(CSQC)*/
					curspeed = vlen(vec2(this.velocity));
//#endif

					makevectors(this.v_angle_y * '0 1 0');
					wishvel = v_forward * this.movement_x + v_right * this.movement_y;
					wishdir = normalize(wishvel);

					this.velocity_x = wishdir_x * curspeed; // allow "dodging" at a multijump
					this.velocity_y = wishdir_y * curspeed;
					// keep velocity_z unchanged!
				}
				if (PHYS_MULTIJUMP > 0)
				{
					this.multijump_count += 1;
				}
			}
		}
		this.multijump_ready = false; // require releasing and pressing the jump button again for the next jump
	}

	return false;
}

MUTATOR_HOOKFUNCTION(multijump, PlayerPhysics)
{
#ifdef CSQC
	self.multijump_count = PHYS_MULTIJUMP_COUNT(self);
#endif
	if(!PHYS_MULTIJUMP) { return; }

	if(IS_ONGROUND(self))
		self.multijump_count = 0;
	return false;
}

MUTATOR_HOOKFUNCTION(multijump, PlayerJump)
{
	return PM_multijump_checkjump(self);
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(multijump, GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_multijump, "cl_multijump");
	return false;
}

MUTATOR_HOOKFUNCTION(multijump, BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":multijump");
	return false;
}

MUTATOR_HOOKFUNCTION(multijump, BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Multi jump");
	return false;
}

#endif
#endif
