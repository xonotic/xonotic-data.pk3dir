#pragma once

// Global list of sounds
// TODO: remove uses of _sound

#include "../teams.qh"
string W_Sound(string w_snd);
string Item_Sound(string it_snd);

SOUND(DRYFIRE, W_Sound("dryfire"));
SOUND(GRENADE_BOUNCE1, W_Sound("grenade_bounce1"));
SOUND(GRENADE_BOUNCE2, W_Sound("grenade_bounce2"));
SOUND(GRENADE_BOUNCE3, W_Sound("grenade_bounce3"));
SOUND(GRENADE_BOUNCE4, W_Sound("grenade_bounce4"));
SOUND(GRENADE_BOUNCE5, W_Sound("grenade_bounce5"));
SOUND(GRENADE_BOUNCE6, W_Sound("grenade_bounce6"));
Sound SND_GRENADE_BOUNCE_RANDOM() {
    return REGISTRY_GET(Sounds, SND_GRENADE_BOUNCE1.m_id + rint(random() * 5));
}

SOUND(LASERIMPACT, W_Sound("laserimpact"));
SOUND(NEXWHOOSH1, W_Sound("nexwhoosh1"));
SOUND(NEXWHOOSH2, W_Sound("nexwhoosh2"));
SOUND(NEXWHOOSH3, W_Sound("nexwhoosh3"));
Sound SND_NEXWHOOSH_RANDOM() {
    return REGISTRY_GET(Sounds, SND_NEXWHOOSH1.m_id + rint(random() * 2));
}
SOUND(RELOAD, W_Sound("reload")); // until weapons have individual reload sounds, precache the reload sound here

SOUND(RIC1, W_Sound("ric1"));
SOUND(RIC2, W_Sound("ric2"));
SOUND(RIC3, W_Sound("ric3"));
Sound SND_RIC_RANDOM() {
    return REGISTRY_GET(Sounds, SND_RIC1.m_id + rint(random() * 2));
}

SOUND(ROCKET_IMPACT, W_Sound("rocket_impact")); // heavily used as a generic explosion sound
SOUND(STRENGTH_FIRE, W_Sound("strength_fire"));
SOUND(UNAVAILABLE, W_Sound("unavailable"));
SOUND(WEAPONPICKUP, W_Sound("weaponpickup"));
SOUND(WEAPONPICKUP_NEW_TOYS, W_Sound("weaponpickup_new_toys"));
SOUND(WEAPON_SWITCH, W_Sound("weapon_switch"));

SOUND(CTF_CAPTURE_NEUTRAL, "ctf/capture");
SOUND(CTF_CAPTURE_RED, "ctf/red_capture");
SOUND(CTF_CAPTURE_BLUE, "ctf/blue_capture");
SOUND(CTF_CAPTURE_YELLOW, "ctf/yellow_capture");
SOUND(CTF_CAPTURE_PINK, "ctf/pink_capture");
Sound SND_CTF_CAPTURE(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_CAPTURE_RED;
        case NUM_TEAM_2:    return SND_CTF_CAPTURE_BLUE;
        case NUM_TEAM_3:    return SND_CTF_CAPTURE_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_CAPTURE_PINK;
        default:            return SND_CTF_CAPTURE_NEUTRAL;
    }
}

SOUND(CTF_DROPPED_NEUTRAL,  "ctf/neutral_dropped");
SOUND(CTF_DROPPED_RED,      "ctf/red_dropped");
SOUND(CTF_DROPPED_BLUE,     "ctf/blue_dropped");
SOUND(CTF_DROPPED_YELLOW,   "ctf/yellow_dropped");
SOUND(CTF_DROPPED_PINK,     "ctf/pink_dropped");
Sound SND_CTF_DROPPED(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_DROPPED_RED;
        case NUM_TEAM_2:    return SND_CTF_DROPPED_BLUE;
        case NUM_TEAM_3:    return SND_CTF_DROPPED_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_DROPPED_PINK;
        default:            return SND_CTF_DROPPED_NEUTRAL;
    }
}

SOUND(CTF_PASS, "ctf/pass");
SOUND(CTF_RESPAWN, "ctf/flag_respawn");

