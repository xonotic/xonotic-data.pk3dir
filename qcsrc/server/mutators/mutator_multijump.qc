#ifdef SVQC
	#include "../_all.qh"
	#include "mutator.qh"
	#include "../antilag.qh"
#endif

.int multijump_count;
.bool multijump_ready;
.bool cvar_cl_multijump;

#ifdef CSQC

#define PHYS_MULTIJUMP 				getstati(STAT_MULTIJUMP)
#define PHYS_MULTIJUMP_SPEED 		getstatf(STAT_MULTIJUMP_SPEED)
#define PHYS_MULTIJUMP_ADD 			getstati(STAT_MULTIJUMP_ADD)
#define PHYS_MULTIJUMP_MAXSPEED 	getstatf(STAT_MULTIJUMP_MAXSPEED)
#define PHYS_MULTIJUMP_DODGING 		getstati(STAT_MULTIJUMP_DODGING)

#elif defined(SVQC)

#define PHYS_MULTIJUMP 				autocvar_g_multijump
#define PHYS_MULTIJUMP_SPEED 		autocvar_g_multijump_speed
#define PHYS_MULTIJUMP_ADD 			autocvar_g_multijump_add
#define PHYS_MULTIJUMP_MAXSPEED 	autocvar_g_multijump_maxspeed
#define PHYS_MULTIJUMP_DODGING 		autocvar_g_multijump_dodging


.float stat_multijump;
.float stat_multijump_speed;
.float stat_multijump_add;
.float stat_multijump_maxspeed;
.float stat_multijump_dodging;

void multijump_UpdateStats()
{
	self.stat_multijump = PHYS_MULTIJUMP;
	self.stat_multijump_speed = PHYS_MULTIJUMP_SPEED;
	self.stat_multijump_add = PHYS_MULTIJUMP_ADD;
	self.stat_multijump_maxspeed = PHYS_MULTIJUMP_MAXSPEED;
	self.stat_multijump_dodging = PHYS_MULTIJUMP_DODGING;
}

void multijump_AddStats()
{
	addstat(STAT_MULTIJUMP, AS_INT, stat_multijump);
	addstat(STAT_MULTIJUMP_SPEED, AS_FLOAT, stat_multijump_speed);
	addstat(STAT_MULTIJUMP_ADD, AS_INT, stat_multijump_add);
	addstat(STAT_MULTIJUMP_MAXSPEED, AS_FLOAT, stat_multijump_maxspeed);
	addstat(STAT_MULTIJUMP_DODGING, AS_INT, stat_multijump_dodging);
}

#endif

void PM_multijump()
{
	if(!PHYS_MULTIJUMP) { return; }

	if(IS_ONGROUND(self))
	{
		self.multijump_count = 0;
	}
}

bool PM_multijump_checkjump()
{
	if(!PHYS_MULTIJUMP) { return false; }

#ifdef SVQC
	bool client_multijump = self.cvar_cl_multijump;
#elif defined(CSQC)
	bool client_multijump = cvar("cl_multijump");

	if(cvar("cl_multijump") > 1)
		return false; // nope
#endif

	if (!IS_JUMP_HELD(self) && !IS_ONGROUND(self) && client_multijump) // jump button pressed this frame and we are in midair
		self.multijump_ready = true;  // this is necessary to check that we released the jump button and pressed it again
	else
		self.multijump_ready = false;

	int phys_multijump = PHYS_MULTIJUMP;

#ifdef CSQC
	phys_multijump = (PHYS_MULTIJUMP) ? -1 : 0;
#endif

	if(!player_multijump && self.multijump_ready && (self.multijump_count < phys_multijump || phys_multijump == -1) && self.velocity_z > PHYS_MULTIJUMP_SPEED && (!PHYS_MULTIJUMP_MAXSPEED || vlen(self.velocity) <= PHYS_MULTIJUMP_MAXSPEED))
	{
		if (PHYS_MULTIJUMP)
		{
			if (!PHYS_MULTIJUMP_ADD) // in this case we make the z velocity == jumpvelocity
			{
				if (self.velocity_z < PHYS_JUMPVELOCITY)
				{
					player_multijump = true;
					self.velocity_z = 0;
				}
			}
			else
				player_multijump = true;

			if(player_multijump)
			{
				if(PHYS_MULTIJUMP_DODGING)
				if(self.movement_x != 0 || self.movement_y != 0) // don't remove all speed if player isnt pressing any movement keys
				{
					float curspeed;
					vector wishvel, wishdir;

/*#ifdef SVQC
					curspeed = max(
						vlen(vec2(self.velocity)), // current xy speed
						vlen(vec2(antilag_takebackavgvelocity(self, max(self.lastteleporttime + sys_frametime, time - 0.25), time))) // average xy topspeed over the last 0.25 secs
					);
#elif defined(CSQC)*/
					curspeed = vlen(vec2(self.velocity));
//#endif

					makevectors(self.v_angle_y * '0 1 0');
					wishvel = v_forward * self.movement_x + v_right * self.movement_y;
					wishdir = normalize(wishvel);

					self.velocity_x = wishdir_x * curspeed; // allow "dodging" at a multijump
					self.velocity_y = wishdir_y * curspeed;
					// keep velocity_z unchanged!
				}
				if (PHYS_MULTIJUMP > 0)
				{
					self.multijump_count += 1;
				}
			}
		}
		self.multijump_ready = false; // require releasing and pressing the jump button again for the next jump
	}

	return false;
}

#ifdef SVQC
MUTATOR_HOOKFUNCTION(multijump_PlayerPhysics)
{
	multijump_UpdateStats();
	PM_multijump();

	return false;
}

MUTATOR_HOOKFUNCTION(multijump_PlayerJump)
{
	return PM_multijump_checkjump();
}

MUTATOR_HOOKFUNCTION(multijump_GetCvars)
{
	GetCvars_handleFloat(get_cvars_s, get_cvars_f, cvar_cl_multijump, "cl_multijump");
	return false;
}

MUTATOR_HOOKFUNCTION(multijump_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":multijump");
	return false;
}

MUTATOR_HOOKFUNCTION(multijump_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Multi jump");
	return false;
}

MUTATOR_DEFINITION(mutator_multijump)
{
	MUTATOR_HOOK(PlayerPhysics, multijump_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerJump, multijump_PlayerJump, CBC_ORDER_ANY);
	MUTATOR_HOOK(GetCvars, multijump_GetCvars, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, multijump_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, multijump_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		multijump_AddStats();
	}

	return false;
}
#endif
