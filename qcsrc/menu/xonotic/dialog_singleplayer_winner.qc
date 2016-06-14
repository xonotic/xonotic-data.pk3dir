#include "dialog_singleplayer_winner.qh"

#include "image.qh"
#include "button.qh"

void XonoticWinnerDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, e = makeXonoticImage("/gfx/winner", -1));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
void XonoticWinnerDialog_focusEnter(entity me)
{
	m_play_click_sound(MENU_SOUND_WINNER);
}
