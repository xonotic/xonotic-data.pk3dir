#ifdef REGISTER_WEAPON
REGISTER_WEAPON(PORTO, w_porto, 0, 0, WEP_TYPE_OTHER, 0, "porto" , "porto", _("Port-O-Launch"))
#else
#ifdef SVQC
.entity porto_current;
.vector porto_v_angle; // holds "held" view angles
.float porto_v_angle_held;
.vector right_vector;

void W_Porto_Success (void)
{
	if(self.realowner == world)
	{
		objerror("Cannot succeed successfully: no owner\n");
		return;
	}

	self.realowner.porto_current = world;
	remove(self);
}

string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo);
void W_Porto_Fail (float failhard)
{
	if(self.realowner == world)
	{
		objerror("Cannot fail successfully: no owner\n");
		return;
	}

	// no portals here!
	Portal_ClearWithID(self.realowner, self.portal_id);
	self.realowner.porto_current = world;

	if(!failhard && self.realowner.playerid == self.playerid && self.realowner.deadflag == DEAD_NO && !(self.realowner.weapons & WEPBIT_PORTO))
	{
		setsize (self, '-16 -16 0', '16 16 32');
		setorigin(self, self.origin + trace_plane_normal);
		if(move_out_of_solid(self))
		{
			self.flags = FL_ITEM;
			self.velocity = trigger_push_calculatevelocity(self.origin, self.realowner, 128);
			tracetoss(self, self);
			if(vlen(trace_endpos - self.realowner.origin) < 128)
			{
				W_ThrowNewWeapon(self.realowner, WEP_PORTO, 0, self.origin, self.velocity);
				centerprint(self.realowner, "^1Portal deployment failed.\n\n^2Catch it to try again!");
			}
		}
	}
	remove(self);
}

void W_Porto_Remove (entity p)
{
	if(p.porto_current)
	{
		entity oldself;
		oldself = self;
		self = p.porto_current;
		W_Porto_Fail(1);
		self = oldself;
	}
}

void W_Porto_Think (void)
{
	trace_plane_normal = '0 0 0';
	if(self.realowner.playerid != self.playerid)
		remove(self);
	else
		W_Porto_Fail(0);
}

void W_Porto_Touch (void)
{
	vector norm;

	// do not use PROJECTILE_TOUCH here

	if(other.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if(trace_ent.iscreature)
	{
		traceline(trace_ent.origin, trace_ent.origin + '0 0 2' * PL_MIN_z, MOVE_WORLDONLY, self);
		if(trace_fraction >= 1)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
	}

	if(self.realowner.playerid != self.playerid)
	{
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		remove(self);
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
	{
		spamsound(self, CHAN_PROJECTILE, "porto/bounce.wav", VOL_BASE, ATTN_NORM);
		// just reflect
		self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * trace_plane_normal);
		self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
		W_Porto_Fail(0);
	}
	else if(self.effects & EF_RED)
	{
		self.effects += EF_BLUE - EF_RED;
		if(Portal_SpawnInPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
		{
			sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			centerprint(self.realowner, "^1In^7-portal created.");
			self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * norm);
			self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * norm));
			CSQCProjectile(self, TRUE, PROJECTILE_PORTO_BLUE, TRUE); // change type
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(0);
		}
	}
	else
	{
		if(self.realowner.portal_in.portal_id == self.portal_id)
		{
			if(Portal_SpawnOutPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
			{
				sound(self, CHAN_PROJECTILE, "porto/create.wav", VOL_BASE, ATTN_NORM);
				trace_plane_normal = norm;
				centerprint(self.realowner, "^4Out^7-portal created.");
				W_Porto_Success();
			}
			else
			{
				sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
				W_Porto_Fail(0);
			}
		}
		else
		{
			sound(self, CHAN_PROJECTILE, "porto/unsupported.wav", VOL_BASE, ATTN_NORM);
			W_Porto_Fail(0);
		}
	}
}

