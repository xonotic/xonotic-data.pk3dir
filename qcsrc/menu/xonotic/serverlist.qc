#include "serverlist.qh"

#include "checkbox.qh"
#include "inputbox.qh"
#include "mainwindow.qh"
#include "dialog_multiplayer_join_serverinfo.qh"
#include <common/mapinfo.qh>

#define IsFavorite(srv) IsServerInList(cvar_string("net_slist_favorites"), srv)
#define IsPromoted(srv) IsServerInList(_Nex_ExtResponseSystem_PromotedServers, srv)
#define IsRecommended(srv) IsServerInList(_Nex_ExtResponseSystem_RecommendedServers, srv)

float m_gethostcachecategory(float entry) { return CategoryOverride(CategoryForEntry(entry)); }

void SL_ProcessCategoryOverrides(.string override_field_string, .float override_field)
{
	for (int i = 0; i < category_ent_count; ++i)
	{
		string s = categories[i].override_field_string;
		if (s != "" && s != categories[i].cat_name)
		{
			int catnum = 0;
			for (int x = 0; x < category_ent_count; ++x)
			{
				if(categories[x].cat_name == s)
				{
					catnum = x + 1;
					break;
				}
			}
			if (catnum)
			{
				strfree(categories[i].override_field_string);
				categories[i].override_field = catnum;
				continue;
			}
			LOG_INFOF("RegisterSLCategories(): Improper override '%s' for category '%s'!", s, categories[i].cat_name);
		}
		strfree(categories[i].override_field_string);
		categories[i].override_field = 0;
	}
}

void RegisterSLCategories()
{
	entity cat;
	#define SLIST_CATEGORY(name,enoverride,dioverride,str) \
		SET_FIELD_COUNT(name, CATEGORY_FIRST, category_ent_count) \
		CHECK_MAX_COUNT(name, MAX_CATEGORIES, category_ent_count, "SLIST_CATEGORY") \
		cat = categories[name - 1] = new(slist_category); \
		cat.cat_name = #name; \
		cat.cat_enoverride_string = strzone(SLIST_CATEGORY_AUTOCVAR(name)); \
		cat.cat_dioverride_string = strzone(dioverride); \
		cat.cat_string = strzone(str);
	SLIST_CATEGORIES
	#undef SLIST_CATEGORY

	SL_ProcessCategoryOverrides(cat_enoverride_string, cat_enoverride);
	SL_ProcessCategoryOverrides(cat_dioverride_string, cat_dioverride);
}

// Supporting Functions
entity RetrieveCategoryEnt(int catnum)
{
	if((catnum > 0) && (catnum <= category_ent_count))
	{
		return categories[catnum - 1];
	}
	else
	{
		error(sprintf("RetrieveCategoryEnt(%d): Improper category number!\n", catnum));
		return NULL;
	}
}

bool IsServerInList(string list, string srv)
{
	if(srv == "")
		return false;
	srv = netaddress_resolve(srv, 26000);
	if(srv == "")
		return false;
	string p = crypto_getidfp(srv);
	int n = tokenize_console(list);
	for(int i = 0; i < n; ++i)
	{
		if(substring(argv(i), 0, 1) != "[" && strlen(argv(i)) == 44 && strstrofs(argv(i), ".", 0) < 0)
		{
			if(p && argv(i) == p)
				return true;
		}
		else
		{
			if(srv == netaddress_resolve(argv(i), 26000))
				return true;
		}
	}
	return false;
}

int CategoryOverride(int cat)
{
	entity catent = RetrieveCategoryEnt(cat);
	if(catent)
	{
		int override = (autocvar_menu_slist_categories ? catent.cat_enoverride : catent.cat_dioverride);
		if(override) { return override; }
		else { return cat; }
	}
	else
	{
		error(sprintf("CategoryOverride(%d): Improper category number!\n", cat));
		return cat;
	}
}

int CategoryForEntry(int entry)
{
	string s, k, v, modtype = "";
	int j, m, impure = 0, freeslots = 0, sflags = 0;
	s = gethostcachestring(SLIST_FIELD_QCSTATUS, entry);
	m = tokenizebyseparator(s, ":");

	for(j = 2; j < m; ++j)
	{
		if(argv(j) == "") { break; }
		k = substring(argv(j), 0, 1);
		v = substring(argv(j), 1, -1);
		switch(k)
		{
			case "P": { impure = stof(v); break; }
			case "S": { freeslots = stof(v); break; }
			case "F": { sflags = stof(v); break; }
			case "M": { modtype = strtolower(v); break; }
		}
	}

	if(modtype != "xonotic") { impure += autocvar_menu_slist_modimpurity; }

	// check if this server is favorited
	if(gethostcachenumber(SLIST_FIELD_ISFAVORITE, entry)) { return CAT_FAVORITED; }

	// now check if it's recommended
	if(autocvar_menu_slist_recommendations)
	{
		string cname = gethostcachestring(SLIST_FIELD_CNAME, entry);

		if(IsPromoted(cname)) { return CAT_RECOMMENDED; }
		else
		{
			float recommended = 0;
			if(autocvar_menu_slist_recommendations & 1)
			{
				if(IsRecommended(cname)) { ++recommended; }
				else { --recommended; }
			}
			if(autocvar_menu_slist_recommendations & 2)
			{
				if(
					///// check for minimum free slots
					(freeslots >= autocvar_menu_slist_recommendations_minfreeslots)

					&& // check for purity requirement
					(
						(autocvar_menu_slist_recommendations_purethreshold < 0)
						||
						(impure <= autocvar_menu_slist_recommendations_purethreshold)
					)

					&& // check for minimum amount of humans
					(
						gethostcachenumber(SLIST_FIELD_NUMHUMANS, entry)
						>=
						autocvar_menu_slist_recommendations_minhumans
					)

					&& // check for maximum latency
					(
						gethostcachenumber(SLIST_FIELD_PING, entry)
						<=
						autocvar_menu_slist_recommendations_maxping
					)
				)
					{ ++recommended; }
				else
					{ --recommended; }
			}
			if(recommended > 0) { return CAT_RECOMMENDED; }
		}
	}

	// if not favorited or recommended, check modname
	if(modtype != "xonotic")
	{
		switch(modtype)
		{
			// old servers which don't report their mod name are considered modified now
			case "": { return CAT_MODIFIED; }

			case "xpm": { return CAT_XPM; }
			case "minstagib":
			case "instagib": { return CAT_INSTAGIB; }
			case "overkill": { return CAT_OVERKILL; }

			// "cts" is allowed as compat, xdf is replacement
			case "cts":
			case "xdf": { return CAT_DEFRAG; }

			default: { LOG_TRACEF("Found strange mod type: %s", modtype); return CAT_MODIFIED; }
		}
	}

	// must be normal or impure server
	//return ((impure > autocvar_menu_slist_purethreshold) ? CAT_MODIFIED : CAT_NORMAL);
	return CAT_NORMAL; // don't separate normal and modified server categories
}

