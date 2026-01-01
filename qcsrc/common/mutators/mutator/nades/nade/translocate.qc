#include "translocate.qh"

#ifdef SVQC
void nade_translocate_boom(entity this)
{
	if(this.realowner.vehicle)
		return;

	setsize(this, PL_MIN_CONST-'16 16 16', PL_MAX_CONST+'16 16 16');

	if(!move_out_of_solid(this))
	{
		sprint(this.realowner, "^1Couldn't move the translocator out of solid! origin: ", vtos(this.origin), "\n");
		return;
	}

	vector locout = this.origin + '0 0 1' * (1 - this.realowner.mins.z - 24);
	tracebox(locout, this.realowner.mins, this.realowner.maxs, locout, MOVE_NOMONSTERS, this.realowner);
	locout = trace_endpos;

	makevectors(this.realowner.angles);

	MUTATOR_CALLHOOK(PortalTeleport, this.realowner);

	TeleportPlayer(this, this.realowner, locout, this.realowner.angles, v_forward * vlen(this.realowner.velocity), '0 0 0', '0 0 0', TELEPORT_FLAGS_TELEPORTER);
}

bool nade_translocate_DestroyDamage(entity this, entity attacker)
{
	if(autocvar_g_nades_translocate_destroy_damage > 0 && STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_TRANSLOCATE.m_id)
	{
		Damage(this.realowner, attacker, attacker, autocvar_g_nades_translocate_destroy_damage, DEATH_TOUCHEXPLODE.m_id, DMG_NOWEP, this.realowner.origin, '0 0 0');
		W_PrepareExplosionByDamage(this, this.realowner, nade_boom); // Don't change the owner

		return true;
	}
	return false;
}
#endif // SVQC
#ifdef MENUQC
METHOD(TranslocateNade, describe, string(TranslocateNade this))
{
	TC(TranslocateNade, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s detonates after a short delay, teleporting you to where it detonated."), COLORED_NAME(this));
	PAR(_("A common use of this nade is saving yourself from the void in space maps, however mastering this is very tricky."));
	PAR(_("If this grenade is destroyed by an attacker, it will deal some damage to them."));
	return PAGE_TEXT;
}
#endif // MENUQC
