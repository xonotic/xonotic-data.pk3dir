REGISTER_MUTATOR(itemstime, true);

#ifdef SVQC
void IT_Write(entity e, int i, float f) {
    if (!IS_REAL_CLIENT(e)) return;
    msg_entity = e;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteMutator(MSG_ONE, itemstime);
    WriteByte(MSG_ONE, i);
    WriteFloat(MSG_ONE, f);
}
#endif

#ifdef CSQC
const float ITEMSTIME_MAXITEMS = 10;
float ItemsTime_time[ITEMSTIME_MAXITEMS];
float ItemsTime_availableTime[ITEMSTIME_MAXITEMS];
MUTATOR_HOOKFUNCTION(itemstime, CSQC_Parse_TempEntity) {
    if (MUTATOR_RETURNVALUE) return false;
    if (!ReadMutatorEquals(mutator_argv_int_0, itemstime)) return false;
    int i = ReadByte();
    float f = ReadFloat();
    ItemsTime_time[i] = f;
    return true;
}
#endif

#ifdef SVQC
float it_armor_large_time;
float it_health_mega_time;
float it_invisible_time;
float it_speed_time;
float it_extralife_time;
float it_strength_time;
float it_shield_time;
float it_fuelregen_time;
float it_jetpack_time;
float it_superweapons_time;

void Item_ItemsTime_Init()
{
    it_armor_large_time = -1;
    it_health_mega_time = -1;
    it_invisible_time = -1;
    it_speed_time = -1;
    it_extralife_time = -1;
    it_strength_time = -1;
    it_shield_time = -1;
    it_fuelregen_time = -1;
    it_jetpack_time = -1;
    it_superweapons_time = -1;
}

STATIC_INIT(ItemsTime_Init) {
    // items time
    Item_ItemsTime_Init();
}

void Item_ItemsTime_ResetTimes()
{
    it_armor_large_time  = (it_armor_large_time  == -1) ? -1 : 0;
    it_health_mega_time  = (it_health_mega_time  == -1) ? -1 : 0;
    it_invisible_time    = (it_invisible_time    == -1) ? -1 : 0;
    it_speed_time        = (it_speed_time        == -1) ? -1 : 0;
    it_extralife_time    = (it_extralife_time    == -1) ? -1 : 0;
    it_strength_time     = (it_strength_time     == -1) ? -1 : 0;
    it_shield_time       = (it_shield_time       == -1) ? -1 : 0;
    it_fuelregen_time    = (it_fuelregen_time    == -1) ? -1 : 0;
    it_jetpack_time      = (it_jetpack_time      == -1) ? -1 : 0;
    it_superweapons_time = (it_superweapons_time == -1) ? -1 : 0;
}

void Item_ItemsTime_ResetTimesForPlayer(entity e)
{
    IT_Write(e, item_armor_large_time , (it_armor_large_time  == -1) ? -1 : 0);
    IT_Write(e, item_health_mega_time , (it_health_mega_time  == -1) ? -1 : 0);
    IT_Write(e, item_invisible_time   , (it_invisible_time    == -1) ? -1 : 0);
    IT_Write(e, item_speed_time       , (it_speed_time        == -1) ? -1 : 0);
    IT_Write(e, item_extralife_time   , (it_extralife_time    == -1) ? -1 : 0);
    IT_Write(e, item_strength_time    , (it_strength_time     == -1) ? -1 : 0);
    IT_Write(e, item_shield_time      , (it_shield_time       == -1) ? -1 : 0);
    IT_Write(e, item_fuelregen_time   , (it_fuelregen_time    == -1) ? -1 : 0);
    IT_Write(e, item_jetpack_time     , (it_jetpack_time      == -1) ? -1 : 0);
    IT_Write(e, item_superweapons_time, (it_superweapons_time == -1) ? -1 : 0);
}

void Item_ItemsTime_SetTimesForPlayer(entity e)
{
    IT_Write(e, item_armor_large_time , it_armor_large_time );
    IT_Write(e, item_health_mega_time , it_health_mega_time );
    IT_Write(e, item_invisible_time   , it_invisible_time   );
    IT_Write(e, item_speed_time       , it_speed_time       );
    IT_Write(e, item_extralife_time   , it_extralife_time   );
    IT_Write(e, item_strength_time    , it_strength_time    );
    IT_Write(e, item_shield_time      , it_shield_time      );
    IT_Write(e, item_fuelregen_time   , it_fuelregen_time   );
    IT_Write(e, item_jetpack_time     , it_jetpack_time     );
    IT_Write(e, item_superweapons_time, it_superweapons_time);
}

