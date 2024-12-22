#include "ammo.qh"

#ifdef MENUQC
METHOD(Shells, describe, string(Shells this))
{
    TC(Shells, this);
    return sprintf(_("The %s ammo type is used by the %s and %s"),
        COLORED_NAME(Shells),
        strcat(rgb_to_hexcolor(COLOR_WEP_SHOTGUN), _("Shotgun"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_OKSHOTGUN), _("Overkill Shotgun"), "^7")
    );
}

METHOD(Bullets, describe, string(Bullets this))
{
    TC(Bullets, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, and %s"),
        COLORED_NAME(Bullets),
        strcat(rgb_to_hexcolor(COLOR_WEP_MACHINEGUN), _("MachineGun"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_RIFLE), _("Rifle"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_OKMACHINEGUN), _("Overkill MachineGun"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_OKHMG), _("Overkill Heavy Machine Gun"), "^7")
    );
}

METHOD(Rockets, describe, string(Rockets this))
{
    TC(Rockets, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, %s, %s, and %s"),
        COLORED_NAME(Rockets),
        strcat(rgb_to_hexcolor(COLOR_WEP_DEVASTATOR), _("Devastator"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_MORTAR), _("Mortar"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_HAGAR), _("Hagar"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_MINELAYER), _("Mine Layer"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_SEEKER), _("T.A.G. Seeker"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_OKRPC), _("Overkill Rocket Propelled Chainsaw"), "^7")
    );
}

METHOD(Cells, describe, string(Cells this))
{
    TC(Cells, this);
    return sprintf(_("The %s ammo type is used by the %s, %s, %s, %s, %s, and %s"),
        COLORED_NAME(Cells),
        strcat(rgb_to_hexcolor(COLOR_WEP_VORTEX), _("Vortex"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_CRYLINK), _("Crylink"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_ELECTRO), _("Electro"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_HLAC), _("Heavy Laser Assault Cannon"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_VAPORIZER), _("Vaporizer"), "^7"),
        strcat(rgb_to_hexcolor(COLOR_WEP_ARC), _("Arc"), "^7")
    );
}
#endif
