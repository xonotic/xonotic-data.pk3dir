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
