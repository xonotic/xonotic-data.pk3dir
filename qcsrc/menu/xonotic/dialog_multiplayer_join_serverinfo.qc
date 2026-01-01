#include "dialog_multiplayer_join_serverinfo.qh"
#include <common/mapinfo.qh>

#include "tabcontroller.qh"
#include "serverlist.qh"
#include "playerlist.qh"
#include "inputbox.qh"
#include "textlabel.qh"
#include "button.qh"
#include "dialog_multiplayer_join_serverinfotab.qh"
#include "dialog_multiplayer_join_termsofservice.qh"


void XonoticServerInfoDialog_loadServerInfo(entity me, float i)
{
	bool pure_available;
	float m, pure_violations, freeslots, numh, maxp, numb, sflags;
	string s, typestr, versionstr, k, v, modname;

	// ====================================
	//  First clear and unzone the strings
	// ====================================
	strfree(me.currentServerName);
	strfree(me.currentServerCName);
	strfree(me.currentServerType);
	strfree(me.currentServerMap);
	strfree(me.currentServerPlayers);
	strfree(me.currentServerNumPlayers);
	strfree(me.currentServerNumBots);
	strfree(me.currentServerNumFreeSlots);
	strfree(me.currentServerMod);
	strfree(me.currentServerVersion);
	// not zoned!
	//	strfree(me.currentServerEncrypt);
	strfree(me.currentServerPure);
	strfree(me.currentServerKey);
	strfree(me.currentServerID);

	// ==========================
	//  Now, fill in the strings
	// ==========================
	me.currentServerName = strzone(gethostcachestring(SLIST_FIELD_NAME, i));
	me.infoTab.nameLabel.setText(me.infoTab.nameLabel, me.currentServerName);

	me.currentServerCName = strzone(gethostcachestring(SLIST_FIELD_CNAME, i));
	me.infoTab.cnameLabel.setText(me.infoTab.cnameLabel, me.currentServerCName);

	pure_available = false;
	pure_violations = -1;
	typestr = _("N/A");
	versionstr = _("N/A");

	s = gethostcachestring(SLIST_FIELD_QCSTATUS, i);
	m = tokenizebyseparator(s, ":");
	if(m >= 2)
	{
		typestr = argv(0);
		versionstr = argv(1);
	}
	freeslots = -1;
	sflags = -1;
	modname = "";
	bool ToSSpecified = false;
	for(int j = 2; j < m; ++j)
	{
		if(argv(j) == "")
			break;
		k = substring(argv(j), 0, 1);
		v = substring(argv(j), 1, -1);
		if(k == "P")
		{
			pure_available = true;
			pure_violations = stof(v);
		}
		else if(k == "S")
		{
			freeslots = stof(v);
		}
		else if(k == "F")
		{
			sflags = stof(v);
		}
		else if(k == "M")
		{
			modname = v;
		}
		else if(k == "T")
		{
			ToSSpecified = true;
			string downloadurl = v;
			if (downloadurl == "INVALID")
			{
				me.ToSTab.textBox.setText(me.ToSTab.textBox, _("No Terms of Service specified"));
			}
			else
			{
				downloadurl = strreplace("|", ":", downloadurl);
				me.ToSTab.loadToS(me.ToSTab, downloadurl);
			}
		}
	}

	if (!ToSSpecified)
	{
		me.ToSTab.textBox.setText(me.ToSTab.textBox, _("No Terms of Service specified"));
	}

#ifdef COMPAT_NO_MOD_IS_XONOTIC
	if(modname == "")
		modname = "Xonotic";
#endif

	s = gethostcachestring(SLIST_FIELD_MOD, i);
	if(s != "data")
		modname = sprintf("%s (%s)", modname, s);

	Gametype j = MapInfo_Type_FromString(typestr, false, false); // try and get the real name of the gametype
	if(j) { typestr = MapInfo_Type_ToText(j); } // only set it if we actually found it

	me.currentServerType = strzone(typestr);
	me.infoTab.typeLabel.setText(me.infoTab.typeLabel, me.currentServerType);

	me.currentServerMap = strzone(gethostcachestring(SLIST_FIELD_MAP, i));
	me.infoTab.mapLabel.setText(me.infoTab.mapLabel, me.currentServerMap);

	me.currentServerPlayers = strzone(gethostcachestring(SLIST_FIELD_PLAYERS, i));
	me.infoTab.rawPlayerList.setPlayerList(me.infoTab.rawPlayerList, me.currentServerPlayers);

	numh = gethostcachenumber(SLIST_FIELD_NUMHUMANS, i);
	maxp = gethostcachenumber(SLIST_FIELD_MAXPLAYERS, i);
	numb = gethostcachenumber(SLIST_FIELD_NUMBOTS, i);
	me.currentServerNumPlayers = strzone(sprintf("%d/%d", numh, maxp));
	me.infoTab.numPlayersLabel.setText(me.infoTab.numPlayersLabel, me.currentServerNumPlayers);

	s = ftos(numb);
	me.currentServerNumBots = strzone(s);
	me.infoTab.numBotsLabel.setText(me.infoTab.numBotsLabel, me.currentServerNumBots);

	if(freeslots < 0) { freeslots = maxp - numh - numb; }
	s = ftos(freeslots);
	me.currentServerNumFreeSlots = strzone(s);
	me.infoTab.numFreeSlotsLabel.setText(me.infoTab.numFreeSlotsLabel, me.currentServerNumFreeSlots);

	me.currentServerMod = ((modname == "Xonotic") ? ZCTX(_("MOD^Default")) : modname);
	me.currentServerMod = strzone(me.currentServerMod);
	me.infoTab.modLabel.setText(me.infoTab.modLabel, me.currentServerMod);

	me.currentServerVersion = strzone(versionstr);
	me.infoTab.versionLabel.setText(me.infoTab.versionLabel, me.currentServerVersion);

	me.currentServerPure = ((!pure_available) ? _("N/A") : (pure_violations == 0) ? _("Official") : sprintf(_("%d modified"), pure_violations));
	me.currentServerPure = strzone(me.currentServerPure);
	me.infoTab.pureLabel.setText(me.infoTab.pureLabel, me.currentServerPure);

	s = crypto_getencryptlevel(me.currentServerCName);
	if(s == "")
	{
		if(cvar("crypto_aeslevel") >= 3)
			me.currentServerEncrypt = _("N/A (auth library missing, can't connect)");
		else
			me.currentServerEncrypt = _("N/A (auth library missing)");
	}
	else switch(stof(substring(s, 0, 1)))
	{
		case 0:
			if(cvar("crypto_aeslevel") >= 3)
				me.currentServerEncrypt = _("Not supported (can't connect)");
			else
				me.currentServerEncrypt = _("Not supported (won't encrypt)");
			break;
		case 1:
			if(cvar("crypto_aeslevel") >= 2)
				me.currentServerEncrypt = _("Supported (will encrypt)");
			else
				me.currentServerEncrypt = _("Supported (won't encrypt)");
			break;
		case 2:
			if(cvar("crypto_aeslevel") >= 1)
				me.currentServerEncrypt = _("Requested (will encrypt)");
			else
				me.currentServerEncrypt = _("Requested (won't encrypt)");
			break;
		case 3:
			if(cvar("crypto_aeslevel") <= 0)
				me.currentServerEncrypt = _("Required (can't connect)");
			else
				me.currentServerEncrypt = _("Required (will encrypt)");
			break;
	}
	me.infoTab.encryptLabel.setText(me.infoTab.encryptLabel, me.currentServerEncrypt);
	setZonedTooltip(me.infoTab.encryptLabel, _("Use the `crypto_aeslevel` cvar to change your preferences"), string_null);

	s = crypto_getidfp(me.currentServerCName);
	if (!s) { s = _("N/A"); }
	me.currentServerID = strzone(s);
	me.infoTab.idLabel.setText(me.infoTab.idLabel, me.currentServerID);

	s = crypto_getkeyfp(me.currentServerCName);
	if (!s) { s = _("N/A"); }
	me.currentServerKey = strzone(s);
	me.infoTab.keyLabel.setText(me.infoTab.keyLabel, me.currentServerKey);

	me.currentServerStatsStatus = ((sflags >= 0 && (sflags & SERVERFLAG_PLAYERSTATS)) ? ((sflags & SERVERFLAG_PLAYERSTATS_CUSTOM) ? _("custom stats server") : _("stats enabled")) : _("stats disabled"));
	me.currentServerStatsStatus = strzone(me.currentServerStatsStatus);
	me.infoTab.statsLabel.setText(me.infoTab.statsLabel, me.currentServerStatsStatus);
}

void XonoticServerInfoDialog_fill(entity me)
{
	entity mc, e;
	mc = makeXonoticTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Status"), me.infoTab = makeXonoticServerInfoTab()));
		me.TD(me, 1, 1, e = mc.makeTabButton(mc, _("Terms of Service"), me.ToSTab = makeXonoticServerToSTab()));

	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Close"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
		//me.TD(me, 1, me.columns/3, e = makeXonoticButton("", '0 0 0')); // TODO: Add bookmark button here
		//	e.onClick = ServerList_Favorite_Click;
		//	e.onClickEntity = slist;
		//	slist.favoriteButton = e;
		me.TD(me, 1, me.columns/2, e = makeXonoticButton(_("Join!"), '0 0 0'));
			e.onClick = Join_Click;
			e.onClickEntity = me;
}

void Join_Click(entity btn, entity me)
{
	localcmd("connect ", me.currentServerCName, "\n");
}

