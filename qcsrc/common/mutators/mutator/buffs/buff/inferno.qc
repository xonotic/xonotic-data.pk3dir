#include "inferno.qh"

#ifdef SVQC
float buff_Inferno_CalculateTime(float dmg)
{
#define offset_x    0
#define offset_y    autocvar_g_buffs_inferno_burntime_min_time
#define intersect_x autocvar_g_buffs_inferno_burntime_target_damage
#define intersect_y autocvar_g_buffs_inferno_burntime_target_time
#define base        autocvar_g_buffs_inferno_burntime_factor
	// Interpolates from (offset_x, offset_y) to (intersect_x, intersect_y) logarithmically with base
	return offset_y + (intersect_y - offset_y) * logn(((dmg - offset_x) * ((base - 1) / intersect_x)) + 1, base);
#undef offset_x
#undef offset_y
#undef intersect_x
#undef intersect_y
#undef base
}
float buff_Inferno_CalculateDamage(float frag_damage)
{
	return frag_damage * autocvar_g_buffs_inferno_damagemultiplier;
}

METHOD(InfernoBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (time >= actor.buff_effect_delay && autocvar_g_buffs_effects) // prevent unnecessary calculations
	{
		.entity weaponentity = weaponentities[0]; // TODO: unhardcode
		entity e = actor.(weaponentity);
		vector org = CENTER_OR_VIEWOFS(actor);

		if (e)
		{
		#if 0
			/* This can't be used as the tags aren't accessible via SVQC, so this code only works properly when testing locally and not on a dedicated server.
			 * e.origin is very inaccurate, but exists for custom weapon models that don't have these tags.
			 * If these particles are moved to CSQC, this code should be used as it's more accurate than the code after the #else
			 *   See https://gitlab.com/xonotic/xonotic-data.pk3dir/-/work_items/2852
			 */
			int idx;
			if ((idx = gettagindex(e, "shot"))   || (idx = gettagindex(e, "tag_shot"))
			||  (idx = gettagindex(e, "weapon")) || (idx = gettagindex(e, "tag_weapon")))
				org = gettaginfo(e, idx);
			else
				org = e.origin;
		#else
			/* As an alternative to the above, draw the particles near where casings spawn.
			 * Code is similar to SpawnCasing, but with the effect of `v_up` minimized when aiming far up and down (via the `fabs`);
			 *   Otherwise it renders far behind the player when looking down and vice versa.
			 */
			makevectors(actor.v_angle);
			vector offset = e.spawnorigin;
			org += offset.x * v_forward - offset.y * v_right + offset.z * v_up * (1 - fabs(v_forward.z));
		#endif
		}

		buff_Effect(actor, EFFECT_RAGE, org, vec2(actor.velocity), 1, true); // particles block view so hide
	}

	SUPER(InfernoBuff).m_tick(this, actor);
}
#endif // SVQC
#ifdef MENUQC
METHOD(InfernoBuff, describe, string(InfernoBuff this))
{
	TC(InfernoBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff sets any enemies or monsters you attack alight, dealing burn damage to them for several seconds until the buff expires."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
