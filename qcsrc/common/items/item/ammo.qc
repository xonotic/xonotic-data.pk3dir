#include "ammo.qh"

#ifdef SVQC

METHOD(Shells, m_spawnfunc_hookreplace, GameItem(Shells this, entity e))
{
	if (autocvar_sv_q3acompat_machineshotgunswap && !Item_IsLoot(e))
	{
		return ITEM_Bullets;
	}
	return this;
}

#endif
