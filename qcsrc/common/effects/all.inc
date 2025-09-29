#pragma once
// Global list of effects, networked to CSQC by ID to save bandwidth and to use client particle numbers (allows mismatching effectinfos to some degree)
// Not too concerned about the order of this list, just keep the weapon effects together!

#include "../teams.qh"

// EFFECT(istrail, EFFECT_NAME,     "effectinfo_string")
EFFECT(0, EXPLOSION_SMALL,          "explosion_small")
EFFECT(0, EXPLOSION_MEDIUM,         "explosion_medium")
EFFECT(0, EXPLOSION_BIG,            "explosion_big")

EFFECT(0, SMOKE_SMALL,              "smoke_small")
EFFECT(0, SMOKE_LARGE,              "smoke_large")


EFFECT(0, ARC_MUZZLEFLASH,          "electro_muzzleflash")

EFFECT(0, BLASTER_IMPACT,           "laser_impact")
EFFECT(0, BLASTER_MUZZLEFLASH,      "laser_muzzleflash")

EFFECT(0, SHOTGUN_IMPACT,           "shotgun_impact")
EFFECT(0, SHOTGUN_MUZZLEFLASH,      "shotgun_muzzleflash")
EFFECT(0, SHOTGUN_WOOSH,            "shotgun_woosh")

EFFECT(0, ARC_BEAM,                 "arc_beam")
EFFECT(0, ARC_BEAM_HEAL,            "arc_beam_heal")
EFFECT(0, ARC_BEAM_HEAL_IMPACT,     "arc_beam_healimpact")
EFFECT(0, ARC_BEAM_HEAL_IMPACT2,    "healray_impact")
// TODO: effect needs updating
//EFFECT(0, ARC_BOLT_EXPLODE,         "arc_bolt_explode")
EFFECT(0, ARC_OVERHEAT,             "arc_overheat")
EFFECT(0, ARC_OVERHEAT_FIRE,        "arc_overheat_fire")
EFFECT(0, ARC_SMOKE,                "arc_smoke")
EFFECT(0, ARC_LIGHTNING,            "arc_lightning")
//EFFECT(0, ARC_LIGHTNING2,           "electro_lightning")

EFFECT(0, MACHINEGUN_IMPACT,        "machinegun_impact")
EFFECT(0, MACHINEGUN_MUZZLEFLASH,   "uzi_muzzleflash")

EFFECT(0, GRENADE_EXPLODE,          "grenade_explode")
EFFECT(0, GRENADE_MUZZLEFLASH,      "grenadelauncher_muzzleflash")

EFFECT(0, ELECTRO_BALLEXPLODE,      "electro_ballexplode")
EFFECT(0, ELECTRO_COMBO,            "electro_combo")
EFFECT(0, ELECTRO_IMPACT,           "electro_impact")
EFFECT(0, ELECTRO_MUZZLEFLASH,      "electro_muzzleflash")

EFFECT(0, CRYLINK_IMPACT,           "crylink_impactbig")
EFFECT(0, CRYLINK_IMPACT2,          "crylink_impact")
EFFECT(0, CRYLINK_JOINEXPLODE,      "crylink_joinexplode")
EFFECT(0, CRYLINK_MUZZLEFLASH,      "crylink_muzzleflash")

// TODO: rename GREEN_HLAC_* to HLAC_* after next release (xonotic-v0.9.0)
// see also common/weapons/weapon/hlac.q*
EFFECT(0, GREEN_HLAC_IMPACT,        "hlac_impact")
EFFECT(0, GREEN_HLAC_MUZZLEFLASH,   "hlac_muzzleflash")

EFFECT(0, VORTEX_BEAM,              "nex_beam")
EFFECT(0, VORTEX_BEAM_OLD,          "TE_TEI_G3")
EFFECT(0, VORTEX_IMPACT,            "nex_impact")
EFFECT(0, VORTEX_MUZZLEFLASH,       "nex_muzzleflash")

