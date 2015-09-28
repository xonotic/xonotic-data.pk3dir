// Global list of sounds
// TODO: remove uses of _sound

string W_Sound(string w_snd);

SOUND(ARC_FIRE, W_Sound("arc_fire"));
SOUND(ARC_LOOP, W_Sound("arc_loop"));
SOUND(ARC_LOOP_OVERHEAT, W_Sound("arc_loop_overheat"));
SOUND(ARC_STOP, W_Sound("arc_stop"));
SOUND(CAMPINGRIFLE_FIRE2, W_Sound("campingrifle_fire2"));
SOUND(CAMPINGRIFLE_FIRE, W_Sound("campingrifle_fire"));
SOUND(CRYLINK_FIRE2, W_Sound("crylink_fire2"));
SOUND(CRYLINK_FIRE, W_Sound("crylink_fire"));
SOUND(CRYLINK_IMPACT2, W_Sound("crylink_impact2"));
SOUND(CRYLINK_IMPACT, W_Sound("crylink_impact"));
SOUND(CRYLINK_LINKJOIN, W_Sound("crylink_linkjoin"));
SOUND(DRYFIRE, W_Sound("dryfire"));
SOUND(ELECTRO_BOUNCE, W_Sound("electro_bounce"));
SOUND(ELECTRO_FIRE2, W_Sound("electro_fire2"));
SOUND(ELECTRO_FIRE, W_Sound("electro_fire"));
SOUND(ELECTRO_FLY, W_Sound("electro_fly"));
SOUND(ELECTRO_IMPACT, W_Sound("electro_impact"));
SOUND(ELECTRO_IMPACT_COMBO, W_Sound("electro_impact_combo"));
SOUND(FIREBALL_FIRE2, W_Sound("fireball_fire2"));
SOUND(FIREBALL_FIRE, W_Sound("fireball_fire"));
SOUND(FIREBALL_FLY2, W_Sound("fireball_fly2"));
SOUND(FIREBALL_FLY, W_Sound("fireball_fly"));
SOUND(FIREBALL_IMPACT2, W_Sound("fireball_impact2"));
SOUND(FIREBALL_PREFIRE2, W_Sound("fireball_prefire2"));
SOUND(FLAC_FIRE, W_Sound("flac_fire"));
SOUND(GRENADE_BOUNCE1, W_Sound("grenade_bounce1"));
SOUND(GRENADE_BOUNCE2, W_Sound("grenade_bounce2"));
SOUND(GRENADE_BOUNCE3, W_Sound("grenade_bounce3"));
SOUND(GRENADE_BOUNCE4, W_Sound("grenade_bounce4"));
SOUND(GRENADE_BOUNCE5, W_Sound("grenade_bounce5"));
SOUND(GRENADE_BOUNCE6, W_Sound("grenade_bounce6"));
Sound SND_GRENADE_BOUNCE_RANDOM() {
    return SOUNDS[SND_GRENADE_BOUNCE1.m_id + rint(random() * 5)];
}
SOUND(GRENADE_FIRE, W_Sound("grenade_fire"));
SOUND(GRENADE_IMPACT, W_Sound("grenade_impact"));
SOUND(GRENADE_STICK, W_Sound("grenade_stick"));
SOUND(HAGAR_BEEP, W_Sound("hagar_beep"));
SOUND(HAGAR_FIRE, W_Sound("hagar_fire"));
SOUND(HAGAR_LOAD, W_Sound("hagar_load"));
SOUND(HAGEXP1, W_Sound("hagexp1"));
SOUND(HAGEXP2, W_Sound("hagexp2"));
SOUND(HAGEXP3, W_Sound("hagexp3"));
Sound SND_HAGEXP_RANDOM() {
    return SOUNDS[SND_HAGEXP1.m_id + rint(random() * 2)];
}

