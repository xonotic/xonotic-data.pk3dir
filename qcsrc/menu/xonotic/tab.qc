#include "tab.qh"

void XonoticTab_showNotify(entity me)
{
	loadAllCvars(me);
	SUPER(XonoticTab).showNotify(me);
}
