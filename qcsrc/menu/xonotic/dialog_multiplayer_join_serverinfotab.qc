#include "dialog_multiplayer_join_serverinfo.qh"
#include "dialog_multiplayer_join_serverinfotab.qh"
#include <common/mapinfo.qh>

#include "serverlist.qh"
#include "playerlist.qh"
#include "inputbox.qh"
#include "textlabel.qh"
#include "button.qh"


entity makeXonoticServerInfoTab()
{
	entity me;
	me = NEW(XonoticServerInfoTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerInfoTab_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Hostname:")));
		me.TD(me, 1, 4.6, e = makeXonoticTextLabel(0.5, ""));
			e.colorL = SKINCOLOR_SERVERINFO_NAME;
			e.allowCut = true;
			me.nameLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Address:")));
		me.TD(me, 1, 4.6, e = makeXonoticTextLabel(0.5, ""));
			e.colorL = SKINCOLOR_SERVERINFO_IP;
			e.allowCut = true;
			me.cnameLabel = e;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Gametype:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.typeLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Map:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.mapLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Mod:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.modLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Version:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.versionLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Settings:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.pureLabel = e;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Players:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.numPlayersLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Bots:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.numBotsLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Free slots:")));
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.numFreeSlotsLabel = e;

	me.gotoRC(me, me.rows - 5, 0);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Encryption:")));
		me.TD(me, 1, 5.4, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.encryptLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("ID:")));
		me.TD(me, 1, 5.4, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.keyLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Key:")));
		me.TD(me, 1, 5.4, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.idLabel = e;
	me.TR(me);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Stats:")));
		me.TD(me, 1, 5.4, e = makeXonoticTextLabel(0, ""));
			e.allowCut = true;
			me.statsLabel = e;

	me.gotoRC(me, 2, 2.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticTextLabel(0, _("Players:")));
	me.TR(me);
		me.TD(me, me.rows - 8, 4, e = makeXonoticPlayerList());
			me.rawPlayerList = e;
}