SOUND(HOOKBOMB_FIRE, W_Sound("hookbomb_fire"));
SOUND(HOOKBOMB_IMPACT, W_Sound("hookbomb_impact"));
SOUND(HOOK_FIRE, W_Sound("hook_fire"));
SOUND(HOOK_IMPACT, W_Sound("hook_impact"));
SOUND(LASERGUN_FIRE, W_Sound("lasergun_fire"));
SOUND(LASERIMPACT, W_Sound("laserimpact"));
SOUND(LGBEAM_FLY, W_Sound("lgbeam_fly"));
SOUND(MINE_DET, W_Sound("mine_det"));
SOUND(MINE_EXP, W_Sound("mine_exp"));
SOUND(MINE_FIRE, W_Sound("mine_fire"));
SOUND(MINE_STICK, W_Sound("mine_stick"));
SOUND(MINE_TRIGGER, W_Sound("mine_trigger"));
SOUND(MINSTANEXFIRE, W_Sound("minstanexfire"));
SOUND(NEXCHARGE, W_Sound("nexcharge"));
SOUND(NEXFIRE, W_Sound("nexfire"));
SOUND(NEXIMPACT, W_Sound("neximpact"));
SOUND(NEXWHOOSH1, W_Sound("nexwhoosh1"));
SOUND(NEXWHOOSH2, W_Sound("nexwhoosh2"));
SOUND(NEXWHOOSH3, W_Sound("nexwhoosh3"));
Sound SND_NEXWHOOSH_RANDOM() {
    return SOUNDS[SND_NEXWHOOSH1.m_id + rint(random() * 2)];
}
SOUND(RELOAD, W_Sound("reload")); // until weapons have individual reload sounds, precache the reload sound here

SOUND(RIC1, W_Sound("ric1"));
SOUND(RIC2, W_Sound("ric2"));
SOUND(RIC3, W_Sound("ric3"));
Sound SND_RIC_RANDOM() {
    return SOUNDS[SND_RIC1.m_id + rint(random() * 2)];
}

SOUND(ROCKET_DET, W_Sound("rocket_det"));
SOUND(ROCKET_FIRE, W_Sound("rocket_fire"));
SOUND(ROCKET_FLY, W_Sound("rocket_fly"));
SOUND(ROCKET_IMPACT, W_Sound("rocket_impact"));
SOUND(ROCKET_MODE, W_Sound("rocket_mode"));
SOUND(SEEKEREXP1, W_Sound("seekerexp1"));
SOUND(SEEKEREXP2, W_Sound("seekerexp2"));
SOUND(SEEKEREXP3, W_Sound("seekerexp3"));
SOUND(SEEKER_FIRE, W_Sound("seeker_fire"));
SOUND(SHOTGUN_FIRE, W_Sound("shotgun_fire"));
SOUND(SHOTGUN_MELEE, W_Sound("shotgun_melee"));
SOUND(STRENGTH_FIRE, W_Sound("strength_fire"));
SOUND(TAGEXP1, W_Sound("tagexp1"));
SOUND(TAGEXP2, W_Sound("tagexp2"));
SOUND(TAGEXP3, W_Sound("tagexp3"));
SOUND(TAG_FIRE, W_Sound("tag_fire"));
SOUND(TAG_IMPACT, W_Sound("tag_impact"));
SOUND(TAG_ROCKET_FLY, W_Sound("tag_rocket_fly"));
SOUND(UNAVAILABLE, W_Sound("unavailable"));
SOUND(UZI_FIRE, W_Sound("uzi_fire"));
SOUND(WEAPONPICKUP, W_Sound("weaponpickup"));
SOUND(WEAPONPICKUP_NEW_TOYS, W_Sound("weaponpickup_new_toys"));
SOUND(WEAPON_SWITCH, W_Sound("weapon_switch"));

SOUND(CTF_CAPTURE_NEUTRAL, "ctf/capture.ogg");
SOUND(CTF_CAPTURE_RED, "ctf/red_capture.wav");
SOUND(CTF_CAPTURE_BLUE, "ctf/blue_capture.wav");
SOUND(CTF_CAPTURE_YELLOW, "ctf/yellow_capture.ogg");
SOUND(CTF_CAPTURE_PINK, "ctf/pink_capture.ogg");
Sound SND_CTF_CAPTURE(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_CAPTURE_RED;
        case NUM_TEAM_2:    return SND_CTF_CAPTURE_BLUE;
        case NUM_TEAM_3:    return SND_CTF_CAPTURE_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_CAPTURE_PINK;
        default:            return SND_CTF_CAPTURE_NEUTRAL;
    }
}

