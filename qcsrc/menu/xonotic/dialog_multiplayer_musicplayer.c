#ifdef INTERFACE
CLASS(XonoticMusicPlayerTab) EXTENDS(XonoticTab)
	METHOD(XonoticMusicPlayerTab, fill, void(entity))
	ATTRIB(XonoticMusicPlayerTab, title, string, _("Music"))
	ATTRIB(XonoticMusicPlayerTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticMusicPlayerTab, rows, float, 22)
	ATTRIB(XonoticMusicPlayerTab, columns, float, 4)
	ATTRIB(XonoticMusicPlayerTab, name, string, "MusicPlayer")
ENDCLASS(XonoticMusicPlayerTab)
entity makeXonoticMusicPlayerTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticMusicPlayerTab()
{
	entity me;
	me = spawnXonoticMusicPlayerTab();
	me.configureDialog(me);
	return me;
}
void XonoticMusicPlayerTab_fill(entity me)
{
	entity e;
	entity btn;
	entity soundList;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "music_playlist_random0", _("Random order")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, 0.5, btn = makeXonoticButton(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, 3, e = makeXonoticInputBox(0, string_null));
			soundList = makeXonoticSoundList();
			e.onChange = SoundList_Filter_Change;
			e.onChangeEntity = soundList;
			btn.onClickEntity = e;
			soundList.controlledTextbox = e;

	me.TR(me);
		me.TD(me, me.rows - 5, me.columns, soundList);

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, me.columns / 5, e = makeXonoticButton(ZCTX(_("MP^Stop")), '0 0 0'));
			e.onClick = StopSound_Click;
			e.onClickEntity = soundList;
		me.TD(me, 1, me.columns / 5, e = makeXonoticButton(ZCTX(_("MP^Play")), '0 0 0'));
			e.onClick = StartSound_Click;
			e.onClickEntity = soundList;
		me.TD(me, 1, me.columns / 5, e = makeXonoticButton(ZCTX(_("MP^Pause/Play")), '0 0 0'));
			e.onClick = PauseSound_Click;
			e.onClickEntity = soundList;
		me.TD(me, 1, me.columns / 5, e = makeXonoticButton(ZCTX(_("MP^Prev")), '0 0 0'));
			e.onClick = PrevSound_Click;
			e.onClickEntity = soundList;
		me.TD(me, 1, me.columns / 5, e = makeXonoticButton(ZCTX(_("MP^Next")), '0 0 0'));
			e.onClick = NextSound_Click;
			e.onClickEntity = soundList;
	me.TR(me);
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Set selected as menu track"), '0 0 0'));
			e.onClick = SoundList_Menu_Track_Change;
			e.onClickEntity = soundList;
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Reset default menu track"), '0 0 0'));
			e.onClick = SoundList_Menu_Track_Reset;
			e.onClickEntity = soundList;
}
#endif
