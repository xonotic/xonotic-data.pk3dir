#ifdef INTERFACE
CLASS(MainWindow) EXTENDS(ModalController)
	METHOD(MainWindow, configureMainWindow, void(entity))
	METHOD(MainWindow, draw, void(entity))
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
		DialogOpenButton_Click_withCoords(world, me.dialogToShow, '0 0 0', eX * conwidth + eY * conheight);
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
	me.firstRunDialog = i = spawnXonoticFirstRunDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// hud_configure dialogs
	i = spawnXonoticHUDExitDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDNotificationDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDAmmoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDHealthArmorDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDChatDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDModIconsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDPowerupsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDPressedKeysDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDRaceTimerDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDRadarDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDScoreDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDTimerDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDVoteDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDWeaponsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDEngineInfoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDInfoMessagesDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	
	i = spawnXonoticHUDPhysicsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	
	me.screenshotViewerDialog = i = spawnXonoticScreenshotViewerDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDCenterprintDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticHUDBuffsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialogs used by settings
	me.userbindEditDialog = i = spawnXonoticUserbindEditDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.cvarsDialog = i = spawnXonoticCvarsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	
	me.resetDialog = i = spawnXonoticResetDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.languageWarningDialog = i = spawnXonoticLanguageWarningDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.hudconfirmDialog = i = spawnXonoticHUDConfirmDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialog used by singleplayer
	me.winnerDialog = i = spawnXonoticWinnerDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialog used by multiplayer/join
	me.serverInfoDialog = i = spawnXonoticServerInfoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
	
	me.demostartconfirmDialog = i = spawnXonoticDemoStartConfirmDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.demotimeconfirmDialog = i = spawnXonoticDemoTimeConfirmDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);


	// dialogs used by multiplayer/create
	me.mapInfoDialog = i = spawnXonoticMapInfoDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	me.mutatorsDialog = i = spawnXonoticMutatorsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	// mutator dialogs
	i = spawnXonoticSandboxToolsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z * SKINALPHA_DIALOG_SANDBOXTOOLS);


	// miscellaneous dialogs
	i = spawnXonoticTeamSelectDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);

	i = spawnXonoticMonsterToolsDialog();
	i.configureDialog(i);
	me.addItemCentered(me, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z * SKINALPHA_DIALOG_SANDBOXTOOLS);


	// main dialogs/windows
	me.mainNexposee = n = spawnXonoticNexposee();
	/*
		if(checkextension("DP_GECKO_SUPPORT"))
		{
			i = spawnXonoticNewsDialog();
			i.configureDialog(i);
			n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
			n.setNexposee(n, i, '0.1 0.1 0', SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		}
	*/
		i = spawnXonoticSingleplayerDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SINGLEPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = spawnXonoticMultiplayerDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_MULTIPLAYER, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = spawnXonoticSettingsDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_SETTINGS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);

		i = spawnXonoticCreditsDialog();
		i.configureDialog(i);
		n.addItemCentered(n, i, i.intendedWidth * eX + i.intendedHeight * eY, SKINALPHAS_MAINMENU_z);
		n.setNexposee(n, i, SKINPOSITION_DIALOG_CREDITS, SKINALPHAS_MAINMENU_x, SKINALPHAS_MAINMENU_y);
		n.pullNexposee(n, i, eY * (SKINHEIGHT_TITLE * SKINFONTSIZE_TITLE / conheight));

		i = spawnXonoticQuitDialog();
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