METHOD(XonoticServerList, toggleFavorite, void(XonoticServerList this, string srv))
{
	bool adding = true;
	string srv_resolved = netaddress_resolve(srv, 26000);
	string p = crypto_getidfp(srv_resolved);
	string s = cvar_string("net_slist_favorites");
	string ret = s;
	for (int i = 0, n = tokenize_console(s); i < n; ++i)
	{
		bool match;
		if (substring(argv(i), 0, 1) != "[" && strlen(argv(i)) == 44 && strstrofs(argv(i), ".", 0) < 0)
		{
			// it's a pubkey hash
			match = (p && p == argv(i));
		}
		else
		{
			// it's an ip
			match = (srv_resolved == netaddress_resolve(argv(i), 26000));
		}
		if (!match) continue;
		// on match: remove
		adding = false;
		string before = (i > 0) ? substring(s, 0, argv_end_index(i - 1)) : "";
		string after = (i < n - 1) ? substring(s, argv_start_index(i + 1), -1) : "";
		s = strcat(before, (before != "" && after != "" ? " " : ""), after);
		ret = s;
		// keep searching
		// TODO: why not break here?
		n = tokenize_console(s);
		--i; // offset the increment that is about to happen
	}
	if (adding)
	{
		ret = strcat(s, (s != "" ? " " : ""), p ? p : srv);
	}
	cvar_set("net_slist_favorites", ret);
	this.refreshServerList(this, REFRESHSERVERLIST_RESORT);
}

void ServerList_Update_favoriteButton(entity btn, entity me)
{
	entity e = me.favoriteButton;
	if(IsFavorite(me.ipAddressBox.text))
	{
		e.setText(e, ZCTX(_("SERVER^Remove favorite")));
		setZonedTooltip(e, _("Remove the currently highlighted server from bookmarks"), string_null);
	}
	else
	{
		e.setText(e, ZCTX(_("SERVER^Favorite")));
		setZonedTooltip(e, _("Bookmark the currently highlighted server so that it's faster to find in the future"), string_null);
	}
}

