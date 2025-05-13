#include "rootdialog.qh"

void XonoticRootDialog_showNotify(entity me)
{
	SUPER(XonoticRootDialog).showNotify(me);
	loadAllCvars(me);
}

void XonoticRootDialog_close(entity me)
{
	m_goto(string_null, true);
}
