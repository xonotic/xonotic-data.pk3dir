#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#include "../item/modalcontroller.qc"
CLASS(MainWindow, ModalController)
	METHOD(MainWindow, configureMainWindow, void(entity));
	METHOD(MainWindow, draw, void(entity));
	ATTRIB(MainWindow, firstRunDialog, entity, NULL)
	ATTRIB(MainWindow, advancedDialog, entity, NULL)
	ATTRIB(MainWindow, mutatorsDialog, entity, NULL)
	ATTRIB(MainWindow, mapInfoDialog, entity, NULL)
	ATTRIB(MainWindow, userbindEditDialog, entity, NULL)
	ATTRIB(MainWindow, winnerDialog, entity, NULL)
	ATTRIB(MainWindow, serverInfoDialog, entity, NULL)
	ATTRIB(MainWindow, cvarsDialog, entity, NULL)
	ATTRIB(MainWindow, screenshotViewerDialog, entity, NULL)
	ATTRIB(MainWindow, viewDialog, entity, NULL)
	ATTRIB(MainWindow, hudconfirmDialog, entity, NULL)
	ATTRIB(MainWindow, languageWarningDialog, entity, NULL)
	ATTRIB(MainWindow, mainNexposee, entity, NULL)
	ATTRIB(MainWindow, fadedAlpha, float, SKINALPHA_BEHIND)
	ATTRIB(MainWindow, dialogToShow, entity, NULL)
	ATTRIB(MainWindow, demostartconfirmDialog, entity, NULL)
	ATTRIB(MainWindow, demotimeconfirmDialog, entity, NULL)
	ATTRIB(MainWindow, resetDialog, entity, NULL)
ENDCLASS(MainWindow)
#endif

#ifdef IMPLEMENTATION
void MainWindow_draw(entity me)
{
	SUPER(MainWindow).draw(me);

	if(me.dialogToShow)
	{
		DialogOpenButton_Click_withCoords(NULL, me.dialogToShow, '0 0 0', eX * conwidth + eY * conheight);
		me.dialogToShow = NULL;
	}
}

void DemoButton_Click(entity me, entity other)
{
	if(me.text == _("Do not press this button again!"))
		DialogOpenButton_Click(me, other);
	else
		me.setText(me, _("Do not press this button again!"));
}

void MainWindow_configureMainWindow(entity me)
{
	entity n, i;

	// dialog run upon startup
	me.firstRunDialog = i = NEW(XonoticFirstRunDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// hud_configure dialogs
	i = NEW(XonoticHUDExitDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDNotificationDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDAmmoDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDHealthArmorDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDChatDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDModIconsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPowerupsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPressedKeysDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDRaceTimerDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDRadarDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDScoreDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDTimerDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDVoteDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDWeaponsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDEngineInfoDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDInfoMessagesDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDPhysicsDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDCenterprintDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDItemsTimeDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticHUDQuickMenuDialog);
	i.configureDialog(i);
	me.addItemRightCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	// dialogs used by settings
	me.userbindEditDialog = i = NEW(XonoticUserbindEditDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.cvarsDialog = i = NEW(XonoticCvarsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.resetDialog = i = NEW(XonoticResetDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.languageWarningDialog = i = NEW(XonoticLanguageWarningDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.hudconfirmDialog = i = NEW(XonoticHUDConfirmDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialog used by singleplayer
	me.winnerDialog = i = NEW(XonoticWinnerDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialog used by multiplayer/join
	me.serverInfoDialog = i = NEW(XonoticServerInfoDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.demostartconfirmDialog = i = NEW(XonoticDemoStartConfirmDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.demotimeconfirmDialog = i = NEW(XonoticDemoTimeConfirmDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialogs used by multiplayer/create
	me.mapInfoDialog = i = NEW(XonoticMapInfoDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.mutatorsDialog = i = NEW(XonoticMutatorsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialogs used by multiplayer/media
	me.screenshotViewerDialog = i = NEW(XonoticScreenshotViewerDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// mutator dialogs
	i = NEW(XonoticSandboxToolsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z * SKINALPHA_DIALOG_SANDBOXTOOLS);


	// miscellaneous dialogs
	i = NEW(XonoticTeamSelectDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = NEW(XonoticMonsterToolsDialog);
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z * SKINALPHA_DIALOG_SANDBOXTOOLS);


	// main dialogs/windows
	me.mainNexposee = n = NEW(XonoticNexposee);
	/*
		if(checkextension("DP_GECKO_SUPPORT"))
		{
			i = spawnXonoticNewsDialog();
			i.configureDialog(i);
			n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
			n.setNexposee(n, i, '0.1 0.1 0', SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		}
	*/
		i = NEW(XonoticSingleplayerDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SINGLEPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = NEW(XonoticMultiplayerDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_MULTIPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = NEW(XonoticSettingsDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SETTINGS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = NEW(XonoticCreditsDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_CREDITS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / conheight));

		i = NEW(XonoticQuitDialog);
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_QUIT, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / conheight));

	me.addItem(me, n, '0 0 0', '1 1 0', SKINALPHAS_MAINMENU_z);
	me.moveItemAfter(me, n, NULL);

	me.initializeDialog(me, n);

	if(cvar_string("_cl_name") == cvar_defstring("_cl_name"))
		me.dialogToShow = me.firstRunDialog;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
