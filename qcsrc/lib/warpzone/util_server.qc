#include "util_server.qh"

#include "common.qh"

#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include <lib/csqcmodel/sv_model.qh>
#endif
#include "common.qh"

void WarpZoneLib_ExactTrigger_Init(entity this, bool unsetmodel)
{
	vector mi, ma;
	if (this.movedir == '0 0 0')
	if (this.angles != '0 0 0')
	{
		vector forward, _r, _u;
		MAKE_VECTORS(this.angles, forward, _r, _u);
		this.movedir = forward;
	}
	if(this.model == "")
	{
		// It's a box! No need to match with exacttriggers.
		this.warpzone_isboxy = 1;
	}
	else
 	{
		mi = this.mins;
		ma = this.maxs;
 		precache_model(this.model);
 		_setmodel(this, this.model);
		// let mapper-set mins/maxs override the model's bounds if set
		if(mi != '0 0 0' || ma != '0 0 0')
		{
			// It's a box! No need to match with exacttriggers.
			this.mins = mi;
			this.maxs = ma;
			this.warpzone_isboxy = 1;
		}
 	}
	setorigin(this, this.origin);
	this.solid = SOLID_TRIGGER; // before setsize to ensure area grid linking
	if(this.scale)
		setsize(this, this.mins * this.scale, this.maxs * this.scale);
	else
		setsize(this, this.mins, this.maxs);
	set_movetype(this, MOVETYPE_NONE);

	if (unsetmodel)
		this.model = "";
}