// TODO: remove the effect definitions from effectinfo.txt post-release (xonotic-v0.9.0)
//EFFECT(1, VAPORIZER_RED,            "TE_TEI_G3RED")
//EFFECT(1, VAPORIZER_HIT_RED,        "TE_TEI_G3RED_HIT")
//EFFECT(1, VAPORIZER_BLUE,           "TE_TEI_G3BLUE")
//EFFECT(1, VAPORIZER_HIT_BLUE,       "TE_TEI_G3BLUE_HIT")
//EFFECT(1, VAPORIZER_YELLOW,         "TE_TEI_G3YELLOW")
//EFFECT(1, VAPORIZER_HIT_YELLOW,     "TE_TEI_G3YELLOW_HIT")
//EFFECT(1, VAPORIZER_PINK,           "TE_TEI_G3PINK")
//EFFECT(1, VAPORIZER_HIT_PINK,       "TE_TEI_G3PINK_HIT")
EFFECT(1, VAPORIZER_BEAM,           "TE_TEI_G3")
EFFECT(1, VAPORIZER_BEAM_HIT,       "TE_TEI_G3_HIT")

EFFECT(0, RIFLE_IMPACT,             "machinegun_impact")
EFFECT(0, RIFLE_MUZZLEFLASH,        "rifle_muzzleflash")
EFFECT(1, RIFLE,                    "tr_rifle")
EFFECT(1, RIFLE_WEAK,               "tr_rifle_weak")

EFFECT(0, HAGAR_BOUNCE,             "hagar_bounce")
EFFECT(0, HAGAR_EXPLODE,            "hagar_explode")
EFFECT(0, HAGAR_MUZZLEFLASH,        "hagar_muzzleflash")
EFFECT(1, HAGAR_ROCKET,             "tr_hagar")

EFFECT(0, ROCKET_EXPLODE,           "rocket_explode")
EFFECT(0, ROCKET_GUIDE,             "rocket_guide")
EFFECT(0, ROCKET_MUZZLEFLASH,       "rocketlauncher_muzzleflash")

EFFECT(0, HOOK_EXPLODE,             "hookbomb_explode")
EFFECT(0, HOOK_IMPACT,              "grapple_impact")
EFFECT(0, HOOK_MUZZLEFLASH,         "grapple_muzzleflash")

EFFECT(0, SEEKER_MUZZLEFLASH,       "seeker_muzzleflash")

EFFECT(1, FIREBALL,                 "fireball")
EFFECT(0, FIREBALL_BFGDAMAGE,       "fireball_bfgdamage")
EFFECT(0, FIREBALL_EXPLODE,         "fireball_explode")
EFFECT(0, FIREBALL_LASER,           "fireball_laser")
EFFECT(0, FIREBALL_MUZZLEFLASH,     "fireball_muzzleflash")
EFFECT(0, FIREBALL_PRE_MUZZLEFLASH, "fireball_preattack_muzzleflash")



EFFECT(0, RAPTOR_CANNON_IMPACT,     "raptor_cannon_impact")
EFFECT(0, RAPTOR_BOMB_IMPACT,       "raptor_bomb_impact")
EFFECT(0, RAPTOR_BOMB_SPREAD,       "raptor_bomb_spread")
EFFECT(0, RAPTOR_MUZZLEFLASH,       "raptor_cannon_muzzleflash")

EFFECT(0, RACER_BOOSTER,            "wakizashi_booster_smoke")
EFFECT(0, RACER_IMPACT,             "wakizashi_gun_impact")
EFFECT(0, RACER_MUZZLEFLASH,        "wakizashi_gun_muzzleflash")
EFFECT(0, RACER_ROCKETLAUNCH,       "wakizashi_rocket_launch")
EFFECT(0, RACER_ROCKET_EXPLODE,     "wakizashi_rocket_explode")
EFFECT(1, RACER_ROCKET_TRAIL,       "wakizashi_rocket_thrust")

EFFECT(0, SPIDERBOT_ROCKETLAUNCH,           "spiderbot_rocket_launch")
EFFECT(1, SPIDERBOT_ROCKET_TRAIL,           "spiderbot_rocket_thrust")
EFFECT(0, SPIDERBOT_ROCKET_EXPLODE,         "spiderbot_rocket_explode")
EFFECT(0, SPIDERBOT_MINIGUN_IMPACT,         "spiderbot_minigun_impact")
EFFECT(0, SPIDERBOT_MINIGUN_MUZZLEFLASH,    "spiderbot_minigun_muzzleflash")

