#include "dialog_media_musicplayer.qh"

#include "soundlist.qh"
#include "playlist.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "button.qh"
#include "checkbox.qh"

entity makeXonoticMusicPlayerTab()
{
	entity me;
	me = NEW(XonoticMusicPlayerTab);
	me.configureDialog(me);
	return me;
}
void XonoticMusicPlayerTab_fill(entity me)
{
	entity e;
	entity soundList, playList;
	float columns_nospacing = (me.columns - 0.2);

	me.gotoRC(me, 0.5, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, 2.5, e = makeXonoticInputBox(0, string_null));
			soundList = makeXonoticSoundList();
			e.onChange = SoundList_Filter_Change;
			e.onChangeEntity = soundList;
			playList = makeXonoticPlayList();
			soundList.playlist = playList;

	me.TR(me);
		me.TD(me, me.rows - 4.5, columns_nospacing / 2, soundList);

	me.gotoRC(me, me.rows - 3, 0);
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticButton(ZCTX(_("MUSICPL^Add")), '0 0 0'));
			e.onClick = SoundList_Add;
			e.onClickEntity = soundList;
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticButton(ZCTX(_("MUSICPL^Add all")), '0 0 0'));
			e.onClick = SoundList_Add_All;
			e.onClickEntity = soundList;
	me.TR(me);
		me.TD(me, 1, columns_nospacing / 2, e = makeXonoticButton(_("Set as menu track"), '0 0 0'));
			e.onClick = SoundList_Menu_Track_Change;
			e.onClickEntity = soundList;
	me.TR(me);
		me.TD(me, 1, columns_nospacing / 2, e = makeXonoticButton(_("Reset default menu track"), '0 0 0'));
			e.onClick = SoundList_Menu_Track_Reset;
			e.onClickEntity = soundList;
	me.TR(me);
	me.TR(me);
	me.gotoRC(me, 0.5, columns_nospacing / 2 + 0.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticTextLabel(0, _("Playlist:")));
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticCheckBox(0, "music_playlist_random0", _("Random order")));
	me.TR(me);
		me.TD(me, me.rows - 3.5, columns_nospacing / 2, playList);

	me.gotoRC(me, me.rows - 2, columns_nospacing / 2 + 0.2);
		me.TD(me, 1, columns_nospacing / 10, e = makeXonoticButton(ZCTX(_("MUSICPL^Stop")), '0 0 0'));
			e.onClick = StopSound_Click;
			e.onClickEntity = playList;
		me.TD(me, 1, columns_nospacing / 10, e = makeXonoticButton(ZCTX(_("MUSICPL^Play")), '0 0 0'));
			e.onClick = StartSound_Click;
			e.onClickEntity = playList;
		me.TD(me, 1, columns_nospacing / 10, e = makeXonoticButton(ZCTX(_("MUSICPL^Pause")), '0 0 0'));
			e.onClick = PauseSound_Click;
			e.onClickEntity = playList;
		me.TD(me, 1, columns_nospacing / 10, e = makeXonoticButton(ZCTX(_("MUSICPL^Prev")), '0 0 0'));
			e.onClick = PrevSound_Click;
			e.onClickEntity = playList;
		me.TD(me, 1, columns_nospacing / 10, e = makeXonoticButton(ZCTX(_("MUSICPL^Next")), '0 0 0'));
			e.onClick = NextSound_Click;
			e.onClickEntity = playList;
	me.TR(me);
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticButton(ZCTX(_("MUSICPL^Remove")), '0 0 0'));
			e.onClick = PlayList_Remove;
			e.onClickEntity = playList;
		me.TD(me, 1, columns_nospacing / 4, e = makeXonoticButton(ZCTX(_("MUSICPL^Remove all")), '0 0 0'));
			e.onClick = PlayList_Remove_All;
			e.onClickEntity = playList;
}
