#include "cl_melee_only.qh"

REGISTER_MUTATOR(melee_only, false)
{
	MUTATOR_ONADD
	{
		RES_SHELLS.m_hidden = true;
		RES_BULLETS.m_hidden = true;
		RES_CELLS.m_hidden = true;
		RES_ROCKETS.m_hidden = true;
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		RES_SHELLS.m_hidden = false;
		RES_BULLETS.m_hidden = false;
		RES_CELLS.m_hidden = false;
		RES_ROCKETS.m_hidden = false;
	}
}
