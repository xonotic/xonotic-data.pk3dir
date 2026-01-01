#include "itemstime.qh"

#ifdef GAMEQC
REGISTER_MUTATOR(itemstime, true);
REGISTER_NET_TEMP(itemstime)
#endif

#ifdef SVQC
void IT_Write(entity e, int i, float f) {
	if (!IS_REAL_CLIENT(e))
		return;
	msg_entity = e;
	WriteHeader(MSG_ONE, itemstime);
	WriteByte(MSG_ONE, i);
	WriteFloat(MSG_ONE, f);
}
#endif

#ifdef CSQC
// reserve one more spot for superweapons time
float ItemsTime_time[REGISTRY_MAX(Items) + 1];
float ItemsTime_availableTime[REGISTRY_MAX(Items) + 1];
NET_HANDLE(itemstime, bool isNew)
{
	int i = ReadByte();
	float f = ReadFloat();
	return = true;
	ItemsTime_time[i] = f;
}
#endif

#ifdef CSQC

STATIC_INIT(ItemsTime_Init) {
	FOREACH(Items, true, {
		ItemsTime_time[it.m_id] = -1;
	});
	ItemsTime_time[REGISTRY_MAX(Items)] = -1;
}

int autocvar_hud_panel_itemstime = 2;
float autocvar_hud_panel_itemstime_dynamicsize = 1;
float autocvar_hud_panel_itemstime_ratio = 2;
//bool autocvar_hud_panel_itemstime_dynamichud    = true;
int autocvar_hud_panel_itemstime_iconalign;
bool autocvar_hud_panel_itemstime_progressbar = 0;
float autocvar_hud_panel_itemstime_progressbar_maxtime = 30;
string autocvar_hud_panel_itemstime_progressbar_name = "progressbar";
float autocvar_hud_panel_itemstime_progressbar_reduced;
bool autocvar_hud_panel_itemstime_hidespawned = 1;
bool autocvar_hud_panel_itemstime_hidebig = false;
int autocvar_hud_panel_itemstime_text = 1;
#define hud_panel_itemstime_hidebig autocvar_hud_panel_itemstime_hidebig
#else
#define hud_panel_itemstime_hidebig false
#endif

bool Item_ItemsTime_SpectatorOnly(GameItem it)
{
	return (false
	|| it == ITEM_ArmorMega		|| (it == ITEM_ArmorBig && !hud_panel_itemstime_hidebig)
	|| it == ITEM_HealthMega	|| (it == ITEM_HealthBig && !hud_panel_itemstime_hidebig)
	);
}

bool Item_ItemsTime_Allow(GameItem it)
{
	return (it.instanceOfPowerup || Item_ItemsTime_SpectatorOnly(it));
}

#ifdef SVQC

// reserve one more spot for superweapons time
float it_times[REGISTRY_MAX(Items) + 1];

STATIC_INIT(ItemsTime_Init) {
	FOREACH(Items, Item_ItemsTime_Allow(it), {
		it_times[it.m_id] = -1;
	});
	it_times[REGISTRY_MAX(Items)] = -1;
}

void Item_ItemsTime_ResetTimes()
{
	FOREACH(Items, Item_ItemsTime_Allow(it), {
		it_times[it.m_id] = (it_times[it.m_id] == -1) ? -1 : 0;
	});
	it_times[REGISTRY_MAX(Items)] = (it_times[REGISTRY_MAX(Items)] == -1) ? -1 : 0;
}

void Item_ItemsTime_ResetTimesForPlayer(entity e)
{
	FOREACH(Items, Item_ItemsTime_Allow(it), {
		IT_Write(e, it.m_id, (it_times[it.m_id] == -1) ? -1 : 0);
	});
	IT_Write(e, REGISTRY_MAX(Items), (it_times[REGISTRY_MAX(Items)] == -1) ? -1 : 0);
}