entity makeXonoticServerList()
{
	entity me;
	me = NEW(XonoticServerList);
	me.configureXonoticServerList(me);
	return me;
}
void XonoticServerList_configureXonoticServerList(entity me)
{
	me.configureXonoticListBox(me);

	// update field ID's
	#define SLIST_FIELD(suffix,name) SLIST_FIELD_##suffix = gethostcacheindexforkey(name);
	SLIST_FIELDS
	#undef SLIST_FIELD

	// clear list
	me.nItems = 0;
}
void XonoticServerList_setSelected(entity me, int i)
{
	me.lockedSelectedItem = false;
	//int save = me.selectedItem;
	SUPER(XonoticServerList).setSelected(me, i);
	/*
	if(me.selectedItem == save)
		return;
	*/
	if(me.nItems == 0)
		return;
	if(gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT) != me.nItems)
		return; // sorry, it would be wrong

	strcpy(me.selectedServer, gethostcachestring(SLIST_FIELD_CNAME, me.selectedItem));

	me.ipAddressBox.setText(me.ipAddressBox, me.selectedServer);
	me.ipAddressBox.cursorPos = strlen(me.selectedServer);
	me.ipAddressBoxFocused = -1;
}
void XonoticServerList_refreshServerList(entity me, int mode)
{
	//print("refresh of type ", ftos(mode), "\n");

	if(mode >= REFRESHSERVERLIST_REFILTER)
	{
		string s = me.filterString;

		string typestr;
		int m = strstrofs(s, ":", 0);
		if(m >= 0)
		{
			typestr = substring(s, 0, m);
			s = substring(s, m + 1, strlen(s) - m - 1);
			while(substring(s, 0, 1) == " ")
				s = substring(s, 1, strlen(s) - 1);
		}
		else
			typestr = "";

		string modstr = cvar_string("menu_slist_modfilter");

		m = SLIST_MASK_AND - 1;
		resethostcachemasks();

		// show full button
		if(!me.filterShowFull)
		{
			sethostcachemasknumber(++m, SLIST_FIELD_FREESLOTS, 1, SLIST_TEST_GREATEREQUAL); // can connect
			// There's several reasons to join a server where nJoinAllowed() reported 0 free slots, such as:
			// to spec the match, chat, vote for a gametype with more players, or join your reserved tournament slot.
			//sethostcachemaskstring(++m, SLIST_FIELD_QCSTATUS, ":S0:", SLIST_TEST_NOTCONTAIN); // g_maxplayers support
		}

		// show empty button
		if(!me.filterShowEmpty)
			sethostcachemasknumber(++m, SLIST_FIELD_NUMHUMANS, 1, SLIST_TEST_GREATEREQUAL);

		// show laggy button
		if(!me.filterShowLaggy && autocvar_menu_slist_maxping > 0)
			sethostcachemasknumber(++m, SLIST_FIELD_PING, autocvar_menu_slist_maxping, SLIST_TEST_LESSEQUAL);

		// gametype filtering
		if(typestr != "")
			sethostcachemaskstring(++m, SLIST_FIELD_QCSTATUS, strcat(typestr, ":"), SLIST_TEST_STARTSWITH);

		// mod filtering
		if(modstr != "")
		{
			if(substring(modstr, 0, 1) == "!")
				sethostcachemaskstring(++m, SLIST_FIELD_MOD, resolvemod(substring(modstr, 1, strlen(modstr) - 1)), SLIST_TEST_NOTEQUAL);
			else
				sethostcachemaskstring(++m, SLIST_FIELD_MOD, resolvemod(modstr), SLIST_TEST_EQUAL);
		}

		// server banning
		int n = tokenizebyseparator(_Nex_ExtResponseSystem_BannedServers, " ");
		for(int i = 0; i < n; ++i)
			if(argv(i) != "")
				sethostcachemaskstring(++m, SLIST_FIELD_CNAME, argv(i), SLIST_TEST_NOTSTARTSWITH);

		m = SLIST_MASK_OR - 1;
		if(s != "")
		{
			sethostcachemaskstring(++m, SLIST_FIELD_NAME, s, SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SLIST_FIELD_MAP, s, SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SLIST_FIELD_PLAYERS, s, SLIST_TEST_CONTAINS);
			sethostcachemaskstring(++m, SLIST_FIELD_QCSTATUS, strcat(s, ":"), SLIST_TEST_STARTSWITH);
		}

		int sorting_flags = 0;
		//sorting_flags |= SLSF_FAVORITES;
		sorting_flags |= SLSF_CATEGORIES;
		if(me.currentSortOrder < 0) { sorting_flags |= SLSF_DESCENDING; }
		sethostcachesort(me.currentSortField, sorting_flags);
	}

	resorthostcache();
	if(mode >= REFRESHSERVERLIST_ASK)
		refreshhostcache(mode >= REFRESHSERVERLIST_RESET);
}
void XonoticServerList_focusEnter(entity me)
{
	SUPER(XonoticServerList).focusEnter(me);
	if(time < me.nextRefreshTime)
	{
		//print("sorry, no refresh yet\n");
		return;
	}
	me.nextRefreshTime = time + 10;
	me.refreshServerList(me, REFRESHSERVERLIST_ASK);
}

