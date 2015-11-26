#ifdef IMPLEMENTATION
REGISTER_MUTATOR(itemstime, true);

REGISTER_NET_TEMP(itemstime)

#ifdef SVQC
void IT_Write(entity e, int i, float f) {
    if (!IS_REAL_CLIENT(e)) return;
    msg_entity = e;
    WriteHeader(MSG_ONE, itemstime);
    WriteByte(MSG_ONE, i);
    WriteFloat(MSG_ONE, f);
}
#endif

#ifdef CSQC
float ItemsTime_time[Items_MAX];
float ItemsTime_availableTime[Items_MAX];
NET_HANDLE(itemstime, bool isNew)
{
    int i = ReadByte();
    float f = ReadFloat();
    return = true;
    ItemsTime_time[i] = f;
}
#endif

#ifdef CSQC
int autocvar_hud_panel_itemstime = 2;
float autocvar_hud_panel_itemstime_dynamicsize = 1;
float autocvar_hud_panel_itemstime_ratio = 2;
int autocvar_hud_panel_itemstime_iconalign;
bool autocvar_hud_panel_itemstime_progressbar = 0;
float autocvar_hud_panel_itemstime_progressbar_maxtime = 30;
string autocvar_hud_panel_itemstime_progressbar_name = "progressbar";
float autocvar_hud_panel_itemstime_progressbar_reduced;
bool autocvar_hud_panel_itemstime_hidespawned = 1;
bool autocvar_hud_panel_itemstime_hidelarge = false;
int autocvar_hud_panel_itemstime_text = 1;
#define hud_panel_itemstime_hidelarge autocvar_hud_panel_itemstime_hidelarge
#else
#define hud_panel_itemstime_hidelarge false
#endif

bool Item_ItemsTime_SpectatorOnly(GameItem it)
{
    return (false
    || it == ITEM_ArmorMega     || (it == ITEM_ArmorLarge && !hud_panel_itemstime_hidelarge)
    || it == ITEM_HealthMega    || (it == ITEM_HealthLarge && !hud_panel_itemstime_hidelarge)
    );
}

bool Item_ItemsTime_Allow(GameItem it, WepSet _weapons)
{
    return (false
    || it.instanceOfPowerup
    || Item_ItemsTime_SpectatorOnly(it)
    || (_weapons & WEPSET_SUPERWEAPONS)
    );
}

#ifdef SVQC

float it_times[Items_MAX];

void Item_ItemsTime_Init()
{
    FOREACH(Items, true, LAMBDA(
        it_times[it.m_id] = -1;
    ));
}

STATIC_INIT(ItemsTime_Init) {
    // items time
    Item_ItemsTime_Init();
}

void Item_ItemsTime_ResetTimes()
{
    FOREACH(Items, true, LAMBDA(
        it_times[it.m_id] = (it_times[it.m_id] == -1) ? -1 : 0;
    ));
}

void Item_ItemsTime_ResetTimesForPlayer(entity e)
{
    FOREACH(Items, true, LAMBDA(
        IT_Write(e, it.m_id, (it_times[it.m_id] == -1) ? -1 : 0);
    ));
}

void Item_ItemsTime_SetTimesForPlayer(entity e)
{
    FOREACH(Items, true, LAMBDA(
        IT_Write(e, it.m_id, it_times[it.m_id]);
    ));
}

void Item_ItemsTime_SetTime(entity e, float t)
{
    if (!autocvar_sv_itemstime)
        return;

    GameItem item = e.itemdef;
    if (item.instanceOfGameItem && !item.instanceOfWeaponPickup)
    {
        it_times[item.m_id] = t;
    }
}

void Item_ItemsTime_SetTimesForAllPlayers()
{
    entity e;
    FOR_EACH_REALCLIENT(e) if (warmup_stage || !IS_PLAYER(e))
        Item_ItemsTime_SetTimesForPlayer(e);
}

float Item_ItemsTime_UpdateTime(entity e, float t)
{
    bool isavailable = (t == 0);
    FOREACH_ENTITY(it.itemdef == e.itemdef || ((it.weapons & WEPSET_SUPERWEAPONS) && clienttype(it) == CLIENTTYPE_NOTACLIENT), LAMBDA(
        if (e == it) continue;
        if (it.scheduledrespawntime <= time)
            isavailable = true;
        else if (t == 0 || it.scheduledrespawntime < t)
            t = it.scheduledrespawntime;
    ));
    if (isavailable)
        t = -t; // let know the client there's another available item
    return t;
}

MUTATOR_HOOKFUNCTION(itemstime, reset_map_global)
{SELFPARAM();
    Item_ItemsTime_ResetTimes();
    // ALL the times need to be reset before .reset()ing each item
    // since Item_Reset schedules respawn of superweapons and powerups
    FOREACH_ENTITY(IS_NOT_A_CLIENT(it), LAMBDA(
        if (it.reset) Item_ItemsTime_SetTime(it, 0);
    ));
    Item_ItemsTime_SetTimesForAllPlayers();
}

MUTATOR_HOOKFUNCTION(itemstime, MakePlayerObserver)
{SELFPARAM();
    Item_ItemsTime_SetTimesForPlayer(self);
}

