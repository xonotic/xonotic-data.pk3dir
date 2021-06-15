string Buff_UndeprecateName(string buffname)
{
    switch(buffname)
    {
        case "ammoregen": return "ammo";
        case "haste": case "scout": return "speed";
        case "guard": return "resistance";
        case "revival": case "regen": return "medic";
        case "invis": return "invisible";
        case "jumper": return "jump";
        default: return buffname;
    }
}

REGISTER_BUFF(AMMO) {
    this.m_name = _("Ammo");
    this.netname = "ammo";
    this.m_icon = "buff_ammo";
    this.m_skin = 3;
    this.m_color = '0.76 1 0.1';
}
BUFF_SPAWNFUNCS(ammo, BUFF_AMMO)
BUFF_SPAWNFUNC_Q3TA_COMPAT(ammoregen, BUFF_AMMO)

REGISTER_BUFF(RESISTANCE) {
    this.m_name = _("Resistance");
    this.netname = "resistance";
    this.m_icon = "buff_resistance";
    this.m_skin = 0;
    this.m_color = '0.36 1 0.07';
}
BUFF_SPAWNFUNCS(resistance, BUFF_RESISTANCE)
BUFF_SPAWNFUNC_Q3TA_COMPAT(guard, BUFF_RESISTANCE)

REGISTER_BUFF(SPEED) {
    this.m_name = _("Speed");
    this.netname = "speed";
    this.m_icon = "buff_speed";
    this.m_skin = 9;
    this.m_color = '0.1 1 0.84';
}
BUFF_SPAWNFUNCS(speed, BUFF_SPEED)
BUFF_SPAWNFUNC_Q3TA_COMPAT(haste, BUFF_SPEED)
BUFF_SPAWNFUNC_Q3TA_COMPAT(scout, BUFF_SPEED)

REGISTER_BUFF(MEDIC) {
    this.m_name = _("Medic");
    this.netname = "medic";
    this.m_icon = "buff_medic";
    this.m_skin = 1;
    this.m_color = '1 0.12 0';
}
BUFF_SPAWNFUNCS(medic, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3TA_COMPAT(regen, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3TA_COMPAT(revival, BUFF_MEDIC)

REGISTER_BUFF(BASH) {
    this.m_name = _("Bash");
    this.netname = "bash";
    this.m_icon = "buff_bash";
    this.m_skin = 5;
    this.m_color = '1 0.39 0';
}
BUFF_SPAWNFUNCS(bash, BUFF_BASH)
BUFF_SPAWNFUNC_Q3TA_COMPAT(doubler, BUFF_BASH)

REGISTER_BUFF(VAMPIRE) {
    this.m_name = _("Vampire");
    this.netname = "vampire";
    this.m_icon = "buff_vampire";
    this.m_skin = 2;
    this.m_color = '1 0 0.24';
}
BUFF_SPAWNFUNCS(vampire, BUFF_VAMPIRE)

REGISTER_BUFF(DISABILITY) {
    this.m_name = _("Disability");
    this.netname = "disability";
    this.m_icon = "buff_disability";
    this.m_skin = 7;
    this.m_color = '0.94 0.3 1';
}
BUFF_SPAWNFUNCS(disability, BUFF_DISABILITY)

REGISTER_BUFF(VENGEANCE) {
    this.m_name = _("Vengeance");
    this.netname = "vengeance";
    this.m_icon = "buff_vengeance";
    this.m_skin = 15;
    this.m_color = '1 0.23 0.61';
}
BUFF_SPAWNFUNCS(vengeance, BUFF_VENGEANCE)

REGISTER_BUFF(JUMP) {
    this.m_name = _("Jump");
    this.netname = "jump";
    this.m_icon = "buff_jump";
    this.m_skin = 10;
    this.m_color = '0.24 0.78 1';
}
BUFF_SPAWNFUNCS(jump, BUFF_JUMP)
BUFF_SPAWNFUNC_Q3TA_COMPAT(jumper, BUFF_JUMP)

REGISTER_BUFF(INVISIBLE) {
    this.m_name = _("Invisible");
    this.netname = "invisible";
    this.m_icon = "buff_invisible";
    this.m_skin = 12;
    this.m_color = '0.5 0.5 1';
}
BUFF_SPAWNFUNCS(invisible, BUFF_INVISIBLE)
BUFF_SPAWNFUNC_Q3TA_COMPAT(invis, BUFF_INVISIBLE)

REGISTER_BUFF(INFERNO) {
    this.m_name = _("Inferno");
    this.netname = "inferno";
    this.m_icon = "buff_inferno";
    this.m_skin = 16;
    this.m_color = '1 0.62 0';
}
BUFF_SPAWNFUNCS(inferno, BUFF_INFERNO)

REGISTER_BUFF(SWAPPER) {
    this.m_name = _("Swapper");
    this.netname = "swapper";
    this.m_icon = "buff_swapper";
    this.m_skin = 17;
    this.m_color = '0.63 0.36 1';
}
BUFF_SPAWNFUNCS(swapper, BUFF_SWAPPER)

REGISTER_BUFF(MAGNET) {
    this.m_name = _("Magnet");
    this.netname = "magnet";
    this.m_icon = "buff_magnet";
    this.m_skin = 18;
    this.m_color = '1 0.95 0.18';
}
BUFF_SPAWNFUNCS(magnet, BUFF_MAGNET)

REGISTER_BUFF(LUCK) {
    this.m_name = _("Luck");
    this.netname = "luck";
    this.m_icon = "buff_luck";
    this.m_skin = 19;
    this.m_color = '1 0.23 0.44';
}
BUFF_SPAWNFUNCS(luck, BUFF_LUCK)

REGISTER_BUFF(FLIGHT) {
    this.m_name = _("Flight");
    this.netname = "flight";
    this.m_icon = "buff_flight";
    this.m_skin = 11;
    this.m_color = '0.23 0.44 1';
}
BUFF_SPAWNFUNCS(flight, BUFF_FLIGHT)
BUFF_SPAWNFUNC_Q3TA_COMPAT(flight, BUFF_FLIGHT)