SOUND(CTF_DROPPED_NEUTRAL,  "ctf/neutral_dropped.wav");
SOUND(CTF_DROPPED_RED,      "ctf/red_dropped.wav");
SOUND(CTF_DROPPED_BLUE,     "ctf/blue_dropped.wav");
SOUND(CTF_DROPPED_YELLOW,   "ctf/yellow_dropped.wav");
SOUND(CTF_DROPPED_PINK,     "ctf/pink_dropped.wav");
Sound SND_CTF_DROPPED(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_DROPPED_RED;
        case NUM_TEAM_2:    return SND_CTF_DROPPED_BLUE;
        case NUM_TEAM_3:    return SND_CTF_DROPPED_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_DROPPED_PINK;
        default:            return SND_CTF_DROPPED_NEUTRAL;
    }
}

SOUND(CTF_PASS, "ctf/pass.wav");
SOUND(CTF_RESPAWN, "ctf/flag_respawn.wav");

SOUND(CTF_RETURNED_NEUTRAL,  "ctf/return.wav");
SOUND(CTF_RETURNED_RED,      "ctf/red_returned.wav");
SOUND(CTF_RETURNED_BLUE,     "ctf/blue_returned.wav");
SOUND(CTF_RETURNED_YELLOW,   "ctf/yellow_returned.wav");
SOUND(CTF_RETURNED_PINK,     "ctf/pink_returned.wav");
Sound SND_CTF_RETURNED(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_RETURNED_RED;
        case NUM_TEAM_2:    return SND_CTF_RETURNED_BLUE;
        case NUM_TEAM_3:    return SND_CTF_RETURNED_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_RETURNED_PINK;
        default:            return SND_CTF_RETURNED_NEUTRAL;
    }
}

SOUND(CTF_TAKEN_NEUTRAL,  "ctf/neutral_taken.wav");
SOUND(CTF_TAKEN_RED,      "ctf/red_taken.wav");
SOUND(CTF_TAKEN_BLUE,     "ctf/blue_taken.wav");
SOUND(CTF_TAKEN_YELLOW,   "ctf/yellow_taken.wav");
SOUND(CTF_TAKEN_PINK,     "ctf/pink_taken.wav");
Sound SND_CTF_TAKEN(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_TAKEN_RED;
        case NUM_TEAM_2:    return SND_CTF_TAKEN_BLUE;
        case NUM_TEAM_3:    return SND_CTF_TAKEN_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_TAKEN_PINK;
        default:            return SND_CTF_TAKEN_NEUTRAL;
    }
}

SOUND(CTF_TOUCH, "ctf/touch.wav");

SOUND(DOM_CLAIM, "domination/claim.wav");

SOUND(KA_DROPPED, "keepaway/dropped.wav");
SOUND(KA_PICKEDUP, "keepaway/pickedup.wav");
SOUND(KA_RESPAWN, "keepaway/respawn.wav");
SOUND(KA_TOUCH, "keepaway/touch.wav");

SOUND(KH_ALARM, "kh/alarm.wav");
SOUND(KH_CAPTURE, "kh/capture.wav");
SOUND(KH_COLLECT, "kh/collect.wav");
SOUND(KH_DESTROY, "kh/destroy.wav");
SOUND(KH_DROP, "kh/drop.wav");

SOUND(NB_BOUNCE, "nexball/bounce.ogg");
SOUND(NB_DROP, "nexball/drop.ogg");
SOUND(NB_SHOOT1, "nexball/shoot1.ogg");
SOUND(NB_SHOOT2, "nexball/shoot2.ogg");
SOUND(NB_STEAL, "nexball/steal.ogg");

SOUND(ONS_CONTROLPOINT_BUILD, "onslaught/controlpoint_build.ogg");
SOUND(ONS_CONTROLPOINT_BUILT, "onslaught/controlpoint_built.ogg");
SOUND(ONS_CONTROLPOINT_UNDERATTACK, "onslaught/controlpoint_underattack.ogg");
SOUND(ONS_DAMAGEBLOCKEDBYSHIELD, "onslaught/damageblockedbyshield.wav");
SOUND(ONS_ELECTRICITY_EXPLODE, "onslaught/electricity_explode.ogg");
SOUND(ONS_GENERATOR_DECAY, "onslaught/generator_decay.ogg");
SOUND(ONS_GENERATOR_UNDERATTACK, "onslaught/generator_underattack.ogg");
SOUND(ONS_HIT1, "onslaught/ons_hit1.ogg");
SOUND(ONS_HIT2, "onslaught/ons_hit2.ogg");
SOUND(ONS_SPARK1, "onslaught/ons_spark1.ogg");
SOUND(ONS_SPARK2, "onslaught/ons_spark2.ogg");
SOUND(ONS_SHOCKWAVE, "onslaught/shockwave.ogg");

