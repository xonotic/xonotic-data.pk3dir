#include "dialog_media_demo.qh"

#include "demolist.qh"
#include "textlabel.qh"
#include "inputbox.qh"
#include "checkbox.qh"
#include "button.qh"

const float DMO_PLAY = 1;
const float DMO_TIME = 2;
void DemoConfirm_Check_Gamestatus(entity btn, entity me)
{
	if(!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)) || isdemo()) // we're not in a match, lets watch the demo
	{
		if(btn.democlicktype == DMO_PLAY)
			{ demolist.startDemo(demolist); }
		else if(btn.democlicktype == DMO_TIME)
			{ demolist.timeDemo(demolist); }
	}
	else // already in a match, player has to confirm
	{
		if(btn.democlicktype == DMO_PLAY)
			{ DialogOpenButton_Click(btn, main.demostartconfirmDialog); }
		else if(btn.democlicktype == DMO_TIME)
			{ DialogOpenButton_Click(btn, main.demotimeconfirmDialog); }
	}
}

entity makeXonoticDemoBrowserTab()
{
	entity me;
	me = NEW(XonoticDemoBrowserTab);
	me.configureDialog(me);
	return me;
}
void XonoticDemoBrowserTab_fill(entity me)
{
	entity e;
	demolist = makeXonoticDemoList();

	me.gotoRC(me, 0.5, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, 2.9, e = makeXonoticInputBox(0, string_null));
			e.onChange = DemoList_Filter_Change;
			e.onChangeEntity = demolist;

	me.gotoRC(me, 0.5, 3.7);
		me.TD(me, 1, 1.5, e = makeXonoticCheckBox(0, "cl_autodemo", _("Auto record demos")));
		me.TD(me, 1, 1, e = makeXonoticButton(_("Refresh"), '0 0 0'));
			e.onClick = DemoList_Refresh_Click;
			e.onClickEntity = demolist;

	me.gotoRC(me, 2, 0);
		me.TD(me, me.rows - 3, me.columns, demolist);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton_T(_("Timedemo"), '0 0 0',
			_("Benchmark how fast your computer can run the highlighted demo")));
			e.democlicktype = DMO_TIME;
			e.onClick = DemoConfirm_Check_Gamestatus;
			e.onClickEntity = me; // demolist is global anyway
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(ZCTX(_("DEMO^Play")), '0 0 0'));
			e.democlicktype = DMO_PLAY;
			e.onClick = DemoConfirm_Check_Gamestatus;
			e.onClickEntity = me; // demolist is global anyway
}