void XonoticServerList_draw(entity me)
{
	me.serversHeight = (autocvar_menu_slist_categories > 0 ? 1.0 : me.categoriesHeight);

	if(_Nex_ExtResponseSystem_BannedServersNeedsRefresh)
	{
		if(!me.needsRefresh)
			me.needsRefresh = 2;
		_Nex_ExtResponseSystem_BannedServersNeedsRefresh = 0;
	}

	if(_Nex_ExtResponseSystem_PromotedServersNeedsRefresh)
	{
		if(!me.needsRefresh)
			me.needsRefresh = 3;
		_Nex_ExtResponseSystem_PromotedServersNeedsRefresh = 0;
	}

	if(_Nex_ExtResponseSystem_RecommendedServersNeedsRefresh)
	{
		if(!me.needsRefresh)
			me.needsRefresh = 3;
		_Nex_ExtResponseSystem_RecommendedServersNeedsRefresh = 0;
	}

	if(me.currentSortField == -1)
	{
		me.setSortOrder(me, SLIST_FIELD_PING, +1);
		me.refreshServerList(me, REFRESHSERVERLIST_RESET);
	}
	else if(me.needsRefresh == 1)
	{
		me.needsRefresh = 2; // delay by one frame to make sure "slist" has been executed
	}
	else if(me.needsRefresh == 2)
	{
		me.needsRefresh = 0;
		me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);
	}
	else if(me.needsRefresh == 3)
	{
		me.needsRefresh = 0;
		me.refreshServerList(me, REFRESHSERVERLIST_RESORT);
	}

	bool owned = ((me.selectedServer == me.ipAddressBox.text) && (me.ipAddressBox.text != ""));

	for(int i = 0; i < category_draw_count; ++i) { category_name[i] = -1; category_item[i] = -1; }
	category_draw_count = 0;

	me.nItems = gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);

	if(autocvar_menu_slist_categories >= 0) // if less than 0, don't even draw a category heading for favorites
	{
		int itemcount = me.nItems;

		//float visible = floor(me.scrollPos / me.itemHeight);
		// ^ unfortunately no such optimization can be made-- we must process through the
		// entire list, otherwise there is no way to know which item is first in its category.

		// binary search method suggested by div
		float begin = 0;
		for(int j = 1; j <= category_ent_count; ++j) {
			float first = begin;
			float last = (itemcount - 1);
			if (first > last) {
				// List is empty.
				break;
			}
			float catf = gethostcachenumber(SLIST_FIELD_CATEGORY, first);
			float catl = gethostcachenumber(SLIST_FIELD_CATEGORY, last);
			if (catf > j) {
				// The first one is already > j.
				// Therefore, category j does not exist.
				// Higher numbered categories do exist though.
			} else if (catl < j) {
				// The last one is < j.
				// Thus this category - and any following -
				// don't exist.
				break;
			} else if (catf == j) {
				// Starts at first. This breaks the loop
				// invariant in the binary search and thus has
				// to be handled separately.
				if(gethostcachenumber(SLIST_FIELD_CATEGORY, first) != j)
					error("Category mismatch I");
				if(first > 0)
					if(gethostcachenumber(SLIST_FIELD_CATEGORY, first - 1) == j)
						error("Category mismatch II");
				category_name[category_draw_count] = j;
				category_item[category_draw_count] = first;
				++category_draw_count;
				begin = first + 1;
			} else {
				// At this point, catf <= j < catl, thus
				// catf < catl, thus first < last.
				// INVARIANTS:
				// last - first >= 1
				// catf == gethostcachenumber(SLIST_FIELD_CATEGORY(first)
				// catl == gethostcachenumber(SLIST_FIELD_CATEGORY(last)
				// catf < j
				// catl >= j
				while (last - first > 1) {
					float middle = floor((first + last) / 2);
					// By loop condition, middle != first && middle != last.
					float cat = gethostcachenumber(SLIST_FIELD_CATEGORY, middle);
					if (cat >= j) {
						last = middle;
						catl = cat;
					} else {
						first = middle;
						catf = cat;
					}
				}
				if (catl == j) {
					if(gethostcachenumber(SLIST_FIELD_CATEGORY, last) != j)
						error("Category mismatch III");
					if(last > 0)
						if(gethostcachenumber(SLIST_FIELD_CATEGORY, last - 1) == j)
							error("Category mismatch IV");
					category_name[category_draw_count] = j;
					category_item[category_draw_count] = last;
					++category_draw_count;
					begin = last + 1; // already scanned through these, skip 'em
				}
				else
					begin = last; // already scanned through these, skip 'em
			}
		}
		if(autocvar_menu_slist_categories_onlyifmultiple && (category_draw_count == 1))
		{
			category_name[0] = -1;
			category_item[0] = -1;
			category_draw_count = 0;
			me.nItems = itemcount;
		}
	}

	me.connectButton.disabled = (me.ipAddressBox.text == "");
	me.infoButton.disabled = !owned;
	me.favoriteButton.disabled = (me.ipAddressBox.text == "");

	bool found = false;
	if(me.lockedSelectedItem)
	{
		if(me.nItems > 0)
		{
			if(gethostcachestring(SLIST_FIELD_CNAME, me.selectedItem) != me.selectedServer)
			{
				strcpy(me.selectedServer, gethostcachestring(SLIST_FIELD_CNAME, me.selectedItem));
			}
			found = true;
		}
	}
	else if(me.selectedServer)
	{
		for(int i = 0; i < me.nItems; ++i)
		{
			if(gethostcachestring(SLIST_FIELD_CNAME, i) == me.selectedServer)
			{
				// don't follow the selected item with SUPER(XonoticServerList).setSelected(me, i);
				me.selectedItem = i;
				found = true;
				break;
			}
		}
	}
	if(!found)
	{
		if(me.nItems > 0)
		{
			// selected server disappeared, select the last server (scrolling to it)
			if(me.selectedItem >= me.nItems)
				SUPER(XonoticServerList).setSelected(me, me.nItems - 1);
			strcpy(me.selectedServer, gethostcachestring(SLIST_FIELD_CNAME, me.selectedItem));
		}
	}

	if(owned)
	{
		if(me.selectedServer != me.ipAddressBox.text)
		{
			me.ipAddressBox.setText(me.ipAddressBox, me.selectedServer);
			me.ipAddressBox.cursorPos = strlen(me.selectedServer);
			me.ipAddressBoxFocused = -1;
		}
	}

	if(me.ipAddressBoxFocused != me.ipAddressBox.focused)
	{
		if(me.ipAddressBox.focused || me.ipAddressBoxFocused < 0)
			ServerList_Update_favoriteButton(NULL, me);
		me.ipAddressBoxFocused = me.ipAddressBox.focused;
	}

	SUPER(XonoticServerList).draw(me);
}
void ServerList_PingSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, SLIST_FIELD_PING, +1);
}
void ServerList_NameSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, SLIST_FIELD_NAME, -1); // why?
}
void ServerList_MapSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, SLIST_FIELD_MAP, -1); // why?
}
void ServerList_PlayerSort_Click(entity btn, entity me)
{
	me.setSortOrder(me, SLIST_FIELD_NUMHUMANS, -1);
}
void ServerList_TypeSort_Click(entity btn, entity me)
{
	string s = me.filterString;
	int m = strstrofs(s, ":", 0);
	if(m >= 0)
	{
		s = substring(s, 0, m);
		while(substring(s, m+1, 1) == " ") // skip spaces
			++m;
	}
	else
		s = "";

	Gametype first = NULL; FOREACH(Gametypes, !first, first = it; break);
	bool flag = false;
	FOREACH(Gametypes, s == MapInfo_Type_ToString(it), {
		// the type was found
		// choose the next one
		flag = true;
		s = MapInfo_Type_ToString(REGISTRY_GET(Gametypes, it.m_id + 1));
		if (s == "") s = MapInfo_Type_ToString(first);
		break;
	});
	if (!flag) {
		// no type was found
		// choose the first one
		s = MapInfo_Type_ToString(first);
	}

	if(s != "") s = strcat(s, ":");
	s = strcat(s, substring(me.filterString, m+1, strlen(me.filterString) - m - 1));

	me.controlledTextbox.setText(me.controlledTextbox, s);
	me.controlledTextbox.keyDown(me.controlledTextbox, K_END, 0, 0);
	me.controlledTextbox.keyUp(me.controlledTextbox, K_END, 0, 0);
	//ServerList_Filter_Change(me.controlledTextbox, me);
}
void ServerList_Filter_Change(entity box, entity me)
{
	strfree(me.filterString);
	if(box.text != "")
		me.filterString = strzone(box.text);
	me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);

	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}
