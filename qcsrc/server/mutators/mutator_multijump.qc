#include "../_all.qh"

#include "mutator.qh"

#include "../antilag.qh"

.float multijump_count;
.float multijump_ready;

MUTATOR_HOOKFUNCTION(multijump_PlayerPhysics)
{
	if(self.flags & FL_ONGROUND)
		self.multijump_count = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(multijump_PlayerJump)
{
	if (self.flags & FL_JUMPRELEASED && !(self.flags & FL_ONGROUND)) // jump button pressed this frame and we are in midair
		self.multijump_ready = true;  // this is necessary to check that we released the jump button and pressed it again
	else
		self.multijump_ready = false;

	if(!player_multijump && self.multijump_ready && (autocvar_g_multijump == -1 || self.multijump_count < autocvar_g_multijump) && self.velocity.z > autocvar_g_multijump_speed)
	{
		if (autocvar_g_multijump)
		{
			if (autocvar_g_multijump_add == 0) // in this case we make the z velocity == jumpvelocity
			{
				if (self.velocity.z < autocvar_sv_jumpvelocity)
				{
					player_multijump = true;
					self.velocity_z = 0;
				}
			}
			else
				player_multijump = true;

			if(player_multijump)
			{
				if(self.movement.x != 0 || self.movement.y != 0) // don't remove all speed if player isnt pressing any movement keys
				{
					float curspeed;
					vector wishvel, wishdir;

					curspeed = max(
						vlen(vec2(self.velocity)), // current xy speed
						vlen(vec2(antilag_takebackavgvelocity(self, max(self.lastteleporttime + sys_frametime, time - 0.25), time))) // average xy topspeed over the last 0.25 secs
					);
					makevectors(self.v_angle.y * '0 1 0');
					wishvel = v_forward * self.movement.x + v_right * self.movement.y;
					wishdir = normalize(wishvel);

					self.velocity_x = wishdir.x * curspeed; // allow "dodging" at a multijump
					self.velocity_y = wishdir.y * curspeed;
					// keep velocity_z unchanged!
				}
				self.multijump_count += 1;
			}
		}
		self.multijump_ready = false; // require releasing and pressing the jump button again for the next jump
	}

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
	MUTATOR_HOOK(BuildMutatorsString, multijump_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, multijump_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	return false;
}
