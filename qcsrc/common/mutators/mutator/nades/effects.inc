#include <common/effects/all.qh>

// XONRELEASE TODO v0.9.0 post-release: remove the effect definitions from effectinfo.txt
// XONRELEASE TODO v0.9.0 post-release: rename brown to navy
//EFFECT(0, NADE_EXPLODE_RED,         "nade_red_explode")
//EFFECT(0, NADE_EXPLODE_BLUE,        "nade_blue_explode")
//EFFECT(0, NADE_EXPLODE_YELLOW,      "nade_yellow_explode")
//EFFECT(0, NADE_EXPLODE_PINK,        "nade_pink_explode")
//EFFECT(0, NADE_EXPLODE_GREEN,       "nade_green_explode")
//EFFECT(0, NADE_EXPLODE_BROWN,       "nade_brown_explode")
//EFFECT(0, NADE_EXPLODE_PURPLE,      "nade_purple_explode")
EFFECT(0, NADE_EXPLODE,             "nade_neutral_explode")

// TODO: these are used on the server side (BAD)
EFFECT(1, NADE_TRAIL_RED,           "nade_red")
EFFECT(1, NADE_TRAIL_BLUE,          "nade_blue")
EFFECT(1, NADE_TRAIL_YELLOW,        "nade_yellow")
EFFECT(1, NADE_TRAIL_PINK,          "nade_pink")
EFFECT(1, NADE_TRAIL_NEUTRAL,       "nade_neutral")
EFFECT(1, NADE_TRAIL_GREEN,         "nade_green")
EFFECT(1, NADE_TRAIL_BROWN,         "nade_brown")
EFFECT(1, NADE_TRAIL_PURPLE,        "nade_purple")
entity EFFECT_NADE_TRAIL(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_NADE_TRAIL_RED;
        case NUM_TEAM_2:    return EFFECT_NADE_TRAIL_BLUE;
        case NUM_TEAM_3:    return EFFECT_NADE_TRAIL_YELLOW;
        case NUM_TEAM_4:    return EFFECT_NADE_TRAIL_PINK;
        default:            return EFFECT_NADE_TRAIL_NEUTRAL;
    }
}

EFFECT(1, NADE_TRAIL_BURN_RED,      "nade_red_burn")
EFFECT(1, NADE_TRAIL_BURN_BLUE,     "nade_blue_burn")
EFFECT(1, NADE_TRAIL_BURN_YELLOW,   "nade_yellow_burn")
EFFECT(1, NADE_TRAIL_BURN_PINK,     "nade_pink_burn")
EFFECT(1, NADE_TRAIL_BURN_NEUTRAL,  "nade_neutral_burn")
EFFECT(1, NADE_TRAIL_BURN_BROWN,    "nade_brown_burn")
EFFECT(1, NADE_TRAIL_BURN_PURPLE,   "nade_purple_burn")
entity EFFECT_NADE_TRAIL_BURN(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_NADE_TRAIL_BURN_RED;
        case NUM_TEAM_2:    return EFFECT_NADE_TRAIL_BURN_BLUE;
        case NUM_TEAM_3:    return EFFECT_NADE_TRAIL_BURN_YELLOW;
        case NUM_TEAM_4:    return EFFECT_NADE_TRAIL_BURN_PINK;
        default:            return EFFECT_NADE_TRAIL_BURN_NEUTRAL;
    }
}