void ServerList_Categories_Click(entity box, entity me)
{
	box.setChecked(box, autocvar_menu_slist_categories = !autocvar_menu_slist_categories);
	me.refreshServerList(me, REFRESHSERVERLIST_RESORT);

	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}
void ServerList_ShowEmpty_Click(entity box, entity me)
{
	box.setChecked(box, me.filterShowEmpty = !me.filterShowEmpty);
	me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);

	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}
void ServerList_ShowFull_Click(entity box, entity me)
{
	box.setChecked(box, me.filterShowFull = !me.filterShowFull);
	me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);

	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}
void ServerList_ShowLaggy_Click(entity box, entity me)
{
	box.setChecked(box, me.filterShowLaggy = !me.filterShowLaggy);
	me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);

	me.ipAddressBox.setText(me.ipAddressBox, "");
	me.ipAddressBox.cursorPos = 0;
	me.ipAddressBoxFocused = -1;
}
void XonoticServerList_setSortOrder(entity me, int fld, int direction)
{
	if(me.currentSortField == fld)
		direction = -me.currentSortOrder;
	me.currentSortOrder = direction;
	me.currentSortField = fld;
	me.sortButton1.forcePressed = (fld == SLIST_FIELD_PING);
	me.sortButton2.forcePressed = (fld == SLIST_FIELD_NAME);
	me.sortButton3.forcePressed = (fld == SLIST_FIELD_MAP);
	me.sortButton4.forcePressed = false;
	me.sortButton5.forcePressed = (fld == SLIST_FIELD_NUMHUMANS);
	me.selectedItem = 0;
	strfree(me.selectedServer);
	me.refreshServerList(me, REFRESHSERVERLIST_REFILTER);
}
void XonoticServerList_positionSortButton(entity me, entity btn, float theOrigin, float theSize, string theTitle, void(entity, entity) theFunc)
{
	vector originInLBSpace = eY * (-me.itemHeight);
	vector sizeInLBSpace = eY * me.itemHeight + eX * (1 - me.controlWidth);

	vector originInDialogSpace = boxToGlobal(originInLBSpace, me.Container_origin, me.Container_size);
	vector sizeInDialogSpace = boxToGlobalSize(sizeInLBSpace, me.Container_size);

	btn.Container_origin_x = originInDialogSpace.x + sizeInDialogSpace.x * theOrigin;
	btn.Container_size_x   =                         sizeInDialogSpace.x * theSize;
	btn.setText(btn, theTitle);
	btn.onClick = theFunc;
	btn.onClickEntity = me;
	btn.resized = 1;
}
void XonoticServerList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	SUPER(XonoticServerList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.realFontSize_y = me.fontSize / (absSize.y * me.itemHeight);
	me.realFontSize_x = me.fontSize / (absSize.x * (1 - me.controlWidth));
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	me.columnIconsOrigin = 0;
	me.columnIconsSize = me.realFontSize.x * 5 * me.iconsSizeFactor;
	me.columnPingSize = me.realFontSize.x * 3;
	me.columnMapSize = me.realFontSize.x * 10;
	me.columnTypeSize = me.realFontSize.x * 4;
	me.columnPlayersSize = me.realFontSize.x * 5;
	me.columnNameSize = 1 - me.columnPlayersSize - me.columnMapSize - me.columnPingSize - me.columnIconsSize - me.columnTypeSize - 4 * me.realFontSize.x;
	// no me.realFontSize.x separation between icons and ping columns because in practice they are already separated
	me.columnPingOrigin = me.columnIconsOrigin + me.columnIconsSize;
	me.columnNameOrigin = me.columnPingOrigin + me.columnPingSize + me.realFontSize.x;
	me.columnMapOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x;
	me.columnTypeOrigin = me.columnMapOrigin + me.columnMapSize + me.realFontSize.x;
	me.columnPlayersOrigin = me.columnTypeOrigin + me.columnTypeSize + me.realFontSize.x;

	me.positionSortButton(me, me.sortButton1, me.columnPingOrigin, me.columnPingSize, _("Ping"), ServerList_PingSort_Click);
	me.positionSortButton(me, me.sortButton2, me.columnNameOrigin, me.columnNameSize, _("Hostname"), ServerList_NameSort_Click);
	me.positionSortButton(me, me.sortButton3, me.columnMapOrigin, me.columnMapSize, _("Map"), ServerList_MapSort_Click);
	me.positionSortButton(me, me.sortButton4, me.columnTypeOrigin, me.columnTypeSize, _("Type"), ServerList_TypeSort_Click);
	me.positionSortButton(me, me.sortButton5, me.columnPlayersOrigin, me.columnPlayersSize, _("Players"), ServerList_PlayerSort_Click);

	int f = me.currentSortField;
	if(f >= 0)
	{
		me.currentSortField = -1;
		me.setSortOrder(me, f, me.currentSortOrder); // force resetting the sort order
	}
}
void ServerList_Connect_Click(entity btn, entity me)
{
	if (me.ipAddressBox.text != "")
		localcmd(sprintf("connect %s\n", me.ipAddressBox.text));
}
void ServerList_Favorite_Click(entity btn, entity this)
{
	string addr = this.ipAddressBox.text;
	string ipstr = netaddress_resolve(addr, 26000);
	if (ipstr == "") return;
	m_play_click_sound(MENU_SOUND_SELECT);
	this.toggleFavorite(this, addr);
	this.ipAddressBoxFocused = -1;
}
void ServerList_Info_Click(entity btn, entity me)
{
	if (me.nItems != 0)
		main.serverInfoDialog.loadServerInfo(main.serverInfoDialog, me.selectedItem);

	float thisPos = me.getItemStart(me, me.selectedItem);
	float thisHeight = me.getItemHeight(me, me.selectedItem);
	vector org = boxToGlobal(eY * (thisPos - me.scrollPos), me.origin, me.size);
	vector sz = boxToGlobalSize(eY * thisHeight + eX * (1 - me.controlWidth), me.size);
	DialogOpenButton_Click_withCoords(me, main.serverInfoDialog, org, sz);
}
void XonoticServerList_doubleClickListBoxItem(entity me, int i, vector where)
{
	ServerList_Connect_Click(NULL, me);
}
int autocvar_hud_panel_scoreboard_ping_low;
int autocvar_hud_panel_scoreboard_ping_medium;
int autocvar_hud_panel_scoreboard_ping_high;
void XonoticServerList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	vector oldscale = draw_scale;
	vector oldshift = draw_shift;
