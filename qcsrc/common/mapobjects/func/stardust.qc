#include "stardust.qh"
#ifdef SVQC
void func_stardust_think(entity this)
{
	this.nextthink = time + 0.25;
	CSQCMODEL_AUTOUPDATE(this);
}
spawnfunc(func_stardust)
{
	if(this.model != "") { precache_model(this.model); _setmodel(this, this.model); }

	this.effects = EF_STARDUST;

	CSQCMODEL_AUTOINIT(this);

	setthink(this, func_stardust_think);
	this.nextthink = time + 0.25;
}
#endif
