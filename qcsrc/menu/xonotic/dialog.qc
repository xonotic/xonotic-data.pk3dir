#include "dialog.qh"

void XonoticDialog_configureDialog(entity me)
{
	currentDialog = me;
	SUPER(XonoticDialog).configureDialog(me);
}