SOUND(CTF_RETURNED_NEUTRAL,  "ctf/return");
SOUND(CTF_RETURNED_RED,      "ctf/red_returned");
SOUND(CTF_RETURNED_BLUE,     "ctf/blue_returned");
SOUND(CTF_RETURNED_YELLOW,   "ctf/yellow_returned");
SOUND(CTF_RETURNED_PINK,     "ctf/pink_returned");
Sound SND_CTF_RETURNED(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_RETURNED_RED;
        case NUM_TEAM_2:    return SND_CTF_RETURNED_BLUE;
        case NUM_TEAM_3:    return SND_CTF_RETURNED_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_RETURNED_PINK;
        default:            return SND_CTF_RETURNED_NEUTRAL;
    }
}

SOUND(CTF_TAKEN_NEUTRAL,  "ctf/neutral_taken");
SOUND(CTF_TAKEN_RED,      "ctf/red_taken");
SOUND(CTF_TAKEN_BLUE,     "ctf/blue_taken");
SOUND(CTF_TAKEN_YELLOW,   "ctf/yellow_taken");
SOUND(CTF_TAKEN_PINK,     "ctf/pink_taken");
Sound SND_CTF_TAKEN(int teamid) {
    switch (teamid) {
        case NUM_TEAM_1:    return SND_CTF_TAKEN_RED;
        case NUM_TEAM_2:    return SND_CTF_TAKEN_BLUE;
        case NUM_TEAM_3:    return SND_CTF_TAKEN_YELLOW;
        case NUM_TEAM_4:    return SND_CTF_TAKEN_PINK;
        default:            return SND_CTF_TAKEN_NEUTRAL;
    }
}

SOUND(CTF_TOUCH, "ctf/touch");

SOUND(DOM_CLAIM, "domination/claim");

SOUND(KA_DROPPED, "keepaway/dropped");
SOUND(KA_PICKEDUP, "keepaway/pickedup");
SOUND(KA_RESPAWN, "keepaway/respawn");
SOUND(KA_TOUCH, "keepaway/touch");

SOUND(KH_ALARM, "kh/alarm");
SOUND(KH_CAPTURE, "kh/capture");
SOUND(KH_COLLECT, "kh/collect");
SOUND(KH_DESTROY, "kh/destroy");
SOUND(KH_DROP, "kh/drop");

SOUND(NB_BOUNCE, "nexball/bounce");
SOUND(NB_DROP, "nexball/drop");
SOUND(NB_SHOOT1, "nexball/shoot1");
SOUND(NB_SHOOT2, "nexball/shoot2");
SOUND(NB_STEAL, "nexball/steal");

SOUND(ONS_CONTROLPOINT_BUILD, "onslaught/controlpoint_build");
SOUND(ONS_CONTROLPOINT_BUILT, "onslaught/controlpoint_built");
SOUND(ONS_CONTROLPOINT_UNDERATTACK, "onslaught/controlpoint_underattack");
SOUND(ONS_DAMAGEBLOCKEDBYSHIELD, "onslaught/damageblockedbyshield");
SOUND(ONS_ELECTRICITY_EXPLODE, "onslaught/electricity_explode");
#define SND_ONS_GENERATOR_ALARM SND_KH_ALARM
//SOUND(ONS_GENERATOR_ALARM, "kh/alarm"); // FIXME: unique sound
SOUND(ONS_GENERATOR_DECAY, "onslaught/generator_decay");
SOUND(ONS_GENERATOR_UNDERATTACK, "onslaught/generator_underattack");
SOUND(ONS_GENERATOR_EXPLODE, W_Sound("grenade_impact"));
SOUND(ONS_HIT1, "onslaught/ons_hit1");
SOUND(ONS_HIT2, "onslaught/ons_hit2");
SOUND(ONS_SPARK1, "onslaught/ons_spark1");
SOUND(ONS_SPARK2, "onslaught/ons_spark2");
SOUND(ONS_SHOCKWAVE, "onslaught/shockwave");

SOUND(MON_GOLEM_LIGHTNING_IMPACT, W_Sound("electro_impact"));

SOUND(FLACEXP1, W_Sound("hagexp1"));
SOUND(FLACEXP2, W_Sound("hagexp2"));
SOUND(FLACEXP3, W_Sound("hagexp3"));
Sound SND_FLACEXP_RANDOM() {
    return REGISTRY_GET(Sounds, SND_FLACEXP1.m_id + rint(random() * 2));
}
SOUND(TUR_PHASER, "turrets/phaser");
SOUND(TUR_PLASMA_IMPACT, W_Sound("electro_impact"));
SOUND(TUR_WALKER_FIRE, W_Sound("hagar_fire"));

