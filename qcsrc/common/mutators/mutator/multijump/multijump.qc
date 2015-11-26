#ifdef IMPLEMENTATION
#ifdef SVQC
	#include "../../../../server/antilag.qh"
#endif
#include "../../../physics.qh"


#if defined(SVQC)
void multijump_AddStats();

REGISTER_MUTATOR(multijump, cvar("g_multijump"))
{
	MUTATOR_ONADD
	{
		multijump_AddStats();
	}
	return false;
}
#elif defined(CSQC)
REGISTER_MUTATOR(multijump, true);
#endif

.int multijump_count;
.bool multijump_ready;

#ifdef CSQC

bool autocvar_cl_multijump = true;

#define PHYS_MULTIJUMP 				getstati(STAT_MULTIJUMP)
#define PHYS_MULTIJUMP_SPEED 		getstatf(STAT_MULTIJUMP_SPEED)
#define PHYS_MULTIJUMP_ADD 			getstati(STAT_MULTIJUMP_ADD)
#define PHYS_MULTIJUMP_MAXSPEED 	getstatf(STAT_MULTIJUMP_MAXSPEED)
#define PHYS_MULTIJUMP_DODGING 		getstati(STAT_MULTIJUMP_DODGING)
#define PHYS_MULTIJUMP_COUNT(s) 	getstati(STAT_MULTIJUMP_COUNT)
#define PHYS_MULTIJUMP_CLIENT(s)	autocvar_cl_multijump

#elif defined(SVQC)

.bool cvar_cl_multijump;

int autocvar_g_multijump;
float autocvar_g_multijump_add;
float autocvar_g_multijump_speed;
float autocvar_g_multijump_maxspeed;
float autocvar_g_multijump_dodging = 1;

#define PHYS_MULTIJUMP 				autocvar_g_multijump
#define PHYS_MULTIJUMP_SPEED 		autocvar_g_multijump_speed
#define PHYS_MULTIJUMP_ADD 			autocvar_g_multijump_add
#define PHYS_MULTIJUMP_MAXSPEED 	autocvar_g_multijump_maxspeed
#define PHYS_MULTIJUMP_DODGING 		autocvar_g_multijump_dodging
#define PHYS_MULTIJUMP_COUNT(s) 	(s).multijump_count
#define PHYS_MULTIJUMP_CLIENT(s)	(s).cvar_cl_multijump

.float stat_multijump;
.float stat_multijump_speed;
.float stat_multijump_add;
.float stat_multijump_maxspeed;
.float stat_multijump_dodging;

void multijump_UpdateStats(entity this)
{
	this.stat_multijump = PHYS_MULTIJUMP;
	this.stat_multijump_speed = PHYS_MULTIJUMP_SPEED;
	this.stat_multijump_add = PHYS_MULTIJUMP_ADD;
	this.stat_multijump_maxspeed = PHYS_MULTIJUMP_MAXSPEED;
	this.stat_multijump_dodging = PHYS_MULTIJUMP_DODGING;
}

void multijump_AddStats()
{
	addstat(STAT_MULTIJUMP, AS_INT, stat_multijump);
	addstat(STAT_MULTIJUMP_SPEED, AS_FLOAT, stat_multijump_speed);
	addstat(STAT_MULTIJUMP_ADD, AS_INT, stat_multijump_add);
	addstat(STAT_MULTIJUMP_MAXSPEED, AS_FLOAT, stat_multijump_maxspeed);
	addstat(STAT_MULTIJUMP_DODGING, AS_INT, stat_multijump_dodging);
	addstat(STAT_MULTIJUMP_COUNT, AS_INT, multijump_count);
}

#endif

void PM_multijump(entity this)
{
	if(!PHYS_MULTIJUMP) { return; }

	if(IS_ONGROUND(this))
		this.multijump_count = 0;
}

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
#ifdef SVQC
	multijump_UpdateStats(self);
#elif defined(CSQC)
	self.multijump_count = PHYS_MULTIJUMP_COUNT(self);
#endif
	PM_multijump(self);
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
