.float multijump_count;
.float multijump_ready;

#ifdef CSQC

#define PHYS_MULTIJUMP 				getstati(STAT_MULTIJUMP)
#define PHYS_MULTIJUMP_SPEED 		getstatf(STAT_MULTIJUMP_SPEED)
#define PHYS_MULTIJUMP_ADD 			getstati(STAT_MULTIJUMP_ADD)

#elif defined(SVQC)

#define PHYS_MULTIJUMP 				autocvar_g_multijump
#define PHYS_MULTIJUMP_SPEED 		autocvar_g_multijump_speed
#define PHYS_MULTIJUMP_ADD 			autocvar_g_multijump_add


.float stat_multijump;
.float stat_multijump_speed;
.float stat_multijump_add;

void multijump_UpdateStats()
{
	self.stat_multijump = PHYS_MULTIJUMP;
	self.stat_multijump_speed = PHYS_MULTIJUMP_SPEED;
	self.stat_multijump_add = PHYS_MULTIJUMP_ADD;
}

void multijump_AddStats()
{
	addstat(STAT_MULTIJUMP, AS_INT, stat_multijump);
	addstat(STAT_MULTIJUMP_SPEED, AS_FLOAT, stat_multijump_speed);
	addstat(STAT_MULTIJUMP_ADD, AS_INT, stat_multijump_add);
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

float PM_multijump_checkjump()
{
	if(!PHYS_MULTIJUMP) { return FALSE; }

	if (!IS_JUMP_HELD(self) && !IS_ONGROUND(self)) // jump button pressed this frame and we are in midair
		self.multijump_ready = TRUE;  // this is necessary to check that we released the jump button and pressed it again
	else
		self.multijump_ready = FALSE;

	if(!player_multijump && self.multijump_ready && (self.multijump_count < PHYS_MULTIJUMP || PHYS_MULTIJUMP == -1) && self.velocity_z > PHYS_MULTIJUMP_SPEED)
	{
		if (PHYS_MULTIJUMP)
		{
			if (!PHYS_MULTIJUMP_ADD) // in this case we make the z velocity == jumpvelocity
			{
				if (self.velocity_z < PHYS_JUMPVELOCITY)
				{
					player_multijump = TRUE;
					self.velocity_z = 0;
				}
			}
			else
				player_multijump = TRUE;

			if(player_multijump)
			{
				if(PHYS_INPUT_MOVEVALUES(self)_x != 0 || PHYS_INPUT_MOVEVALUES(self)_y != 0) // don't remove all speed if player isnt pressing any movement keys
				{
					float curspeed;
					vector wishvel, wishdir;

#ifdef SVQC
					curspeed = max(
						vlen(vec2(self.velocity)), // current xy speed
						vlen(vec2(antilag_takebackavgvelocity(self, max(self.lastteleporttime + sys_frametime, time - 0.25), time))) // average xy topspeed over the last 0.25 secs
					);
#elif defined(CSQC)
					curspeed = vlen(vec2(self.velocity));
#endif

					makevectors(PHYS_INPUT_ANGLES(self)_y * '0 1 0');
					wishvel = v_forward * PHYS_INPUT_MOVEVALUES(self)_x + v_right * PHYS_INPUT_MOVEVALUES(self)_y;
					wishdir = normalize(wishvel);

					self.velocity_x = wishdir_x * curspeed; // allow "dodging" at a multijump
					self.velocity_y = wishdir_y * curspeed;
					// keep velocity_z unchanged!
				}
				self.multijump_count += 1;
			}
		}
		self.multijump_ready = FALSE; // require releasing and pressing the jump button again for the next jump
	}

	return FALSE;
}

#ifdef SVQC
MUTATOR_HOOKFUNCTION(multijump_PlayerPhysics)
{
	multijump_UpdateStats();
	PM_multijump();

	return FALSE;
}

MUTATOR_HOOKFUNCTION(multijump_PlayerJump)
{
	return PM_multijump_checkjump();
}

MUTATOR_HOOKFUNCTION(multijump_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":multijump");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(multijump_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Multi jump");
	return FALSE;
}

MUTATOR_DEFINITION(mutator_multijump)
{
	MUTATOR_HOOK(PlayerPhysics, multijump_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerJump, multijump_PlayerJump, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, multijump_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, multijump_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		multijump_AddStats();
	}

	return FALSE;
}
#endif