SOUND(PORTO_BOUNCE, "porto/bounce.ogg");
SOUND(PORTO_CREATE, "porto/create.ogg");
SOUND(PORTO_EXPIRE, "porto/expire.ogg");
SOUND(PORTO_EXPLODE, "porto/explode.ogg");
SOUND(PORTO_FIRE, "porto/fire.ogg");
SOUND(PORTO_UNSUPPORTED, "porto/unsupported.ogg");

SOUND(TUR_PHASER, "turrets/phaser.ogg");

SOUND(VEH_ALARM, "vehicles/alarm.wav");
SOUND(VEH_ALARM_SHIELD, "vehicles/alarm_shield.wav");
SOUND(VEH_MISSILE_ALARM, "vehicles/missile_alarm.wav");

SOUND(VEH_BUMBLEBEE_FIRE, W_Sound("flacexp3"));

SOUND(VEH_RACER_BOOST, "vehicles/racer_boost.wav");
SOUND(VEH_RACER_IDLE, "vehicles/racer_idle.wav");
SOUND(VEH_RACER_MOVE, "vehicles/racer_move.wav");

SOUND(VEH_RAPTOR_FLY, "vehicles/raptor_fly.wav");
SOUND(VEH_RAPTOR_SPEED, "vehicles/raptor_speed.wav");

SOUND(VEH_SPIDERBOT_DIE, "vehicles/spiderbot_die.wav");
SOUND(VEH_SPIDERBOT_IDLE, "vehicles/spiderbot_idle.wav");
SOUND(VEH_SPIDERBOT_JUMP, "vehicles/spiderbot_jump.wav");
SOUND(VEH_SPIDERBOT_LAND, "vehicles/spiderbot_land.wav");
SOUND(VEH_SPIDERBOT_STRAFE, "vehicles/spiderbot_strafe.wav");
SOUND(VEH_SPIDERBOT_WALK, "vehicles/spiderbot_walk.wav");

SOUND(NADE_BEEP, "overkill/grenadebip.ogg");

SOUND(BUFF_LOST, "relics/relic_effect.wav");

SOUND(POWEROFF, "misc/poweroff.wav");
SOUND(POWERUP, "misc/powerup.ogg");
SOUND(SHIELD_RESPAWN, "misc/shield_respawn.wav");
SOUND(STRENGTH_RESPAWN, "misc/strength_respawn.wav");

SOUND(ARMOR25, "misc/armor25.wav");
SOUND(ARMORIMPACT, "misc/armorimpact.wav");
SOUND(BODYIMPACT1, "misc/bodyimpact1.wav");
SOUND(BODYIMPACT2, "misc/bodyimpact2.wav");

SOUND(ITEMPICKUP, "misc/itempickup.ogg");
SOUND(ITEMRESPAWNCOUNTDOWN, "misc/itemrespawncountdown.ogg");
SOUND(ITEMRESPAWN, "misc/itemrespawn.ogg");
SOUND(MEGAHEALTH, "misc/megahealth.ogg");

SOUND(LAVA, "player/lava.wav");
SOUND(SLIME, "player/slime.wav");

SOUND(GIB, "misc/gib.wav");
SOUND(GIB_SPLAT01, "misc/gib_splat01.wav");
SOUND(GIB_SPLAT02, "misc/gib_splat02.wav");
SOUND(GIB_SPLAT03, "misc/gib_splat03.wav");
SOUND(GIB_SPLAT04, "misc/gib_splat04.wav");
Sound SND_GIB_SPLAT_RANDOM() {
    return SOUNDS[SND_GIB_SPLAT01.m_id + floor(prandom() * 4)];
}

SOUND(HIT, "misc/hit.wav");
SOUND(TYPEHIT, "misc/typehit.wav");

SOUND(SPAWN, "misc/spawn.ogg");

SOUND(TALK, "misc/talk.wav");

SOUND(TELEPORT, "misc/teleport.ogg");

SOUND(INVSHOT, "misc/invshot.wav");

SOUND(JETPACK_FLY, "misc/jetpack_fly.ogg");
