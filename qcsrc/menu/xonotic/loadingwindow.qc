#ifndef LOADINGWINDOW_H
#define LOADINGWINDOW_H
CLASS(LoadingWindow, ModalController)
    METHOD(LoadingWindow, configureLoadingWindow, void(entity));
    METHOD(LoadingWindow, draw, void(entity));
    ATTRIB(LoadingWindow, tipDialog, entity, NULL)
    ATTRIB(LoadingWindow, fadedAlpha, float, SKINALPHA_BEHIND)
    ATTRIB(LoadingWindow, dialogToShow, entity, NULL)
    INIT(LoadingWindow) {
        entity e;

        this.tipDialog = e = NEW(XonoticTipDialog);
        e.configureDialog(e);
        this.addItemCentered(this, e, e.intendedWidth * eX + e.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

        this.dialogToShow = this.tipDialog;
    }
ENDCLASS(LoadingWindow)
#endif

#ifdef IMPLEMENTATION
void LoadingWindow_draw(entity this)
{
    super.draw(this);

    if (this.dialogToShow)
    {
        DialogOpenButton_Click_withCoords(world, this.dialogToShow, '0 0 0', eX * conwidth + eY * conheight);
        this.dialogToShow = NULL;
    }
}

#endif