void W_Porto_Attack (void)
{
	local entity gren;

	if not(self.items & IT_UNLIMITED_SUPERWEAPONS)
		self.weapons = self.weapons - (self.weapons & WEPBIT_PORTO);
	W_SetupShot (self, FALSE, 4, "porto/fire.wav", CHAN_WEAPON, 0);
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;

	//pointparticles(particleeffectnum("grenadelauncher_muzzleflash"), w_shotorg, w_shotdir * 1000, 1);

	gren = spawn ();
	gren.owner = gren.realowner = self;
	gren.playerid = self.playerid;
	gren.classname = "porto";
	gren.bot_dodge = TRUE;
	gren.bot_dodgerating = 200;
	gren.movetype = MOVETYPE_BOUNCEMISSILE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.effects = EF_RED;
	gren.scale = 4;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + autocvar_g_balance_porto_primary_lifetime;
	gren.think = W_Porto_Think;
	gren.touch = W_Porto_Touch;
	if(self.items & IT_STRENGTH)
		W_SetupProjectileVelocity(gren, autocvar_g_balance_porto_primary_speed * autocvar_g_balance_powerup_strength_force, 0);
	else
		W_SetupProjectileVelocity(gren, autocvar_g_balance_porto_primary_speed, 0);

	gren.angles = vectoangles (gren.velocity);
	gren.flags = FL_PROJECTILE;

	gren.portal_id = time;
	self.porto_current = gren;
	gren.playerid = self.playerid;
	fixedmakevectors(fixedvectoangles(gren.velocity));
	gren.right_vector = v_right;

	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;

	CSQCProjectile(gren, TRUE, PROJECTILE_PORTO_RED, TRUE);

	other = gren; MUTATOR_CALLHOOK(EditProjectile);
}

void spawnfunc_weapon_porto (void)
{
	weapon_defaultspawnfunc(WEP_PORTO);
}

float w_nexball_weapon(float req);
float w_porto(float req)
{
	vector v_angle_save;

	if (g_nexball) { return w_nexball_weapon(req); }
	if (req == WR_AIM)
	{
		self.BUTTON_ATCK = FALSE;
		self.BUTTON_ATCK2 = FALSE;
		if(bot_aim(autocvar_g_balance_porto_primary_speed, 0, autocvar_g_balance_grenadelauncher_primary_lifetime, FALSE))
			self.BUTTON_ATCK = TRUE;
	}
	else if (req == WR_THINK)
	{
		if(self.porto_v_angle_held)
		{
			if(!self.BUTTON_ATCK2)
			{
				self.porto_v_angle_held = 0;

				ClientData_Touch(self);
			}
		}
		else
		{
			if(self.BUTTON_ATCK2)
			{
				self.porto_v_angle = self.v_angle;
				self.porto_v_angle_held = 1;

				ClientData_Touch(self);
			}
		}
		v_angle_save = self.v_angle;
		if(self.porto_v_angle_held)
			makevectors(self.porto_v_angle); // override the previously set angles

		if (self.BUTTON_ATCK)
		if (!self.porto_current)
		if (!self.porto_forbidden)
		if (weapon_prepareattack(0, autocvar_g_balance_porto_primary_refire))
		{
			W_Porto_Attack();
			weapon_thinkf(WFRAME_FIRE1, autocvar_g_balance_porto_primary_animtime, w_ready);
		}
	}
	else if (req == WR_PRECACHE)
	{
		precache_model ("models/weapons/g_porto.md3");
		precache_model ("models/weapons/v_porto.md3");
		precache_model ("models/weapons/h_porto.iqm");
		precache_model ("models/portal.md3");
		precache_sound ("porto/bounce.wav");
		precache_sound ("porto/create.wav");
		precache_sound ("porto/expire.wav");
		precache_sound ("porto/explode.wav");
		precache_sound ("porto/fire.wav");
		precache_sound ("porto/unsupported.wav");
	}
	else if (req == WR_SETUP)
	{
		weapon_setup(WEP_PORTO);
		self.current_ammo = ammo_none;
	}
	else if (req == WR_RESETPLAYER)
	{
		self.porto_current = world;
	}
	return TRUE;
};
#endif
#ifdef CSQC
float w_porto(float req)
{
	if(req == WR_IMPACTEFFECT)
	{
		print("Since when does Porto send DamageInfo?\n");
	}
	else if(req == WR_PRECACHE)
	{
		// nothing to do
	}
	else if (req == WR_SUICIDEMESSAGE)
		w_deathtypestring = _("%s did the impossible");
	else if (req == WR_KILLMESSAGE)
		w_deathtypestring = _("%s felt %s doing the impossible to him");
	return TRUE;
}
#endif
#endif
