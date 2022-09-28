#include "multijump.qh"

#ifdef GAMEQC

REPLICATE(cvar_cl_multijump, bool, "cl_multijump");

#ifdef SVQC
	#include <server/antilag.qh>
#endif
#include <common/physics/player.qh>


#if defined(SVQC)
REGISTER_MUTATOR(multijump, autocvar_g_multijump);
#elif defined(CSQC)
REGISTER_MUTATOR(multijump, true);
#endif

#define PHYS_MULTIJUMP(s) 				STAT(MULTIJUMP, s)
#define PHYS_MULTIJUMP_SPEED(s) 		STAT(MULTIJUMP_SPEED, s)
#define PHYS_MULTIJUMP_ADD(s) 			STAT(MULTIJUMP_ADD, s)
#define PHYS_MULTIJUMP_MAXSPEED(s) 		STAT(MULTIJUMP_MAXSPEED, s)
#define PHYS_MULTIJUMP_DODGING(s) 		STAT(MULTIJUMP_DODGING, s)
#define PHYS_MULTIJUMP_COUNT(s) 		STAT(MULTIJUMP_COUNT, s)
#define PHYS_MULTIJUMP_CLIENTDEFAULT(s)	STAT(MULTIJUMP_CLIENT, s)

.bool multijump_ready;

#ifdef CSQC
int autocvar_cl_multijump = -1;
	#define PHYS_MULTIJUMP_CLIENT(s)	autocvar_cl_multijump
#elif defined(SVQC)
	#define PHYS_MULTIJUMP_CLIENT(s)	CS_CVAR(s).cvar_cl_multijump
#endif

MUTATOR_HOOKFUNCTION(multijump, PlayerPhysics)
{
    entity player = M_ARGV(0, entity);

#ifdef CSQC
	player.multijump_count = PHYS_MULTIJUMP_COUNT(player);
#endif
	if(!PHYS_MULTIJUMP(player)) { return; }

	if(IS_ONGROUND(player))
		player.multijump_count = 0;
}

MUTATOR_HOOKFUNCTION(multijump, PlayerJump)
{
	entity player = M_ARGV(0, entity);

	if(!PHYS_MULTIJUMP(player)) { return; }

	int client_multijump = PHYS_MULTIJUMP_CLIENT(player);
	if(client_multijump == -1)
		client_multijump = PHYS_MULTIJUMP_CLIENTDEFAULT(player);
	if(client_multijump > 1)
		return; // nope

	if (!IS_JUMP_HELD(player) && !IS_ONGROUND(player) && client_multijump) // jump button pressed this frame and we are in midair
		player.multijump_ready = true;  // this is necessary to check that we released the jump button and pressed it again
	else
		player.multijump_ready = false;

	int phys_multijump = PHYS_MULTIJUMP(player);

	if(!M_ARGV(2, bool) && player.multijump_ready && (PHYS_MULTIJUMP_COUNT(player) < phys_multijump || phys_multijump == -1) && player.velocity_z > PHYS_MULTIJUMP_SPEED(player) &&
		(!PHYS_MULTIJUMP_MAXSPEED(player) || vdist(player.velocity, <=, PHYS_MULTIJUMP_MAXSPEED(player))))
	{
		if (PHYS_MULTIJUMP(player))
		{
			if (!PHYS_MULTIJUMP_ADD(player)) // in this case we make the z velocity == jumpvelocity
			{
				if (player.velocity_z < PHYS_JUMPVELOCITY(player))
				{
					M_ARGV(2, bool) = true;
					player.velocity_z = 0;
				}
			}
			else
				M_ARGV(2, bool) = true;

			if(M_ARGV(2, bool))
			{
				if(PHYS_MULTIJUMP_DODGING(player))
				if(PHYS_CS(player).movement_x != 0 || PHYS_CS(player).movement_y != 0) // don't remove all speed if player isnt pressing any movement keys
				{
					float curspeed;
					vector wishvel, wishdir;

/*#ifdef SVQC
					curspeed = max(
						vlen(vec2(player.velocity)), // current xy speed
						vlen(vec2(antilag_takebackavgvelocity(player, max(player.lastteleporttime + sys_frametime, time - 0.25), time))) // average xy topspeed over the last 0.25 secs
					);
#elif defined(CSQC)*/
					curspeed = vlen(vec2(player.velocity));
//#endif

					makevectors(player.v_angle_y * '0 1 0');
					wishvel = v_forward * PHYS_CS(player).movement_x + v_right * PHYS_CS(player).movement_y;
					wishdir = normalize(wishvel);

					player.velocity_x = wishdir_x * curspeed; // allow "dodging" at a multijump
					player.velocity_y = wishdir_y * curspeed;
					// keep velocity_z unchanged!
				}
				if (PHYS_MULTIJUMP(player) > 0)
				{
					player.multijump_count += 1;
				}
			}
		}
		player.multijump_ready = false; // require releasing and pressing the jump button again for the next jump
	}
}

#ifdef SVQC

MUTATOR_HOOKFUNCTION(multijump, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":multijump");
}

MUTATOR_HOOKFUNCTION(multijump, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Multi jump");
}

#endif

#endif
