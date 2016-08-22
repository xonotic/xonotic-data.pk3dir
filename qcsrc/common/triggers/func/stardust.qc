#include "stardust.qh"
#ifdef SVQC
spawnfunc(func_stardust)
{
	this.effects = EF_STARDUST;

	CSQCMODEL_AUTOINIT(this);
}
#endif