void Item_ItemsTime_SetTimesForPlayer(entity e)
{
	FOREACH(Items, Item_ItemsTime_Allow(it), {
		IT_Write(e, it.m_id, it_times[it.m_id]);
	});
	IT_Write(e, REGISTRY_MAX(Items), it_times[REGISTRY_MAX(Items)]);
}

void Item_ItemsTime_SetTime(entity e, float t)
{
	if (!autocvar_sv_itemstime)
		return;

	GameItem item = e.itemdef;
	if (item.instanceOfGameItem)
	{
		if (!item.instanceOfWeaponPickup)
			it_times[item.m_id] = t;
		else if (STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS)
			it_times[REGISTRY_MAX(Items)] = t;
	}
}

void Item_ItemsTime_SetTimesForAllPlayers()
{
	FOREACH_CLIENT(IS_REAL_CLIENT(it) && (warmup_stage || !IS_PLAYER(it) || autocvar_sv_itemstime == 2),
		Item_ItemsTime_SetTimesForPlayer(it);
	);
}

float Item_ItemsTime_UpdateTime(entity e, float t)
{
	bool isavailable = (t == 0);
	IL_EACH(g_items, it != e,
	{
		if(!(it.itemdef == e.itemdef
			|| ((STAT(WEAPONS, e) & WEPSET_SUPERWEAPONS) && (STAT(WEAPONS, it) & WEPSET_SUPERWEAPONS))))
		{
			continue;
		}
		if (it.scheduledrespawntime <= time)
			isavailable = true;
		else if (t == 0 || it.scheduledrespawntime < t)
			t = it.scheduledrespawntime;
	});
	if (isavailable)
		t = -t; // let know the client there's another available item
	return t;
}

MUTATOR_HOOKFUNCTION(itemstime, reset_map_global)
{
	Item_ItemsTime_ResetTimes();
	// ALL the times need to be reset before .reset()ing each item
	// since Item_Reset schedules respawn of superweapons and powerups
	IL_EACH(g_items, it.reset,
	{
		Item_ItemsTime_SetTime(it, 0);
	});
	Item_ItemsTime_SetTimesForAllPlayers();
}

MUTATOR_HOOKFUNCTION(itemstime, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	Item_ItemsTime_SetTimesForPlayer(player);
}

MUTATOR_HOOKFUNCTION(itemstime, ClientConnect, CBC_ORDER_LAST)
{
	entity player = M_ARGV(0, entity);

	if(IS_PLAYER(player))
	{
		// client became player on connection skipping putObserverInServer step
		if (IS_REAL_CLIENT(player))
		if (warmup_stage || autocvar_sv_itemstime == 2)
			Item_ItemsTime_SetTimesForPlayer(player);
	}
}

MUTATOR_HOOKFUNCTION(itemstime, PlayerSpawn)
{
	if (warmup_stage || autocvar_sv_itemstime == 2) return;
	entity player = M_ARGV(0, entity);

	Item_ItemsTime_ResetTimesForPlayer(player);
}

#endif

#ifdef CSQC

// ItemsTime (#22)

void HUD_ItemsTime_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_itemstime_iconalign");
	HUD_Write_Cvar("hud_panel_itemstime_progressbar");
	HUD_Write_Cvar("hud_panel_itemstime_progressbar_name");
	HUD_Write_Cvar("hud_panel_itemstime_progressbar_reduced");
	HUD_Write_Cvar("hud_panel_itemstime_text");
	HUD_Write_Cvar("hud_panel_itemstime_ratio");
	HUD_Write_Cvar("hud_panel_itemstime_dynamicsize");
}

