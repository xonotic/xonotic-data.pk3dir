#include <lib/color.qh>

string Buff_CompatName(string buffname)
{
    switch(buffname)
    {
        case "ammoregen": return "ammo";               // Q3TA ammoregen
        case "doubler": return "inferno";              // Q3TA doubler
        case "scout": return "bash";                   // Q3TA scout
        case "guard": return "resistance";             // Q3TA guard
        case "revival": case "regen": return "medic";  // WOP revival, Q3A regen
        case "jumper": return "jump";                  // WOP jumper
        case "invulnerability": return "vampire";      // Q3TA invulnerability
        case "kamikaze": return "vengeance";           // Q3TA kamikaze
        case "teleporter": return "swapper";           // Q3A personal teleporter
        default: return buffname;
    }
}

CLASS(AmmoBuff, Buff)
    ATTRIB(AmmoBuff, m_name, string, _("Ammo"));
    ATTRIB(AmmoBuff, netname, string, "ammo");
    ATTRIB(AmmoBuff, m_icon, string, "buff_ammo");
    ATTRIB(AmmoBuff, m_skin, int, 3);
    ATTRIB(AmmoBuff, m_color, vector, '0.76 1 0.1');
#ifdef MENUQC
    METHOD(AmmoBuff, describe, string(AmmoBuff this))
    {
        TC(AmmoBuff, this);
        return sprintf(_("The %s gives you infinite ammo until the buff expires, so you don't need to worry about running out of ammo"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(AmmoBuff)
REGISTER_BUFF(AMMO, NEW(AmmoBuff));
BUFF_SPAWNFUNCS(ammo, BUFF_AMMO)
BUFF_SPAWNFUNC_Q3COMPAT(item_ammoregen, BUFF_AMMO)

CLASS(ResistanceBuff, Buff)
    ATTRIB(ResistanceBuff, m_name, string, _("Resistance"));
    ATTRIB(ResistanceBuff, netname, string, "resistance");
    ATTRIB(ResistanceBuff, m_icon, string, "buff_resistance");
    ATTRIB(ResistanceBuff, m_skin, int, 0);
    ATTRIB(ResistanceBuff, m_color, vector, '0.36 0 0.07');
#ifdef MENUQC
    METHOD(ResistanceBuff, describe, string(ResistanceBuff this))
    {
        TC(ResistanceBuff, this);
        return sprintf(_("The %s greatly reduces your damage taken while the buff is active\n\n"
            "This also impacts the damage you deal to yourself"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(ResistanceBuff)
REGISTER_BUFF(RESISTANCE, NEW(ResistanceBuff));
BUFF_SPAWNFUNCS(resistance, BUFF_RESISTANCE)
BUFF_SPAWNFUNC_Q3COMPAT(item_guard, BUFF_RESISTANCE)

CLASS(MedicBuff, Buff)
    ATTRIB(MedicBuff, m_name, string, _("Medic"));
    ATTRIB(MedicBuff, netname, string, "medic");
    ATTRIB(MedicBuff, m_icon, string, "buff_medic");
    ATTRIB(MedicBuff, m_skin, int, 1);
    ATTRIB(MedicBuff, m_color, vector, '1 0.12 0');
#ifdef MENUQC
    METHOD(MedicBuff, describe, string(MedicBuff this))
    {
        TC(MedicBuff, this);
        return sprintf(_("The %s increases health regeneration speed, increases the maximum health you can have before health starts to rot, and reduces health rot speed until the buff expires\n\n"
            "It also gives you a chance to survive a fatal hit, with a small amount of health left over"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(MedicBuff)
REGISTER_BUFF(MEDIC, NEW(MedicBuff));
BUFF_SPAWNFUNCS(medic, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3COMPAT(item_regen, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3COMPAT(item_revival, BUFF_MEDIC)

CLASS(BashBuff, Buff)
    ATTRIB(BashBuff, m_name, string, _("Bash"));
    ATTRIB(BashBuff, netname, string, "bash");
    ATTRIB(BashBuff, m_icon, string, "buff_bash");
    ATTRIB(BashBuff, m_skin, int, 5);
    ATTRIB(BashBuff, m_color, vector, '1 0.39 0');
#ifdef MENUQC
    METHOD(BashBuff, describe, string(BashBuff this))
    {
        TC(BashBuff, this);
        return sprintf(_("The %s increases knockback force you deal, and makes you immune to knockback while the buff is active\n\n"
            "It also slightly increases knockback you deal to yourself"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(BashBuff)
REGISTER_BUFF(BASH, NEW(BashBuff));
BUFF_SPAWNFUNCS(bash, BUFF_BASH)
BUFF_SPAWNFUNC_Q3COMPAT(item_scout, BUFF_BASH)

CLASS(VampireBuff, Buff)
    ATTRIB(VampireBuff, m_name, string, _("Vampire"));
    ATTRIB(VampireBuff, netname, string, "vampire");
    ATTRIB(VampireBuff, m_icon, string, "buff_vampire");
    ATTRIB(VampireBuff, m_skin, int, 2);
    ATTRIB(VampireBuff, m_color, vector, '1 0 0.24');
#ifdef MENUQC
    METHOD(VampireBuff, describe, string(VampireBuff this))
    {
        TC(VampireBuff, this);
        return sprintf(_("The %s converts some of the damage you deal to enemies and monsters into health for yourself, until the buff expires"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(VampireBuff)
REGISTER_BUFF(VAMPIRE, NEW(VampireBuff));
BUFF_SPAWNFUNCS(vampire, BUFF_VAMPIRE)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_invulnerability, BUFF_VAMPIRE)

CLASS(DisabilityBuff, Buff)
    ATTRIB(DisabilityBuff, m_name, string, _("Disability"));
    ATTRIB(DisabilityBuff, netname, string, "disability");
    ATTRIB(DisabilityBuff, m_icon, string, "buff_disability");
    ATTRIB(DisabilityBuff, m_skin, int, 7);
    ATTRIB(DisabilityBuff, m_color, vector, '0.94 0.3 1');
#ifdef MENUQC
    METHOD(DisabilityBuff, describe, string(DisabilityBuff this))
    {
        TC(DisabilityBuff, this);
        return sprintf(_("The %s causes your enemies and monsters to slow down for a few seconds when you attack them, while the buff is active\n\n"
            "This is particularly useful against speedy players, especially in Capture The Flag"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(DisabilityBuff)
REGISTER_BUFF(DISABILITY, NEW(DisabilityBuff));
BUFF_SPAWNFUNCS(disability, BUFF_DISABILITY)

CLASS(VengeanceBuff, Buff)
    ATTRIB(VengeanceBuff, m_name, string, _("Vengeance"));
    ATTRIB(VengeanceBuff, netname, string, "vengeance");
    ATTRIB(VengeanceBuff, m_icon, string, "buff_vengeance");
    ATTRIB(VengeanceBuff, m_skin, int, 15);
    ATTRIB(VengeanceBuff, m_color, vector, '1 0.23 0.61');
#ifdef MENUQC
    METHOD(VengeanceBuff, describe, string(VengeanceBuff this))
    {
        TC(VengeanceBuff, this);
        return sprintf(_("The %s reciprocates a portion of the damage enemies deal to you onto them, until the buff expires"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(VengeanceBuff)
REGISTER_BUFF(VENGEANCE, NEW(VengeanceBuff));
BUFF_SPAWNFUNCS(vengeance, BUFF_VENGEANCE)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_kamikaze, BUFF_VENGEANCE)

CLASS(JumpBuff, Buff)
    ATTRIB(JumpBuff, m_name, string, _("Jump"));
    ATTRIB(JumpBuff, netname, string, "jump");
    ATTRIB(JumpBuff, m_icon, string, "buff_jump");
    ATTRIB(JumpBuff, m_skin, int, 10);
    ATTRIB(JumpBuff, m_color, vector, '0.24 0.78 1');
#ifdef MENUQC
    METHOD(JumpBuff, describe, string(JumpBuff this))
    {
        TC(JumpBuff, this);
        return sprintf(_("The %s greatly increases your jump height, while the buff is active"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(JumpBuff)
REGISTER_BUFF(JUMP, NEW(JumpBuff));
BUFF_SPAWNFUNCS(jump, BUFF_JUMP)
BUFF_SPAWNFUNC_Q3COMPAT(item_jumper, BUFF_JUMP)

CLASS(InfernoBuff, Buff)
    ATTRIB(InfernoBuff, m_name, string, _("Inferno"));
    ATTRIB(InfernoBuff, netname, string, "inferno");
    ATTRIB(InfernoBuff, m_icon, string, "buff_inferno");
    ATTRIB(InfernoBuff, m_skin, int, 16);
    ATTRIB(InfernoBuff, m_color, vector, '1 0.62 0');
#ifdef MENUQC
    METHOD(InfernoBuff, describe, string(InfernoBuff this))
    {
        TC(InfernoBuff, this);
        return sprintf(_("The %s sets any enemies or monsters you attack alight, dealing burn damage to them for several seconds until the buff expires"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(InfernoBuff)
REGISTER_BUFF(INFERNO, NEW(InfernoBuff));
BUFF_SPAWNFUNCS(inferno, BUFF_INFERNO)
BUFF_SPAWNFUNC_Q3COMPAT(item_doubler, BUFF_INFERNO)

CLASS(SwapperBuff, Buff)
    ATTRIB(SwapperBuff, m_name, string, _("Swapper"));
    ATTRIB(SwapperBuff, netname, string, "swapper");
    ATTRIB(SwapperBuff, m_icon, string, "buff_swapper");
    ATTRIB(SwapperBuff, m_skin, int, 17);
    ATTRIB(SwapperBuff, m_color, vector, '0.63 0.36 1');
#ifdef MENUQC
    METHOD(SwapperBuff, describe, string(SwapperBuff this))
    {
        TC(SwapperBuff, this);
        return sprintf(_("The %s allows you to press the ^3drop weapon^7 bind to switch places with a nearby enemy once\n\n"
            "A common usage of this Buff is to jump over the map's void, then swap with an enemy, to cause them to fall into the void"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(SwapperBuff)
REGISTER_BUFF(SWAPPER, NEW(SwapperBuff));
BUFF_SPAWNFUNCS(swapper, BUFF_SWAPPER)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_teleporter, BUFF_SWAPPER)

CLASS(MagnetBuff, Buff)
    ATTRIB(MagnetBuff, m_name, string, _("Magnet"));
    ATTRIB(MagnetBuff, netname, string, "magnet");
    ATTRIB(MagnetBuff, m_icon, string, "buff_magnet");
    ATTRIB(MagnetBuff, m_skin, int, 18);
    ATTRIB(MagnetBuff, m_color, vector, '1 0.95 0.18');
#ifdef MENUQC
    METHOD(MagnetBuff, describe, string(MagnetBuff this))
    {
        TC(MagnetBuff, this);
        return sprintf(_("The %s greatly increases your item pickup range, collecting nearby items for you while the buff is active"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(MagnetBuff)
REGISTER_BUFF(MAGNET, NEW(MagnetBuff));
BUFF_SPAWNFUNCS(magnet, BUFF_MAGNET)

CLASS(LuckBuff, Buff)
    ATTRIB(LuckBuff, m_name, string, _("Luck"));
    ATTRIB(LuckBuff, netname, string, "luck");
    ATTRIB(LuckBuff, m_icon, string, "buff_luck");
    ATTRIB(LuckBuff, m_skin, int, 19);
    ATTRIB(LuckBuff, m_color, vector, '1 0.23 0.44');
#ifdef MENUQC
    METHOD(LuckBuff, describe, string(LuckBuff this))
    {
        TC(LuckBuff, this);
        return sprintf(_("While you have the %s, each attack has a chance of being a critical hit with greatly increased damage"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(LuckBuff)
REGISTER_BUFF(LUCK, NEW(LuckBuff));
BUFF_SPAWNFUNCS(luck, BUFF_LUCK)

CLASS(FlightBuff, Buff)
    ATTRIB(FlightBuff, m_name, string, _("Flight"));
    ATTRIB(FlightBuff, netname, string, "flight");
    ATTRIB(FlightBuff, m_icon, string, "buff_flight");
    ATTRIB(FlightBuff, m_skin, int, 11);
    ATTRIB(FlightBuff, m_color, vector, '0.23 0.44 1');
#ifdef MENUQC
    METHOD(FlightBuff, describe, string(FlightBuff this))
    {
        TC(FlightBuff, this);
        return sprintf(_("While you have the %s, you can crouch while midair to switch your gravity, allowing flight"),
        COLORED_NAME_WITH_CONCAT(this, _("Buff")));
    }
#endif
ENDCLASS(FlightBuff)
REGISTER_BUFF(FLIGHT, NEW(FlightBuff));
BUFF_SPAWNFUNCS(flight, BUFF_FLIGHT)
BUFF_SPAWNFUNC_Q3COMPAT(item_flight, BUFF_FLIGHT)
