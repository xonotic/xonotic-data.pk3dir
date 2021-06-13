string Buff_UndeprecateName(string buffname)
{
    switch(buffname)
    {
        case "ammoregen": return "ammo";		// Q3TA ammoregen
        case "haste": return "speed";			// Q3A haste
        case "doubler": return "inferno";		// Q3TA doubler
        case "scout": return "bash";			// Q3TA scout
        case "guard": return "resistance";		// Q3TA guard
        case "revival": case "regen": return "medic";	// WOP revival, Q3A regen
        case "invis": return "invisible";		// Q3A invis
        case "jumper": return "jump";			// WOP jumper
        case "invulnerability": return "vampire";	// Q3TA invulnerability
        case "kamikaze": return "vengeance";		// Q3TA kamikaze
        case "teleporter": return "swapper";		// Q3A personal teleporter
        default: return buffname;
    }
}

REGISTER_BUFF(AMMO) {
    this.m_name = _("Ammo");
    this.netname = "ammo";
    this.m_skin = 3;
    this.m_color = '0.76 1 0.1';
}
BUFF_SPAWNFUNCS(ammo, BUFF_AMMO)
BUFF_SPAWNFUNC_Q3COMPAT(item_ammoregen, BUFF_AMMO)

REGISTER_BUFF(RESISTANCE) {
    this.m_name = _("Resistance");
    this.netname = "resistance";
    this.m_skin = 0;
    this.m_color = '0.36 1 0.07';
}
BUFF_SPAWNFUNCS(resistance, BUFF_RESISTANCE)
BUFF_SPAWNFUNC_Q3COMPAT(item_guard, BUFF_RESISTANCE)

REGISTER_BUFF(SPEED) {
    this.m_name = _("Speed");
    this.netname = "speed";
    this.m_skin = 9;
    this.m_color = '0.1 1 0.84';
}
BUFF_SPAWNFUNCS(speed, BUFF_SPEED)
BUFF_SPAWNFUNC_Q3COMPAT(item_haste, BUFF_SPEED)

REGISTER_BUFF(MEDIC) {
    this.m_name = _("Medic");
    this.netname = "medic";
    this.m_skin = 1;
    this.m_color = '1 0.12 0';
}
BUFF_SPAWNFUNCS(medic, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3COMPAT(item_regen, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3COMPAT(item_revival, BUFF_MEDIC)

REGISTER_BUFF(BASH) {
    this.m_name = _("Bash");
    this.netname = "bash";
    this.m_skin = 5;
    this.m_color = '1 0.39 0';
}
BUFF_SPAWNFUNCS(bash, BUFF_BASH)
BUFF_SPAWNFUNC_Q3COMPAT(item_scout, BUFF_BASH)

REGISTER_BUFF(VAMPIRE) {
    this.m_name = _("Vampire");
    this.netname = "vampire";
    this.m_skin = 2;
    this.m_color = '1 0 0.24';
}
BUFF_SPAWNFUNCS(vampire, BUFF_VAMPIRE)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_invulnerability, BUFF_VAMPIRE)

REGISTER_BUFF(DISABILITY) {
    this.m_name = _("Disability");
    this.netname = "disability";
    this.m_skin = 7;
    this.m_color = '0.94 0.3 1';
}
BUFF_SPAWNFUNCS(disability, BUFF_DISABILITY)

REGISTER_BUFF(VENGEANCE) {
    this.m_name = _("Vengeance");
    this.netname = "vengeance";
    this.m_skin = 15;
    this.m_color = '1 0.23 0.61';
}
BUFF_SPAWNFUNCS(vengeance, BUFF_VENGEANCE)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_kamikaze, BUFF_VENGEANCE)

REGISTER_BUFF(JUMP) {
    this.m_name = _("Jump");
    this.netname = "jump";
    this.m_skin = 10;
    this.m_color = '0.24 0.78 1';
}
BUFF_SPAWNFUNCS(jump, BUFF_JUMP)
BUFF_SPAWNFUNC_Q3COMPAT(item_jumper, BUFF_JUMP)

REGISTER_BUFF(INVISIBLE) {
    this.m_name = _("Invisible");
    this.netname = "invisible";
    this.m_skin = 12;
    this.m_color = '0.5 0.5 1';
}
BUFF_SPAWNFUNCS(invisible, BUFF_INVISIBLE)
BUFF_SPAWNFUNC_Q3COMPAT(item_invis, BUFF_INVISIBLE)

REGISTER_BUFF(INFERNO) {
    this.m_name = _("Inferno");
    this.netname = "inferno";
    this.m_skin = 16;
    this.m_color = '1 0.62 0';
}
BUFF_SPAWNFUNCS(inferno, BUFF_INFERNO)
BUFF_SPAWNFUNC_Q3COMPAT(item_doubler, BUFF_INFERNO)

REGISTER_BUFF(SWAPPER) {
    this.m_name = _("Swapper");
    this.netname = "swapper";
    this.m_skin = 17;
    this.m_color = '0.63 0.36 1';
}
BUFF_SPAWNFUNCS(swapper, BUFF_SWAPPER)
BUFF_SPAWNFUNC_Q3COMPAT(holdable_teleporter, BUFF_SWAPPER)

REGISTER_BUFF(MAGNET) {
    this.m_name = _("Magnet");
    this.netname = "magnet";
    this.m_skin = 18;
    this.m_color = '1 0.95 0.18';
}
BUFF_SPAWNFUNCS(magnet, BUFF_MAGNET)

REGISTER_BUFF(LUCK) {
    this.m_name = _("Luck");
    this.netname = "luck";
    this.m_skin = 19;
    this.m_color = '1 0.23 0.44';
}
BUFF_SPAWNFUNCS(luck, BUFF_LUCK)

REGISTER_BUFF(FLIGHT) {
    this.m_name = _("Flight");
    this.netname = "flight";
    this.m_skin = 11;
    this.m_color = '0.23 0.44 1';
}
BUFF_SPAWNFUNCS(flight, BUFF_FLIGHT)
BUFF_SPAWNFUNC_Q3COMPAT(item_flight, BUFF_FLIGHT)
