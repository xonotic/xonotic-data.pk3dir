#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../dpdefs/progsdefs.qh"
    #include "../dpdefs/dpextensions.qh"
    #include "util_server.qh"
    #include "../csqcmodellib/sv_model.qh"
#endif
#include "common.qh"

void WarpZoneLib_ExactTrigger_Init()
{
	vector mi, ma;
	if (self.movedir == '0 0 0')
	if (self.angles != '0 0 0')
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}
	if(self.model == "")
	{
		// It's a box! No need to match with exacttriggers.
		self.warpzone_isboxy = 1;
	}
	else
 	{
		mi = self.mins;
		ma = self.maxs;
#ifdef SVQC
 		precache_model(self.model);
#endif
 		setmodel(self, self.model);
		// let mapper-set mins/maxs override the model's bounds if set
		if(mi != '0 0 0' || ma != '0 0 0')
		{
			// It's a box! No need to match with exacttriggers.
			self.mins = mi;
			self.maxs = ma;
			self.warpzone_isboxy = 1;
		}
 	}
	setorigin(self, self.origin);
	if(self.scale)
		setsize(self, self.mins * self.scale, self.maxs * self.scale);
	else
		setsize(self, self.mins, self.maxs);
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.model = "";
}