#define SET_YRANGE(start,end) \
	draw_scale = boxToGlobalSize(eX + eY * ((end) - (start)), oldscale); \
	draw_shift = boxToGlobal(eY * (start), oldshift, oldscale);

	int c;
	for (c = 0; c < category_draw_count; ++c) {
		// Matches exactly the headings with increased height.
		if (i == category_item[c])
			break;
	}

	if (c < category_draw_count)
	{
		entity catent = RetrieveCategoryEnt(category_name[c]);
		if(catent)
		{
			SET_YRANGE(
				(me.categoriesHeight - me.realFontSize.y) / (me.categoriesHeight + me.serversHeight),
				me.categoriesHeight / (me.categoriesHeight + me.serversHeight)
			);
			draw_Text(
				eY * me.realUpperMargin
				+
#if 0
				eX * (me.columnNameOrigin + (me.columnNameSize - draw_TextWidth(catent.cat_string, 0, me.realFontSize)) * 0.5),
				catent.cat_string,
#else
				eX * (me.columnNameOrigin),
				strcat(catent.cat_string, ":"),
#endif
				me.realFontSize,
				SKINCOLOR_SERVERLIST_CATEGORY,
				SKINALPHA_SERVERLIST_CATEGORY,
				0
			);
			SET_YRANGE(me.categoriesHeight / (me.categoriesHeight + me.serversHeight), 1);
		}
	}

	// Now categories are done. Set the Y range in stone.
	oldscale = draw_scale;
	oldshift = draw_shift;

	if(isSelected && !me.lockedSelectedItem)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	string s = gethostcachestring(SLIST_FIELD_QCSTATUS, i);
	int m = tokenizebyseparator(s, ":");
	string typestr = "", versionstr = "";
	if(m >= 2)
	{
		typestr = argv(0);
		versionstr = argv(1);
	}
	bool pure = false, pure_available = false;
	int qcfreeslots = -1, sflags = -1;
	string modname = "";
	for(int j = 2; j < m; ++j)
	{
		if(argv(j) == "")
			break;
		string key = substring(argv(j), 0, 1);
		string value = substring(argv(j), 1, -1);
		if(key == "P")
		{
			pure = (stof(value) == 0);
			pure_available = true;
		}
		else if(key == "S")
			qcfreeslots = stof(value); // from nJoinAllowed()
		else if(key == "F")
			sflags = stoi(value);
		else if(key == "M")
			modname = value;
	}

#ifdef COMPAT_NO_MOD_IS_XONOTIC
	if(modname == "")
		modname = "Xonotic";
