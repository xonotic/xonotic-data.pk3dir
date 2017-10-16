#include "ammo.qh"

#ifdef SVQC

METHOD(Bullets, m_spawnfunc_hookreplace, GameItem(Bullets this, entity e))
{
	if (autocvar_sv_q3acompat_machineshotgunswap && e.classname != "droppedweapon")
	{
		return ITEM_Shells;
	}
	return this;
}

METHOD(Shells, m_spawnfunc_hookreplace, GameItem(Shells this, entity e))
{
	if (autocvar_sv_q3acompat_machineshotgunswap && e.classname != "droppedweapon")
	{
		return ITEM_Bullets;
	}
	return this;
}

#endif
