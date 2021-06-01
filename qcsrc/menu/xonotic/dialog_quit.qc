#include "dialog_quit.qh"

#include "textlabel.qh"
#include "commandbutton.qh"
#include "button.qh"

void Disconnect_Click(entity btn, entity me)
{
	localcmd(QUITGAME_CMD);
	Dialog_Close(btn, me);
}

void XonoticQuitDialog_draw(entity me)
{
	entity e = me.disconnectButton;
	e.disabled = !(gamestatus & (GAME_ISSERVER | GAME_CONNECTED));
	e.setText(e, quitGameButton_getText(e));
	setZonedTooltip(e, quitGameButton_getTooltip(e), string_null);
	SUPER(XonoticQuitDialog).draw(me);
}

void XonoticQuitDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, me.disconnectButton = makeXonoticButton(string_null, '0 0 0'));
			me.disconnectButton.onClick = Disconnect_Click;
			me.disconnectButton.onClickEntity = me;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Quit Xonotic"), '1 0 0', "echo ]quit; quit", 0));
		me.TD(me, 1, 1, e = makeXonoticButton(_("Cancel"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