EFFECT(0, BUMBLEBEE_HEAL_MUZZLEFLASH,   "healray_muzzleflash")
EFFECT(0, BUMBLEBEE_HEAL_IMPACT,        "healray_impact")

EFFECT(0, BIGPLASMA_IMPACT,         "bigplasma_impact")
EFFECT(0, BIGPLASMA_MUZZLEFLASH,    "bigplasma_muzzleflash")

EFFECT(0, TELEPORT,                 "teleport")

// TODO: remove the effect definitions from effectinfo.txt post-release (xonotic-v0.9.0)
//EFFECT(0, SPAWNPOINT_RED,           "spawn_point_red")
//EFFECT(0, SPAWNPOINT_BLUE,          "spawn_point_blue")
//EFFECT(0, SPAWNPOINT_YELLOW,        "spawn_point_yellow")
//EFFECT(0, SPAWNPOINT_PINK,          "spawn_point_pink")
//EFFECT(0, SPAWN_RED,                "spawn_event_red")
//EFFECT(0, SPAWN_BLUE,               "spawn_event_blue")
//EFFECT(0, SPAWN_YELLOW,             "spawn_event_yellow")
//EFFECT(0, SPAWN_PINK,               "spawn_event_pink")
//EFFECT(0, SPAWN_GREEN,              "spawn_event_green")
//EFFECT(0, SPAWN_BROWN,              "spawn_event_brown")
//EFFECT(0, SPAWN_PURPLE,             "spawn_event_purple")
EFFECT(0, SPAWNPOINT,               "spawn_point_neutral")
EFFECT(0, SPAWN,                    "spawn_event_neutral")

EFFECT(0, DARKFIELD,                "darkfield")
EFFECT(0, ICEORGLASS,               "iceorglass")
EFFECT(0, ICEFIELD,                 "icefield")
EFFECT(0, FIREFIELD,                "firefield")
EFFECT(0, HEALING,                  "healing_fx")
EFFECT(0, ARMOR_REPAIR,             "armorrepair_fx")
EFFECT(0, AMMO_REGEN,               "ammoregen_fx")
EFFECT(1, LASER_BEAM_FAST,          "nex242_misc_laser_beam_fast")
EFFECT(0, RESPAWN_GHOST,            "respawn_ghost")

// TODO: ctf effects are server side (BAD)
EFFECT(0, FLAG_TOUCH_RED,           "redflag_touch")
EFFECT(0, FLAG_TOUCH_BLUE,          "blueflag_touch")
EFFECT(0, FLAG_TOUCH_YELLOW,        "yellowflag_touch")
EFFECT(0, FLAG_TOUCH_PINK,          "pinkflag_touch")
EFFECT(0, FLAG_TOUCH_NEUTRAL,       "neutralflag_touch")
entity EFFECT_FLAG_TOUCH(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_FLAG_TOUCH_RED;
        case NUM_TEAM_2:    return EFFECT_FLAG_TOUCH_BLUE;
        case NUM_TEAM_3:    return EFFECT_FLAG_TOUCH_YELLOW;
        case NUM_TEAM_4:    return EFFECT_FLAG_TOUCH_PINK;
        default:            return EFFECT_FLAG_TOUCH_NEUTRAL;
    }
}

EFFECT(1, PASS_RED,                 "red_pass")
EFFECT(1, PASS_BLUE,                "blue_pass")
EFFECT(1, PASS_YELLOW,              "yellow_pass")
EFFECT(1, PASS_PINK,                "pink_pass")
EFFECT(1, PASS_NEUTRAL,             "neutral_pass")
entity EFFECT_PASS(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_PASS_RED;
        case NUM_TEAM_2:    return EFFECT_PASS_BLUE;
        case NUM_TEAM_3:    return EFFECT_PASS_YELLOW;
        case NUM_TEAM_4:    return EFFECT_PASS_PINK;
        default:            return EFFECT_PASS_NEUTRAL;
    }
}