void Item_ItemsTime_SetTime(entity e, float t)
{
    if (!autocvar_sv_itemstime)
        return;

    if (g_instagib)
    {
        switch (e.items)
        {
            case IT_STRENGTH://"item-invis"
                it_invisible_time = t;
                break;
            case IT_NAILS://"item-extralife"
                it_extralife_time = t;
                break;
            case IT_INVINCIBLE://"item-speed"
                it_speed_time = t;
                break;
        }
    }
    else
    {
        switch (e.items)
        {
            case ITEM_HealthMega.m_itemid:
                // if (e.itemdef == ITEM_HealthMega) // e.items == IT_HEALTH unequivocally identifies it
                    it_health_mega_time = t;
                break;
            case ITEM_ArmorMega.m_itemid:
                if (e.itemdef == ITEM_ArmorMega) // e.items == IT_ARMOR doesn't unequivocally identifies it
                    it_armor_large_time = t;
                break;
            case IT_STRENGTH://"item-strength"
                it_strength_time = t;
                break;
            case IT_INVINCIBLE://"item-shield"
                it_shield_time = t;
                break;
            default:
                if (e.weapons & WEPSET_SUPERWEAPONS)
                    it_superweapons_time = t;
        }
    }
    switch (e.items)
    {
        case IT_FUEL_REGEN://"item-fuelregen"
            it_fuelregen_time = t;
            break;
        case IT_JETPACK://"item-jetpack"
            it_jetpack_time = t;
            break;
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
    if (e.weapons & WEPSET_SUPERWEAPONS)
    {
        for (entity head = world; (head = nextent(head)); )
        {
            if (clienttype(head) != CLIENTTYPE_NOTACLIENT || !(head.weapons & WEPSET_SUPERWEAPONS) || head.classname == "weapon_info")
                continue;
            if (e == head)
                continue;

            if (head.scheduledrespawntime <= time)
                isavailable = true;
            else if (t == 0 || head.scheduledrespawntime < t)
                t = head.scheduledrespawntime;
        }
    }
    else
    {
        for (entity head = world; (head = nextent(head)); )
        {
            if (head.itemdef != e.itemdef)
                continue;
            if (e == head)
                continue;

            if (head.scheduledrespawntime <= time)
                isavailable = true;
            else if (t == 0 || head.scheduledrespawntime < t)
                t = head.scheduledrespawntime;
        }
    }
    if (isavailable)
        t = -t; // let know the client there's another available item
    return t;
}

MUTATOR_HOOKFUNCTION(itemstime, reset_map_global) {
    Item_ItemsTime_ResetTimes();
}

MUTATOR_HOOKFUNCTION(itemstime, MakePlayerObserver) {
    Item_ItemsTime_SetTimesForPlayer(self);
}

MUTATOR_HOOKFUNCTION(itemstime, PlayerSpawn) {
    if (warmup_stage) return;
    Item_ItemsTime_ResetTimesForPlayer(self);
}

#endif

#ifdef CSQC

string GetItemsTimePicture(float i)
{
    switch(i)
    {
        case 0: return "item_large_armor";
        case 1: return "item_mega_health";
        case 2: return "strength";
        case 3: return "shield";
        case 4: return "item_mega_health";
        case 5: return "strength";
        case 6: return "shield";
        case 7: return "fuelregen";
        case 8: return "jetpack";
        case 9: return "superweapons";
        default: return "";
    }
}

void DrawItemsTimeItem(vector myPos, vector mySize, float ar, float itemcode, float item_time, bool item_available, float item_availableTime)
{
    float t = 0;
    vector color = '0 0 0';
    float picalpha;

    if(autocvar_hud_panel_itemstime_hidespawned == 2)
        picalpha = 1;
    else if(item_available)
    {
        float BLINK_FACTOR = 0.15;
        float BLINK_BASE = 0.85;
        float BLINK_FREQ = 5;
        picalpha = BLINK_BASE + BLINK_FACTOR * cos(time * BLINK_FREQ);
    }
    else
        picalpha = 0.5;
    t = floor(item_time - time + 0.999);
    if(t < 5)
        color = '0.7 0 0';
    else if(t < 10)
        color = '0.7 0.7 0';
    else
        color = '1 1 1';

    vector picpos, numpos;
    if(autocvar_hud_panel_itemstime_iconalign)
    {
        numpos = myPos;
        picpos = myPos + eX * (ar - 1) * mySize_y;
    }
    else
    {
        numpos = myPos + eX * mySize_y;
        picpos = myPos;
    }

    if(t > 0 && autocvar_hud_panel_itemstime_progressbar)
    {
        vector p_pos, p_size;
        if(autocvar_hud_panel_itemstime_progressbar_reduced)
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

    if(t > 0 && autocvar_hud_panel_itemstime_text)
        drawstring_aspect(numpos, ftos(t), eX * ((ar - 1)/ar) * mySize_x + eY * mySize_y, color, panel_fg_alpha, DRAWFLAG_NORMAL);
    else
        picpos.x = myPos.x + mySize.x / 2 - mySize.y / 2;
    if(item_availableTime)
        drawpic_aspect_skin_expanding(picpos, GetItemsTimePicture(itemcode), '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL, item_availableTime);
    drawpic_aspect_skin(picpos, GetItemsTimePicture(itemcode), '1 1 0' * mySize_y, '1 1 1', panel_fg_alpha * picalpha, DRAWFLAG_NORMAL);
}

void HUD_ItemsTime()
{
    if(!autocvar__hud_configure)
    {
        if(!(
            (autocvar_hud_panel_itemstime == 1 && spectatee_status != 0)
        ||	(autocvar_hud_panel_itemstime == 2 && (spectatee_status != 0 || warmup_stage))
            )) { return; }
    }
    else
    {
        // do not show here mutator-dependent items
        ItemsTime_time[0] = time + 0;
        ItemsTime_time[1] = time + 8;
        ItemsTime_time[2] = -1; // mutator-dependent
        ItemsTime_time[3] = -1; // mutator-dependent
        ItemsTime_time[4] = -1; // mutator-dependent
        ItemsTime_time[5] = time + 0;
        ItemsTime_time[6] = time + 4;
        ItemsTime_time[7] = time + 49;
        ItemsTime_time[8] = -1;
        ItemsTime_time[9] = time + 28;
    }

    float i;
    float count = 0;
    if(autocvar_hud_panel_itemstime_hidespawned == 1)
        for (i = 0; i < ITEMSTIME_MAXITEMS; ++i)
            count += (ItemsTime_time[i] > time || -ItemsTime_time[i] > time);
    else if(autocvar_hud_panel_itemstime_hidespawned == 2)
        for (i = 0; i < ITEMSTIME_MAXITEMS; ++i)
            count += (ItemsTime_time[i] > time);
    else
        for (i = 0; i < ITEMSTIME_MAXITEMS; ++i)
            count += (ItemsTime_time[i] != -1);
    if (count == 0)
        return;

    HUD_Panel_UpdateCvars();

    vector pos, mySize;
    pos = panel_pos;
    mySize = panel_size;

    if(panel_bg_padding)
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
    if(autocvar_hud_panel_itemstime_dynamicsize)
    {
        if(autocvar__hud_configure)
        if(menu_enabled != 2)
            HUD_Panel_DrawBg(1); // also draw the bg of the entire panel

        // reduce panel to avoid spacing items
        if(itemstime_size.x / itemstime_size.y < ar)
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
        if(itemstime_size.x/itemstime_size.y > ar)
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
    for (i = 0; i < ITEMSTIME_MAXITEMS; ++i) {
        if (ItemsTime_time[i] == -1)
            continue;

        float item_time = ItemsTime_time[i];
        if(item_time < -1)
        {
            item_available = true;
            item_time = -item_time;
        }
        else
            item_available = (item_time <= time);

        if(ItemsTime_time[i] >= 0)
        {
            if(time <= ItemsTime_time[i])
                ItemsTime_availableTime[i] = 0;
            else if(ItemsTime_availableTime[i] == 0)
                ItemsTime_availableTime[i] = time;
        }
        else if(ItemsTime_availableTime[i] == 0)
            ItemsTime_availableTime[i] = time;

        float f = (time - ItemsTime_availableTime[i]) * 2;
        f = (f > 1) ? 0 : bound(0, f, 1);

        if(autocvar_hud_panel_itemstime_hidespawned == 1)
            if(!(ItemsTime_time[i] > time || -ItemsTime_time[i] > time))
                continue;

        if(autocvar_hud_panel_itemstime_hidespawned == 2)
            if(!(ItemsTime_time[i] > time))
                continue;

        DrawItemsTimeItem(pos + eX * column * (itemstime_size.x + offset.x) + eY * row * (itemstime_size.y + offset.y), itemstime_size, ar, i, item_time, item_available, f);
        ++row;
        if(row >= rows)
        {
            row = 0;
            column = column + 1;
        }
    }
}

#endif
