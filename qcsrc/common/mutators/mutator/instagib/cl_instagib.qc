#include "cl_instagib.qh"

REGISTER_MUTATOR(mutator_instagib, false)
{
	MUTATOR_ONADD
	{
		// NOTE: VaporizerCells resource doesn't exist client side
		RES_SHELLS.m_hidden = true;
		RES_BULLETS.m_hidden = true;
		//RES_CELLS.m_hidden = false;
		RES_ROCKETS.m_hidden = true;
	}

	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		RES_SHELLS.m_hidden = false;
		RES_BULLETS.m_hidden = false;
		//RES_CELLS.m_hidden = false;
		RES_ROCKETS.m_hidden = false;
	}
}
