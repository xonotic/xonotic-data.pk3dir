#include "walljump.qh"

#ifdef GAMEQC
#ifdef CSQC
REGISTER_MUTATOR(walljump, true);
#elif defined(SVQC)
REGISTER_MUTATOR(walljump, autocvar_g_walljump);
#endif

#define PHYS_WALLJUMP(s) 						STAT(WALLJUMP, s)
#define PHYS_WALLJUMP_VELOCITY_Z_FACTOR(s) 		STAT(WALLJUMP_VELOCITY_Z_FACTOR, s)
#define PHYS_WALLJUMP_VELOCITY_XY_FACTOR(s) 	STAT(WALLJUMP_VELOCITY_XY_FACTOR, s)
#define PHYS_WALLJUMP_DELAY(s) 					STAT(WALLJUMP_DELAY, s)
#define PHYS_WALLJUMP_FORCE(s) 					STAT(WALLJUMP_FORCE, s)

vector PlayerTouchWall(entity this)
{
#define TRACE(newvec) \
	tracebox (start, this.mins, this.maxs, (newvec), true, this); \
	if (trace_fraction < 1 && vdist(this.origin - trace_endpos, <, dist) && trace_plane_normal_z < max_normal) \
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)) \
		return trace_plane_normal;

	float dist = 10, max_normal = 0.2, scaler = 100;
	vector start = this.origin;
	vector forward, right, _up;
	MAKE_VECTORS(this.angles, forward, right, _up);
	TRACE(start + forward * scaler)
	TRACE(start - forward * scaler)
	TRACE(start + right * scaler)
	TRACE(start - right * scaler)
#undef TRACE
	return '0 0 0';
}

MUTATOR_HOOKFUNCTION(walljump, PlayerJump)
{
	entity player = M_ARGV(0, entity);

	if(PHYS_WALLJUMP(player))
	if(time - STAT(LASTWJ, player) > PHYS_WALLJUMP_DELAY(player)) // can't do this on client, as it's too stupid to obey counters
	if(!IS_ONGROUND(player))
	if(player.move_movetype != MOVETYPE_NONE && player.move_movetype != MOVETYPE_FOLLOW && player.move_movetype != MOVETYPE_FLY && player.move_movetype != MOVETYPE_NOCLIP)
	if(!IS_JUMP_HELD(player))
	if(!STAT(FROZEN, player) && !StatusEffects_active(STATUSEFFECT_Frozen, player))
	if(!IS_DEAD(player))
	{
		vector plane_normal = PlayerTouchWall(player);

		if(plane_normal != '0 0 0')
		{
			float wj_force = PHYS_WALLJUMP_FORCE(player);
			float wj_xy_factor = PHYS_WALLJUMP_VELOCITY_XY_FACTOR(player);
			float wj_z_factor = PHYS_WALLJUMP_VELOCITY_Z_FACTOR(player);
			player.velocity_x += plane_normal_x * wj_force;
			player.velocity_x /= wj_xy_factor;
			player.velocity_y += plane_normal_y * wj_force;
			player.velocity_y /= wj_xy_factor;
			player.velocity_z = PHYS_JUMPVELOCITY(player) * wj_z_factor;
			if(PHYS_INPUT_BUTTON_CROUCH(player)) player.velocity_z *= -1;

#ifdef SVQC
			STAT(LASTWJ, player) = time;
			player.oldvelocity = player.velocity;
			Send_Effect(EFFECT_SMOKE_RING, trace_endpos, plane_normal, 5);
			PlayerSound(player, playersound_jump, CH_PLAYER, VOL_BASE, VOICETYPE_PLAYERSOUND);
			animdecide_setaction(player, ANIMACTION_JUMP, true);
#endif

			M_ARGV(2, bool) = true; // multijump
		}
	}
}

#endif
#ifdef MENUQC
METHOD(MutatorWallJump, describe, string(MutatorWallJump this))
{
	TC(MutatorWallJump, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator that enables jumping off walls for added mobility. "
	      "To do a wall jump, tap %s when against a wall."), COLORED_NAME(this), strcat("^3", _("jump"), "^7"));
	PAR(_("This mutator adds a bit of versatility, allowing for more dynamic and unpredictable movement."));
	return PAGE_TEXT;
}
#endif
