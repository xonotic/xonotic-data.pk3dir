#include <common/colors.qh>

#ifdef GAMEQC
#define NADE_PROJECTILE(i, projectile, trail) MACRO_BEGIN \
    this.m_projectile[i] = projectile; \
    this.m_trail[i] = trail; \
MACRO_END
#endif

CLASS(NormalNade, Nade)
    ATTRIB(NormalNade, m_color, vector, COLOR_NADE_NORMAL);
    ATTRIB(NormalNade, m_name, string, _("Grenade"));
    ATTRIB(NormalNade, m_icon, string, "nade_normal");
#ifdef MENUQC
    METHOD(NormalNade, describe, string(NormalNade this))
    {
        TC(NormalNade, this);
        return sprintf(_("The (normal) %s explodes after a short delay, dealing damage to nearby players\n\n"
            "Make sure you remember to throw it with ^3drop weapon^7, or else it will blow up in your hands!"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(NormalNade)
REGISTER_NADE(NORMAL, NEW(NormalNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE, EFFECT_Null);
    NADE_PROJECTILE(1, PROJECTILE_NADE_BURN, EFFECT_Null);
#endif
}

CLASS(NapalmNade, Nade)
    ATTRIB(NapalmNade, m_color, vector, COLOR_NADE_NAPALM);
    ATTRIB(NapalmNade, m_name, string, _("Napalm grenade"));
    ATTRIB(NapalmNade, m_icon, string, "nade_napalm");
#ifdef MENUQC
    METHOD(NapalmNade, describe, string(NapalmNade this))
    {
        TC(NapalmNade, this);
        return sprintf(_("The %s explodes after a short delay, spreading fiery napalm globs around in the fountain. "
            "The napalm fire balls burn for a while, and damage players who get too close"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(NapalmNade)
REGISTER_NADE(NAPALM, NEW(NapalmNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_NAPALM, EFFECT_TR_ROCKET);
    NADE_PROJECTILE(1, PROJECTILE_NADE_NAPALM_BURN, EFFECT_SPIDERBOT_ROCKET_TRAIL);
#endif
}

CLASS(IceNade, Nade)
    ATTRIB(IceNade, m_color, vector, COLOR_NADE_ICE);
    ATTRIB(IceNade, m_name, string, _("Ice grenade"));
    ATTRIB(IceNade, m_icon, string, "nade_ice");
#ifdef MENUQC
    METHOD(IceNade, describe, string(IceNade this))
    {
        TC(IceNade, this);
        return sprintf(_("The %s detonates after a short delay, freezing any enemies who walk within the explosion radius for a few seconds after the explosion. "
            "While frozen, enemies are progressively dealt damage"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(IceNade)
REGISTER_NADE(ICE, NEW(IceNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ICE, EFFECT_TR_NEXUIZPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ICE_BURN, EFFECT_RACER_ROCKET_TRAIL);
#endif
}

CLASS(TranslocateNade, Nade)
    ATTRIB(TranslocateNade, m_color, vector, COLOR_NADE_TRANSLOCATE);
    ATTRIB(TranslocateNade, m_name, string, _("Translocate grenade"));
    ATTRIB(TranslocateNade, m_icon, string, "nade_translocate");
#ifdef MENUQC
    METHOD(TranslocateNade, describe, string(TranslocateNade this))
    {
        TC(TranslocateNade, this);
        return sprintf(_("The %s detonates after a short delay, teleporting you to where it detonated"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(TranslocateNade)
REGISTER_NADE(TRANSLOCATE, NEW(TranslocateNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
    NADE_PROJECTILE(1, PROJECTILE_NADE_TRANSLOCATE, EFFECT_TR_CRYLINKPLASMA);
#endif
}

CLASS(SpawnNade, Nade)
    ATTRIB(SpawnNade, m_color, vector, COLOR_NADE_SPAWN);
    ATTRIB(SpawnNade, m_name, string, _("Spawn grenade"));
    ATTRIB(SpawnNade, m_icon, string, "nade_spawn");
#ifdef MENUQC
    METHOD(SpawnNade, describe, string(SpawnNade this))
    {
        TC(SpawnNade, this);
        return sprintf(_("The %s detonates after a short delay, temporarily setting your spawn point to where it detonated. "
            "It is useful for cases where you want to go back to some point on the map after you die"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(SpawnNade)
REGISTER_NADE(SPAWN, NEW(SpawnNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_SPAWN, EFFECT_NADE_TRAIL_YELLOW);
#endif
}

CLASS(HealNade, Nade)
    ATTRIB(HealNade, m_color, vector, COLOR_NADE_HEAL);
    ATTRIB(HealNade, m_name, string, _("Heal grenade"));
    ATTRIB(HealNade, m_icon, string, "nade_heal");
#ifdef MENUQC
    METHOD(HealNade, describe, string(HealNade this))
    {
        TC(HealNade, this);
        return sprintf(_("The %s detonates after a short delay, temporarily creating a healing orb around the point where it detonated for several seconds. "
            "If your team members enter the orb they will recover health, and if enemies enter the sphere they will be harmed"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(HealNade)
REGISTER_NADE(HEAL, NEW(HealNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_HEAL, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_HEAL_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(MonsterNade, Nade)
    ATTRIB(MonsterNade, m_color, vector, COLOR_NADE_MONSTER);
    ATTRIB(MonsterNade, m_name, string, _("Monster grenade"));
    ATTRIB(MonsterNade, m_icon, string, "nade_monster");
#ifdef MENUQC
    METHOD(MonsterNade, describe, string(MonsterNade this))
    {
        TC(MonsterNade, this);
        return sprintf(_("The %s explodes after a short delay, spawning one of four monster types"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(MonsterNade)
REGISTER_NADE(MONSTER, NEW(MonsterNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_MONSTER, EFFECT_NADE_TRAIL_RED);
    NADE_PROJECTILE(1, PROJECTILE_NADE_MONSTER_BURN, EFFECT_NADE_TRAIL_BURN_RED);
#endif
}

CLASS(EntrapNade, Nade)
    ATTRIB(EntrapNade, m_color, vector, COLOR_NADE_ENTRAP);
    ATTRIB(EntrapNade, m_name, string, _("Entrap grenade"));
    ATTRIB(EntrapNade, m_icon, string, "nade_entrap");
#ifdef MENUQC
    METHOD(EntrapNade, describe, string(EntrapNade this))
    {
        TC(EntrapNade, this);
        return sprintf(_("The %s detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
            "Players and projectiles that enter the sphere will be slowed down, including yourself"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(EntrapNade)
REGISTER_NADE(ENTRAP, NEW(EntrapNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_ENTRAP, EFFECT_NADE_TRAIL_YELLOW);
    NADE_PROJECTILE(1, PROJECTILE_NADE_ENTRAP_BURN, EFFECT_NADE_TRAIL_BURN_YELLOW);
#endif
}

CLASS(VeilNade, Nade)
    ATTRIB(VeilNade, m_color, vector, COLOR_NADE_VEIL);
    ATTRIB(VeilNade, m_name, string, _("Veil grenade"));
    ATTRIB(VeilNade, m_icon, string, "nade_veil");
    ATTRIB(VeilNade, m_alpha, float, 0.45);
#ifdef MENUQC
    METHOD(VeilNade, describe, string(VeilNade this))
    {
        TC(VeilNade, this);
        return sprintf(_("The Veil grenade detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
            "Players inside the orb will be invisible to those outside it"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(VeilNade)
REGISTER_NADE(VEIL, NEW(VeilNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_VEIL, EFFECT_NADE_TRAIL_NEUTRAL);
    NADE_PROJECTILE(1, PROJECTILE_NADE_VEIL_BURN, EFFECT_NADE_TRAIL_BURN_NEUTRAL);
#endif
}

CLASS(AmmoNade, Nade)
    ATTRIB(AmmoNade, m_color, vector, COLOR_NADE_AMMO);
    ATTRIB(AmmoNade, m_name, string, _("Ammo grenade"));
    ATTRIB(AmmoNade, m_icon, string, "nade_ammo");
#ifdef MENUQC
    METHOD(AmmoNade, describe, string(AmmoNade this))
    {
        TC(AmmoNade, this);
        return sprintf(_("The %s detonates after a short delay, temporarily creating an orb around the point where it detonated for several seconds. "
            "If your team members enter the orb they will recover ammo, and if enemies enter the sphere they will lose ammo\n\n"
            "This does not impact weapon magazines, so it won't reload your weapons for you"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(AmmoNade)
REGISTER_NADE(AMMO, NEW(AmmoNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_AMMO, EFFECT_NADE_TRAIL_BROWN);
    NADE_PROJECTILE(1, PROJECTILE_NADE_AMMO_BURN, EFFECT_NADE_TRAIL_BURN_BROWN);
#endif
}

CLASS(DarknessNade, Nade)
    ATTRIB(DarknessNade, m_color, vector, COLOR_NADE_DARKNESS);
    ATTRIB(DarknessNade, m_name, string, _("Darkness grenade"));
    ATTRIB(DarknessNade, m_icon, string, "nade_darkness");
#ifdef MENUQC
    METHOD(DarknessNade, describe, string(DarknessNade this))
    {
        TC(DarknessNade, this);
        return sprintf(_("The %s detonates after a short delay, creating a dark field which temporarily blinds enemies who enter it"),
        COLORED_NAME(this));
    }
#endif
ENDCLASS(DarknessNade)
REGISTER_NADE(DARKNESS, NEW(DarknessNade)) {
#ifdef GAMEQC
    NADE_PROJECTILE(0, PROJECTILE_NADE_DARKNESS, EFFECT_NADE_TRAIL_PURPLE);
    NADE_PROJECTILE(1, PROJECTILE_NADE_DARKNESS_BURN, EFFECT_NADE_TRAIL_BURN_PURPLE);
#endif
}