#endif

	string original_modname = modname;
	modname = strtolower(modname);

	/*
	SLIST_FIELD_MOD = gethostcacheindexforkey("mod");
	s = gethostcachestring(SLIST_FIELD_MOD, i);
	if(s != "data")
		if(modname == "xonotic")
			modname = s;
	*/

	// list the mods here on which the pure server check actually works
	if(modname != "xonotic")
	if(modname != "instagib" || modname != "minstagib")
	if(modname != "cts")
	if(modname != "nix")
	if(modname != "newtoys")
		pure_available = false;

	float theAlpha;
	if(gethostcachenumber(SLIST_FIELD_FREESLOTS, i) <= 0) // can't connect
		theAlpha = SKINALPHA_SERVERLIST_FULL;
	else if(qcfreeslots == 0) // can connect but may not be able to play yet (duel, g_maxplayers, etc)
		theAlpha = SKINALPHA_SERVERLIST_EMPTY;
	else if (!gethostcachenumber(SLIST_FIELD_NUMHUMANS, i))
		theAlpha = SKINALPHA_SERVERLIST_EMPTY;
	else
		theAlpha = 1;

	float ping = gethostcachenumber(SLIST_FIELD_PING, i);
	const int PING_LOW = autocvar_hud_panel_scoreboard_ping_low;
	const int PING_MED = autocvar_hud_panel_scoreboard_ping_medium;
	const int PING_HIGH = autocvar_hud_panel_scoreboard_ping_high;
	vector theColor;
	// this colour selection code should match csqc Scoreboard_GetField()
	if (ping < PING_LOW)
		theColor = SKINCOLOR_SERVERLIST_LOWPING;
	else if(ping < PING_MED)
		theColor = SKINCOLOR_SERVERLIST_LOWPING + (SKINCOLOR_SERVERLIST_MEDPING - SKINCOLOR_SERVERLIST_LOWPING) * ((ping - PING_LOW) / (PING_MED - PING_LOW));
	else if(ping < PING_HIGH)
		theColor = SKINCOLOR_SERVERLIST_MEDPING + (SKINCOLOR_SERVERLIST_HIGHPING - SKINCOLOR_SERVERLIST_MEDPING) * ((ping - PING_MED) / (PING_HIGH - PING_MED));
	else
	{
		theColor = eX;
		theAlpha *= 1 + (SKINALPHA_SERVERLIST_HIGHPING - 1) * ((ping - PING_HIGH) / (PING_HIGH * 2 - PING_HIGH));
	}

	if(gethostcachenumber(SLIST_FIELD_ISFAVORITE, i))
	{
		theColor = theColor * (1 - SKINALPHA_SERVERLIST_FAVORITE) + SKINCOLOR_SERVERLIST_FAVORITE * SKINALPHA_SERVERLIST_FAVORITE;
		if (gethostcachenumber(SLIST_FIELD_FREESLOTS, i) > 0) // can connect
			theAlpha = theAlpha * (1 - SKINALPHA_SERVERLIST_FAVORITE) + SKINALPHA_SERVERLIST_FAVORITE;
	}

	s = gethostcachestring(SLIST_FIELD_CNAME, i);

	bool isv4 = false, isv6 = false;
	if(substring(s, 0, 1) == "[")
	{
		isv6 = true;
		++me.seenIPv6;
	}
	else if(IS_DIGIT(substring(s, 0, 1)))
	{
		isv4 = true;
		++me.seenIPv4;
	}

	int crypto = stof(substring(crypto_getencryptlevel(s), 0, 1));
	if((crypto <= 0 && cvar("crypto_aeslevel") >= 3) || (crypto >= 3 && cvar("crypto_aeslevel") <= 0))
	{
		theColor = SKINCOLOR_SERVERLIST_IMPOSSIBLE;
		theAlpha = SKINALPHA_SERVERLIST_IMPOSSIBLE;
	}

	if(crypto == 1)
	{
		if(cvar("crypto_aeslevel") >= 2)
			crypto |= 4;
	}
	if(crypto == 2)
	{
		if(cvar("crypto_aeslevel") >= 1)
			crypto |= 4;
	}
	if(crypto == 3)
		crypto = 5;
	else if(crypto >= 3)
		crypto -= 2;
	// possible status:
	// 0: crypto off
	// 1: AES possible
	// 2: AES recommended but not available
	// 3: AES possible and will be used
	// 4: AES recommended and will be used
	// 5: AES required

	// --------------
	//  RENDER ICONS
	// --------------
	vector iconSize = '0 0 0';
	iconSize_y = me.realFontSize.y * me.iconsSizeFactor / me.serversHeight;
	iconSize_x = me.realFontSize.x * me.iconsSizeFactor;

	vector iconPos = '0 0 0';
	if(me.seenIPv4 && me.seenIPv6)
		iconPos_x = (me.columnIconsSize - 4 * iconSize.x) * 0.5;
	else
		iconPos_x = (me.columnIconsSize - 3 * iconSize.x) * 0.5;
	iconPos_y = (1 - iconSize.y) * 0.5;

	// IP
	if(me.seenIPv4 && me.seenIPv6)
	{
		if(isv6)
			draw_Picture(iconPos, "icon_ipv6", iconSize, '1 1 1', 1);
		else if(isv4)
			draw_Picture(iconPos, "icon_ipv4", iconSize, '1 1 1', 1);

		iconPos.x += iconSize.x;
	}

	// AES
	if(crypto > 0)
		draw_Picture(iconPos, strcat("icon_aeslevel", ftos(crypto)), iconSize, '1 1 1', 1);

	iconPos.x += iconSize.x;

	// Mod
	if(modname == "xonotic")
	{
		// Here, pure_available should always be set. If not, consider
		// it an impurity.
		if(pure_available && pure)
			draw_Picture(iconPos, "icon_pure1", iconSize, '1 1 1', 1);
	}
	else
	{
		string icon = strcat("icon_mod_", modname);
		if(draw_PreloadPicture(icon) == "")
			icon = "icon_mod_";

		// In mods, pure_available not being present indicates
		// non-support of the feature. Just show the mod icon as is
		// then.
		if(pure_available && !pure)
			draw_Picture(iconPos, icon, iconSize, '1 1 1', SKINALPHA_SERVERLIST_ICON_NONPURE);
		else
			draw_Picture(iconPos, icon, iconSize, '1 1 1', 1);
	}

	iconPos.x += iconSize.x;

	// Stats
	if(sflags >= 0 && (sflags & SERVERFLAG_PLAYERSTATS))
	{
		if (sflags & SERVERFLAG_PLAYERSTATS_CUSTOM)
			draw_Picture(iconPos, "icon_mod_", iconSize, '1 1 1', 1); // TODO: custom stats server icon
		else
			draw_Picture(iconPos, "icon_stats1", iconSize, '1 1 1', 1);
	}

	if(isFocused && me.mouseOverIcons && !me.tooltip)
	{
		string t = "";
		if(me.seenIPv4 && me.seenIPv6)
			t = strcat(t, (isv6) ? "IPv6, " : "IPv4, ");
		t = strcat(t, _("encryption:"), " ", (crypto ? sprintf(_("AES level %d"), crypto) : ZCTX(_("ENC^none"))), ", ");
		t = strcat(t, sprintf(_("mod: %s"), ((modname == "xonotic") ? ZCTX(_("MOD^Default")) : original_modname)));
		if(pure_available)
			t = strcat(t, sprintf(" (%s)", (pure) ? _("official settings") : _("modified settings")));
		t = strcat(t, ", ");
		t = strcat(t, ((sflags >= 0 && (sflags & SERVERFLAG_PLAYERSTATS)) ? ((sflags & SERVERFLAG_PLAYERSTATS_CUSTOM) ? _("custom stats server") : _("stats enabled")) : _("stats disabled")));
		setZonedTooltip(me, t, string_null);
	}
	// --------------
	//  RENDER TEXT
	// --------------

	// Center it in the row.
	SET_YRANGE(
		0.5 - 0.5 / me.serversHeight,
		0.5 + 0.5 / me.serversHeight
	);

	// ping
	s = ftos(ping);
	draw_Text(me.realUpperMargin * eY + (me.columnPingOrigin + me.columnPingSize - draw_TextWidth(s, 0, me.realFontSize)) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	// server name
	s = draw_TextShortenToWidth(gethostcachestring(SLIST_FIELD_NAME, i), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + me.columnNameOrigin * eX, s, me.realFontSize, theColor, theAlpha, 0);

	// server map
	s = draw_TextShortenToWidth(gethostcachestring(SLIST_FIELD_MAP, i), me.columnMapSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnMapOrigin + (me.columnMapSize - draw_TextWidth(s, 0, me.realFontSize)) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	// server gametype
	s = draw_TextShortenToWidth(typestr, me.columnTypeSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin * eY + (me.columnTypeOrigin + (me.columnTypeSize - draw_TextWidth(s, 0, me.realFontSize)) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	// server playercount
	s = strcat(ftos(gethostcachenumber(SLIST_FIELD_NUMHUMANS, i)), "/", ftos(gethostcachenumber(SLIST_FIELD_MAXPLAYERS, i)));
	draw_Text(me.realUpperMargin * eY + (me.columnPlayersOrigin + (me.columnPlayersSize - draw_TextWidth(s, 0, me.realFontSize)) * 0.5) * eX, s, me.realFontSize, theColor, theAlpha, 0);
}

void XonoticServerList_focusedItemChangeNotify(entity me)
{
	clearTooltip(me);
}

float XonoticServerList_mouseMove(entity me, vector pos)
{
	if(!SUPER(XonoticServerList).mouseMove(me, pos))
	{
		me.mouseOverIcons = false;
		clearTooltip(me);
		return 1;
	}

	float iconSize_x = me.realFontSize.x * me.iconsSizeFactor;
	float iconPos_x;
	if(me.seenIPv4 && me.seenIPv6)
		iconPos_x = (me.columnIconsSize - 4 * iconSize_x) * 0.5;
	else
		iconPos_x = (me.columnIconsSize - 3 * iconSize_x) * 0.5;
	me.mouseOverIcons = (pos.x >= me.columnIconsOrigin + iconPos_x && pos.x <= me.columnIconsOrigin + me.columnIconsSize - iconPos_x);
	if(!me.mouseOverIcons)
		clearTooltip(me);
	return 1;
}

bool XonoticServerList_keyDown(entity me, int scan, bool ascii, bool shift)
{
	if(scan == K_ENTER || scan == K_KP_ENTER)
	{
		ServerList_Connect_Click(NULL, me);
		return true;
	}
	else if(scan == K_MOUSE2 || scan == K_SPACE || ((shift & S_CTRL) && scan == K_MOUSE1))
	{
		if(me.nItems != 0)
		{
			float thisPos = me.getItemStart(me, me.selectedItem);
			float thisHeight = me.getItemHeight(me, me.selectedItem);
			vector org = boxToGlobal(eY * (thisPos - me.scrollPos), me.origin, me.size);
			vector sz = boxToGlobalSize(eY * thisHeight + eX * (1 - me.controlWidth), me.size);
			m_play_click_sound(MENU_SOUND_OPEN);
			main.serverInfoDialog.loadServerInfo(main.serverInfoDialog, me.selectedItem);
			DialogOpenButton_Click_withCoords(me, main.serverInfoDialog, org, sz);
			return true;
		}
		return false;
	}
	else if(scan == K_INS || scan == K_MOUSE3 || scan == K_KP_INS)
	{
		if(me.nItems != 0)
		{
			me.toggleFavorite(me, me.selectedServer);
			me.ipAddressBoxFocused = -1;
			return true;
		}
		return false;
	}
	else if(SUPER(XonoticServerList).keyDown(me, scan, ascii, shift))
		return true;
	else if(!me.controlledTextbox)
		return false;
	else
		return me.controlledTextbox.keyDown(me.controlledTextbox, scan, ascii, shift);
}

float XonoticServerList_getTotalHeight(entity me)
{
	float num_normal_rows = me.nItems;
	int num_headers = category_draw_count;
	return me.itemHeight * (me.serversHeight * num_normal_rows + me.categoriesHeight * num_headers);
}
int XonoticServerList_getItemAtPos(entity me, float pos)
{
	pos = pos / me.itemHeight;
	for (int i = category_draw_count - 1; i >= 0; --i) {
		int itemidx = category_item[i];
		float itempos = i * me.categoriesHeight + itemidx * me.serversHeight;
		if (pos >= itempos + me.categoriesHeight + me.serversHeight)
			return itemidx + 1 + floor((pos - (itempos + me.categoriesHeight + me.serversHeight)) / me.serversHeight);
		if (pos >= itempos)
			return itemidx;
	}
	// No category matches? Note that category 0 is... 0. Therefore no headings exist at all.
	return floor(pos / me.serversHeight);
}
float XonoticServerList_getItemStart(entity me, int item)
{
	for (int i = category_draw_count - 1; i >= 0; --i) {
		int itemidx = category_item[i];
		float itempos = i * me.categoriesHeight + itemidx * me.serversHeight;
		if (item >= itemidx + 1)
			return (itempos + me.categoriesHeight + (1 + item - (itemidx + 1)) * me.serversHeight) * me.itemHeight;
		if (item >= itemidx)
			return itempos * me.itemHeight;
	}
	// No category matches? Note that category 0 is... 0. Therefore no headings exist at all.
	return item * me.serversHeight * me.itemHeight;
}
float XonoticServerList_getItemHeight(entity me, int item)
{
	for (int i = 0; i < category_draw_count; ++i) {
		// Matches exactly the headings with increased height.
		if (item == category_item[i])
			return me.itemHeight * (me.categoriesHeight + me.serversHeight);
	}
	return me.itemHeight * me.serversHeight;
}