SOUND(VEH_ALARM, "vehicles/alarm");
SOUND(VEH_ALARM_SHIELD, "vehicles/alarm_shield");
SOUND(VEH_MISSILE_ALARM, "vehicles/missile_alarm");

SOUND(VEH_BUMBLEBEE_FIRE, W_Sound("flacexp3"));
SOUND(VEH_BUMBLEBEE_IMPACT, W_Sound("fireball_impact2"));

SOUND(VEH_RACER_BOOST, "vehicles/racer_boost");
SOUND(VEH_RACER_IDLE, "vehicles/racer_idle");
SOUND(VEH_RACER_MOVE, "vehicles/racer_move");
SOUND(VEH_RACER_ROCKET_FLY, W_Sound("tag_rocket_fly"));

SOUND(VEH_RAPTOR_FLY, "vehicles/raptor_fly");
SOUND(VEH_RAPTOR_SPEED, "vehicles/raptor_speed");

SOUND(VEH_SPIDERBOT_DIE, "vehicles/spiderbot_die");
SOUND(VEH_SPIDERBOT_IDLE, "vehicles/spiderbot_idle");
SOUND(VEH_SPIDERBOT_JUMP, "vehicles/spiderbot_jump");
SOUND(VEH_SPIDERBOT_LAND, "vehicles/spiderbot_land");
SOUND(VEH_SPIDERBOT_STRAFE, "vehicles/spiderbot_strafe");
SOUND(VEH_SPIDERBOT_WALK, "vehicles/spiderbot_walk");
SOUND(VEH_SPIDERBOT_MINIGUN_FIRE, W_Sound("uzi_fire"));
SOUND(VEH_SPIDERBOT_ROCKET_FLY, W_Sound("tag_rocket_fly"));
SOUND(VEH_SPIDERBOT_ROCKET_FIRE, W_Sound("rocket_fire"));

SOUND(NADE_BEEP, "overkill/grenadebip");
 // FIXME: unique sounds
#define SND_NADE_BONUS SND_KH_ALARM
//SOUND(NADE_BONUS, "kh/alarm");
#define SND_NADE_NAPALM_FIRE SND_FIREBALL_FIRE
//SOUND(NADE_NAPALM_FIRE, W_Sound("fireball_fire"));
#define SND_NADE_NAPALM_FLY SND_FIREBALL_FLY2
//SOUND(NADE_NAPALM_FLY, W_Sound("fireball_fly2"));

SOUND(BUFF_LOST, "relics/relic_effect");

SOUND(POWEROFF, Item_Sound("poweroff"));
SOUND(POWERUP, Item_Sound("powerup"));
SOUND(SHIELD_RESPAWN, Item_Sound("shield_respawn"));
SOUND(STRENGTH_RESPAWN, Item_Sound("strength_respawn"));

SOUND(ARMOR25, Item_Sound("armor25"));
SOUND(ARMORIMPACT, "misc/armorimpact");
SOUND(BODYIMPACT1, "misc/bodyimpact1");
SOUND(BODYIMPACT2, "misc/bodyimpact2");

SOUND(ITEMPICKUP, Item_Sound("itempickup"));
SOUND(ITEMRESPAWNCOUNTDOWN, Item_Sound("itemrespawncountdown"));
SOUND(ITEMRESPAWN, Item_Sound("itemrespawn"));
SOUND(MEGAHEALTH, Item_Sound("megahealth"));

SOUND(LAVA, "player/lava");
SOUND(SLIME, "player/slime");

SOUND(GIB, "misc/gib");
SOUND(GIB_SPLAT01, "misc/gib_splat01");
SOUND(GIB_SPLAT02, "misc/gib_splat02");
SOUND(GIB_SPLAT03, "misc/gib_splat03");
SOUND(GIB_SPLAT04, "misc/gib_splat04");
Sound SND_GIB_SPLAT_RANDOM() {
    return REGISTRY_GET(Sounds, SND_GIB_SPLAT01.m_id + floor(prandom() * 4));
}

SOUND(HIT, "misc/hit");
SOUND(TYPEHIT, "misc/typehit");
SOUND(KILL, "misc/kill");

SOUND(SPAWN, "misc/spawn");

SOUND(TALK, "misc/talk");
SOUND(TALK2, "misc/talk2");

SOUND(BLIND, "misc/blind");
SOUND(TELEPORT, "misc/teleport");
SOUND(INVSHOT, "misc/invshot");
SOUND(JETPACK_FLY, "misc/jetpack_fly");
