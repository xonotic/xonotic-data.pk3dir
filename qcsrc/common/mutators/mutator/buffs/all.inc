REGISTER_BUFF(AMMO) {
    this.m_prettyName = _("Ammo");
    this.m_name = "ammo";
    this.m_skin = 3;
    this.m_color = '0.76 1 0.1';
}
BUFF_SPAWNFUNCS(ammo, BUFF_AMMO)
BUFF_SPAWNFUNC_Q3TA_COMPAT(ammoregen, BUFF_AMMO)

REGISTER_BUFF(RESISTANCE) {
    this.m_prettyName = _("Resistance");
    this.m_name = "resistance";
    this.m_skin = 0;
    this.m_color = '0.36 1 0.07';
}
BUFF_SPAWNFUNCS(resistance, BUFF_RESISTANCE)
BUFF_SPAWNFUNC_Q3TA_COMPAT(resistance, BUFF_RESISTANCE)

REGISTER_BUFF(SPEED) {
    this.m_prettyName = _("Speed");
    this.m_name = "speed";
    this.m_skin = 9;
    this.m_color = '0.1 1 0.84';
}
BUFF_SPAWNFUNCS(speed, BUFF_SPEED)
BUFF_SPAWNFUNC_Q3TA_COMPAT(haste, BUFF_SPEED)
BUFF_SPAWNFUNC_Q3TA_COMPAT(scout, BUFF_SPEED)

REGISTER_BUFF(MEDIC) {
    this.m_prettyName = _("Medic");
    this.m_name = "medic";
    this.m_skin = 1;
    this.m_color = '1 0.12 0';
}
BUFF_SPAWNFUNCS(medic, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3TA_COMPAT(doubler, BUFF_MEDIC)
BUFF_SPAWNFUNC_Q3TA_COMPAT(medic, BUFF_MEDIC)

REGISTER_BUFF(BASH) {
    this.m_prettyName = _("Bash");
    this.m_name = "bash";
    this.m_skin = 5;
    this.m_color = '1 0.39 0';
}
BUFF_SPAWNFUNCS(bash, BUFF_BASH)

REGISTER_BUFF(VAMPIRE) {
    this.m_prettyName = _("Vampire");
    this.m_name = "vampire";
    this.m_skin = 2;
    this.m_color = '1 0 0.24';
}
BUFF_SPAWNFUNCS(vampire, BUFF_VAMPIRE)

REGISTER_BUFF(DISABILITY) {
    this.m_prettyName = _("Disability");
    this.m_name = "disability";
    this.m_skin = 7;
    this.m_color = '0.94 0.3 1';
}
BUFF_SPAWNFUNCS(disability, BUFF_DISABILITY)

REGISTER_BUFF(VENGEANCE) {
    this.m_prettyName = _("Vengeance");
    this.m_name = "vengeance";
    this.m_skin = 15;
    this.m_color = '1 0.23 0.61';
}
BUFF_SPAWNFUNCS(vengeance, BUFF_VENGEANCE)

REGISTER_BUFF(JUMP) {
    this.m_prettyName = _("Jump");
    this.m_name = "jump";
    this.m_skin = 10;
    this.m_color = '0.24 0.78 1';
}
BUFF_SPAWNFUNCS(jump, BUFF_JUMP)

REGISTER_BUFF(FLIGHT) {
    this.m_prettyName = _("Flight");
    this.m_name = "flight";
    this.m_skin = 11;
    this.m_color = '0.33 0.56 1';
}
BUFF_SPAWNFUNCS(flight, BUFF_FLIGHT)

REGISTER_BUFF(INVISIBLE) {
    this.m_prettyName = _("Invisible");
    this.m_name = "invisible";
    this.m_skin = 12;
    this.m_color = '0.5 0.5 1';
}
BUFF_SPAWNFUNCS(invisible, BUFF_INVISIBLE)
BUFF_SPAWNFUNC_Q3TA_COMPAT(invis, BUFF_INVISIBLE)

REGISTER_BUFF(INFERNO) {
    this.m_prettyName = _("Inferno");
    this.m_name = "inferno";
    this.m_skin = 16;
    this.m_color = '1 0.62 0';
}
BUFF_SPAWNFUNCS(inferno, BUFF_INFERNO)

REGISTER_BUFF(SWAPPER) {
    this.m_prettyName = _("Swapper");
    this.m_name = "swapper";
    this.m_skin = 17;
    this.m_color = '0.63 0.36 1';
}
BUFF_SPAWNFUNCS(swapper, BUFF_SWAPPER)

REGISTER_BUFF(MAGNET) {
    this.m_prettyName = _("Magnet");
    this.m_name = "magnet";
    this.m_skin = 18;
    this.m_color = '1 0.95 0.18';
}
BUFF_SPAWNFUNCS(magnet, BUFF_MAGNET)
