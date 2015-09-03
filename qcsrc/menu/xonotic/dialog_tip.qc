#ifndef DIALOG_TIP_H
#define DIALOG_TIP_H
CLASS(XonoticTipDialog, XonoticDialog)
    METHOD(XonoticTipDialog, fill, void(entity));
    ATTRIB(XonoticTipDialog, title, string, _("Tip"))
    ATTRIB(XonoticTipDialog, color, vector, SKINCOLOR_DIALOG_FIRSTRUN)
    ATTRIB(XonoticTipDialog, intendedWidth, float, 0.7)
    ATTRIB(XonoticTipDialog, rows, float, 2)
    ATTRIB(XonoticTipDialog, columns, float, 2)
    ATTRIB(XonoticTipDialog, name, string, "Tip")

    ATTRIB(XonoticTipDialog, closable, float, 0)

ENDCLASS(XonoticTipDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticTipDialog_fill(entity this)
{
    entity e;
    this.TR(this);
        this.TD(this, 2, 2, e = makeXonoticTextLabel(0, "Loading"));
        e.allowWrap = 1;
}
#endif