EFFECT(0, CAP_RED,                  "red_cap")
EFFECT(0, CAP_BLUE,                 "blue_cap")
EFFECT(0, CAP_YELLOW,               "yellow_cap")
EFFECT(0, CAP_PINK,                 "pink_cap")
EFFECT(0, CAP_NEUTRAL,              "neutral_cap")
entity EFFECT_CAP(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_CAP_RED;
        case NUM_TEAM_2:    return EFFECT_CAP_BLUE;
        case NUM_TEAM_3:    return EFFECT_CAP_YELLOW;
        case NUM_TEAM_4:    return EFFECT_CAP_PINK;
        default:            return EFFECT_CAP_NEUTRAL;
    }
}

EFFECT(0, ITEM_PICKUP,              "item_pickup")
EFFECT(0, ITEM_RESPAWN,             "item_respawn")
EFFECT(0, ITEM_DESPAWN,             "item_despawn")

// FIXME: needs custom effect
EFFECT(0, ONS_ELECTRICITY_EXPLODE,  "electro_ballexplode")
EFFECT(0, ONS_GENERATOR_DAMAGED,    "torch_small")
EFFECT(0, ONS_GENERATOR_GIB,        "onslaught_generator_gib_explode")
EFFECT(0, ONS_GENERATOR_EXPLODE,    "onslaught_generator_smallexplosion")
EFFECT(0, ONS_GENERATOR_EXPLODE2,   "onslaught_generator_finalexplosion")
// FIXME: needs custom effect
EFFECT(0, ONS_SHOCKWAVE,            "electro_combo")

// FIXME: needs custom effect
EFFECT(0, KA_BALL_RESPAWN,          "electro_combo")


EFFECT(0, LASER_DEADLY,             "laser_deadly")
EFFECT(1, FLAC_TRAIL,               "TR_SEEKER")
EFFECT(1, SEEKER_TRAIL,             "TR_SEEKER")
EFFECT(1, FIREMINE,                 "firemine")
EFFECT(0, BALL_SPARKS,              "kaball_sparks")
EFFECT(0, ELECTRIC_SPARKS,          "electricity_sparks")
EFFECT(0, SPARKS,                   "sparks")
EFFECT(0, RAGE,                     "rage")
EFFECT(0, SMOKING,                  "smoking")
EFFECT(0, SMOKE_RING,               "smoke_ring")
EFFECT(0, JUMPPAD,                  "jumppad_activate")
EFFECT(1, BULLET,                   "tr_bullet")
EFFECT(1, BULLET_WEAK,              "tr_bullet_weak")
EFFECT(0, EF_SHOCK,                 "EF_SHOCK")
EFFECT(0, EF_FLAME,                 "EF_FLAME")
EFFECT(0, EF_STARDUST,              "EF_STARDUST")
EFFECT(0, TE_EXPLOSION,             "TE_EXPLOSION")
EFFECT(1, TR_NEXUIZPLASMA,          "TR_NEXUIZPLASMA")
EFFECT(1, TR_CRYLINKPLASMA,         "TR_CRYLINKPLASMA")
EFFECT(1, TR_ROCKET,                "TR_ROCKET")
EFFECT(1, TR_GRENADE,               "TR_GRENADE")
EFFECT(1, TR_BLOOD,                 "TR_BLOOD")
EFFECT(1, TR_WIZSPIKE,              "TR_WIZSPIKE")
EFFECT(1, TR_SLIGHTBLOOD,           "TR_SLIGHTBLOOD")
EFFECT(1, TR_KNIGHTSPIKE,           "TR_KNIGHTSPIKE")
EFFECT(1, TR_VORESPIKE,             "TR_VORESPIKE")
EFFECT(0, TE_SPARK,                 "TE_SPARK")

// TODO: remove the effect definitions from effectinfo.txt post-release (xonotic-v0.9.0)
//EFFECT(1, ROCKETMINSTA_LASER_RED,       "rocketminsta_laser_red")
//EFFECT(1, ROCKETMINSTA_LASER_BLUE,      "rocketminsta_laser_blue")
//EFFECT(1, ROCKETMINSTA_LASER_YELLOW,    "rocketminsta_laser_yellow")
//EFFECT(1, ROCKETMINSTA_LASER_PINK,      "rocketminsta_laser_pink")
EFFECT(1, ROCKETMINSTA_LASER,       "rocketminsta_laser_neutral")