MUTATOR_HOOKFUNCTION(itemstime, PlayerSpawn)
{SELFPARAM();
    if (warmup_stage) return;
    Item_ItemsTime_ResetTimesForPlayer(self);
}

#endif

#ifdef CSQC

void DrawItemsTimeItem(vector myPos, vector mySize, float ar, entity item, float item_time, bool item_available, float item_availableTime)
{
    float t = 0;
    vector color = '0 0 0';
    float picalpha;

    if (autocvar_hud_panel_itemstime_hidespawned == 2)
        picalpha = 1;
    else if (item_available)
    {
        float BLINK_FACTOR = 0.15;
        float BLINK_BASE = 0.85;
        float BLINK_FREQ = 5;
        picalpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);
    }
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
            p_size = eX * ((ar - 1)/ar) * mySize_x + eY * mySize_y;
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
            drawstring_aspect(numpos, ftos(t), eX * ((ar - 1)/ar) * mySize_x + eY * mySize_y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
        else if(precache_pic("gfx/hud/default/checkmark")) // COMPAT: check if this image exists, as 0.8.1 clients lack it
            drawpic_aspect_skin(numpos, "checkmark", eX * (ar - 1) * mySize_y + eY * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL);
        else // legacy code, if the image is missing just center the icon
            picpos.x = myPos.x + mySize.x / 2 - mySize.y / 2;
    }
    if (item_availableTime)
        drawpic_aspect_skin_expanding(picpos, item.m_icon, '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL, item_availableTime);
    drawpic_aspect_skin(picpos, item.m_icon, '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL);
}

void HUD_ItemsTime()
{
    if (!autocvar__hud_configure)
    {
        if (!(
            (autocvar_hud_panel_itemstime == 1 && spectatee_status != 0)
        ||	(autocvar_hud_panel_itemstime == 2 && (spectatee_status != 0 || warmup_stage))
            )) { return; }
    }
    else
    {
        ItemsTime_time[ITEM_ArmorMega.m_id] = time + 0;
        ItemsTime_time[ITEM_HealthMega.m_id] = time + 8;
        ItemsTime_time[ITEM_Strength.m_id] = time + 0;
        ItemsTime_time[ITEM_Shield.m_id] = time + 4;
    }

    int count = 0;
    if (autocvar_hud_panel_itemstime_hidespawned == 1)
        FOREACH(Items, Item_ItemsTime_Allow(it, '0 0 0'), LAMBDA(
            count += (ItemsTime_time[it.m_id] > time || -ItemsTime_time[it.m_id] > time);
        ));
    else if (autocvar_hud_panel_itemstime_hidespawned == 2)
        FOREACH(Items, Item_ItemsTime_Allow(it, '0 0 0'), LAMBDA(
            count += (ItemsTime_time[it.m_id] > time);
        ));
    else
        FOREACH(Items, Item_ItemsTime_Allow(it, '0 0 0'), LAMBDA(
            count += (ItemsTime_time[it.m_id] != -1);
        ));
    if (count == 0)
        return;

    HUD_Panel_UpdateCvars();

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

    vector itemstime_size = eX * mySize.x*(1/columns) + eY * mySize.y*(1/rows);

    vector offset = '0 0 0';
    float newSize;
    if (autocvar_hud_panel_itemstime_dynamicsize)
    {
        if (autocvar__hud_configure)
        if (menu_enabled != 2)
            HUD_Panel_DrawBg(1); // also draw the bg of the entire panel

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

    HUD_Panel_DrawBg(1);

    float row = 0, column = 0;
    bool item_available;
    FOREACH(Items, Item_ItemsTime_Allow(it, '0 0 0') && ItemsTime_time[it.m_id] != -1, LAMBDA(
        float item_time = ItemsTime_time[it.m_id];
        if (item_time < -1)
        {
            item_available = true;
            item_time = -item_time;
        }
        else
            item_available = (item_time <= time);

        if (ItemsTime_time[it.m_id] >= 0)
        {
            if (time <= ItemsTime_time[it.m_id])
                ItemsTime_availableTime[it.m_id] = 0;
            else if (ItemsTime_availableTime[it.m_id] == 0)
                ItemsTime_availableTime[it.m_id] = time;
        }
        else if (ItemsTime_availableTime[it.m_id] == 0)
            ItemsTime_availableTime[it.m_id] = time;

        float f = (time - ItemsTime_availableTime[it.m_id]) * 2;
        f = (f > 1) ? 0 : bound(0, f, 1);

        if (autocvar_hud_panel_itemstime_hidespawned == 1)
            if (!(ItemsTime_time[it.m_id] > time || -ItemsTime_time[it.m_id] > time))
                continue;

        if (autocvar_hud_panel_itemstime_hidespawned == 2)
            if (!(ItemsTime_time[it.m_id] > time))
                continue;

        DrawItemsTimeItem(pos + eX * column * (itemstime_size.x + offset.x) + eY * row * (itemstime_size.y + offset.y), itemstime_size, ar, it, item_time, item_available, f);
        ++row;
        if (row >= rows)
        {
            row = 0;
            column = column + 1;
        }
    ));
}

#endif
#endif