void DrawItemsTimeItem(vector myPos, vector mySize, float ar, string item_icon, float item_time, bool item_available, float item_availableTime)
{
	float t = 0;
	vector color = '0 0 0';
	float picalpha;

	if (autocvar_hud_panel_itemstime_hidespawned == 2)
		picalpha = 1;
	else if (item_available)
		picalpha = blink(0.85, 0.15, 5);
	else
		picalpha = 0.5;
	t = floor(item_time - time + 0.999);
	if (t < 5)
		color = '0.7 0 0';
	else if (t < 10)
		color = '0.7 0.7 0';
	else
		color = '1 1 1';

	vector picpos, numpos;
	if (autocvar_hud_panel_itemstime_iconalign)
	{
		numpos = myPos;
		picpos = myPos + eX * (ar - 1) * mySize_y;
	}
	else
	{
		numpos = myPos + eX * mySize_y;
		picpos = myPos;
	}

	if (t > 0 && autocvar_hud_panel_itemstime_progressbar)
	{
		vector p_pos, p_size;
		if (autocvar_hud_panel_itemstime_progressbar_reduced)
		{
			p_pos = numpos;
			p_size = vec2(((ar - 1)/ar) * mySize.x, mySize.y);
		}
		else
		{
			p_pos = myPos;
			p_size = mySize;
		}
		HUD_Panel_DrawProgressBar(p_pos, p_size, autocvar_hud_panel_itemstime_progressbar_name, t/autocvar_hud_panel_itemstime_progressbar_maxtime, 0, autocvar_hud_panel_itemstime_iconalign, color, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
	}

	if(autocvar_hud_panel_itemstime_text)
	{
		if(t > 0)
			drawstring_aspect(numpos, ftos(t), vec2(((ar - 1)/ar) * mySize.x, mySize.y), color, panel_fg_alpha, DRAWFLAG_NORMAL);
		else if(precache_pic("gfx/hud/default/checkmark")) // COMPAT: check if this image exists, as 0.8.1 clients lack it
			drawpic_aspect_skin(numpos, "checkmark", vec2((ar - 1) * mySize.y, mySize.y), '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL);
		else // legacy code, if the image is missing just center the icon
			picpos.x = myPos.x + mySize.x / 2 - mySize.y / 2;
	}
	if (item_availableTime)
		drawpic_aspect_skin_expanding(picpos, item_icon, '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL, item_availableTime);
	drawpic_aspect_skin(picpos, item_icon, '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL);
}

float Item_ItemsTime_GetTime(int item)
{
	if (autocvar__hud_configure)
	{
		switch (item)
		{
			case ITEM_ArmorMega.m_id: return time + 8;
			case ITEM_ArmorBig.m_id: return time + 0;
			case ITEM_HealthMega.m_id: return time + 0;
			case ITEM_Strength.m_id: return time + 4;
		}

		return -1; // don't show others
	}
	else
		return ItemsTime_time[item];
}

void HUD_ItemsTime()
{
	if (!autocvar__hud_configure)
	{
		if (!(
			(autocvar_hud_panel_itemstime == 1 && spectatee_status != 0)
		||	(autocvar_hud_panel_itemstime == 2 && (spectatee_status != 0 || warmup_stage || STAT(ITEMSTIME) == 2))
			)) { return; }
	}

	int count = 0;
	if (autocvar_hud_panel_itemstime_hidespawned == 1)
	{
		FOREACH(Items, Item_ItemsTime_Allow(it), {
			count += (Item_ItemsTime_GetTime(it.m_id) > time || -Item_ItemsTime_GetTime(it.m_id) > time);
		});
		count += (Item_ItemsTime_GetTime(REGISTRY_MAX(Items)) > time || -Item_ItemsTime_GetTime(REGISTRY_MAX(Items)) > time);
	}
	else if (autocvar_hud_panel_itemstime_hidespawned == 2)
	{
		FOREACH(Items, Item_ItemsTime_Allow(it), {
			count += (Item_ItemsTime_GetTime(it.m_id) > time);
		});
		count += (Item_ItemsTime_GetTime(REGISTRY_MAX(Items)) > time);
	}
	else
	{
		FOREACH(Items, Item_ItemsTime_Allow(it), {
			count += (Item_ItemsTime_GetTime(it.m_id) != -1);
		});
		count += (Item_ItemsTime_GetTime(REGISTRY_MAX(Items)) != -1);
	}
	if (count == 0)
		return;

	HUD_Panel_LoadCvars();

	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if (panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	float rows, columns;
	float ar = max(2, autocvar_hud_panel_itemstime_ratio) + 1;
	rows = HUD_GetRowCount(count, mySize, ar);
	columns = ceil(count/rows);

	vector itemstime_size = vec2(mySize.x / columns, mySize.y / rows);

	vector offset = '0 0 0';
	float newSize;
	if (autocvar_hud_panel_itemstime_dynamicsize)
	{
		if (autocvar__hud_configure)
		if (hud_configure_menu_open != 2)
			HUD_Panel_DrawBg(); // also draw the bg of the entire panel

		// reduce panel to avoid spacing items
		if (itemstime_size.x / itemstime_size.y < ar)
		{
			newSize = rows * itemstime_size.x / ar;
			pos.y += (mySize.y - newSize) / 2;
			mySize.y = newSize;
			itemstime_size.y = mySize.y / rows;
		}
		else
		{
			newSize = columns * itemstime_size.y * ar;
			pos.x += (mySize.x - newSize) / 2;
			mySize.x = newSize;
			itemstime_size.x = mySize.x / columns;
		}
		panel_pos = pos - '1 1 0' * panel_bg_padding;
		panel_size = mySize + '2 2 0' * panel_bg_padding;
	}
	else
	{
		if (itemstime_size.x/itemstime_size.y > ar)
		{
			newSize = ar * itemstime_size.y;
			offset.x = itemstime_size.x - newSize;
			pos.x += offset.x/2;
			itemstime_size.x = newSize;
		}
		else
		{
			newSize = 1/ar * itemstime_size.x;
			offset.y = itemstime_size.y - newSize;
			pos.y += offset.y/2;
			itemstime_size.y = newSize;
		}
	}

	HUD_Scale_Enable();
	HUD_Panel_DrawBg();

	float row = 0, column = 0;
	bool item_available;
	int id = 0;
	string icon = "";
	FOREACH(Items, Item_ItemsTime_Allow(it) && Item_ItemsTime_GetTime(it.m_id) != -1, {
		id = it.m_id;
		icon = it.m_icon;

LABEL(iteration)
		float item_time = Item_ItemsTime_GetTime(id);
		if (item_time < -1)
		{
			item_available = true;
			item_time = -item_time;
		}
		else
			item_available = (item_time <= time);

		if (Item_ItemsTime_GetTime(id) >= 0)
		{
			if (time <= Item_ItemsTime_GetTime(id))
				ItemsTime_availableTime[id] = 0;
			else if (ItemsTime_availableTime[id] == 0)
				ItemsTime_availableTime[id] = time;
		}
		else if (ItemsTime_availableTime[id] == 0)
			ItemsTime_availableTime[id] = time;

		float f = (time - ItemsTime_availableTime[id]) * 2;
		f = (f > 1) ? 0 : bound(0, f, 1);

		if (autocvar_hud_panel_itemstime_hidespawned == 1)
			if (!(Item_ItemsTime_GetTime(id) > time || -Item_ItemsTime_GetTime(id) > time))
				continue;

		if (autocvar_hud_panel_itemstime_hidespawned == 2)
			if (!(Item_ItemsTime_GetTime(id) > time))
				continue;

		DrawItemsTimeItem(pos + vec2(column * (itemstime_size.x + offset.x), row * (itemstime_size.y + offset.y)), itemstime_size, ar, icon, item_time, item_available, f);
		++row;
		if (row >= rows)
		{
			row = 0;
			column = column + 1;
		}
		if(id == REGISTRY_MAX(Items)) // can happen only in the last fake iteration
			break;
	});
	// add another fake iteration for superweapons time
	if(id < REGISTRY_MAX(Items) && Item_ItemsTime_GetTime(REGISTRY_MAX(Items)) != -1)
	{
		id = REGISTRY_MAX(Items);
		icon = "superweapons";
		goto iteration;
	}
}

#endif
