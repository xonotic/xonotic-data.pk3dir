EFFECT(0, NADE_EXPLODE_RED,         "nade_red_explode")
EFFECT(0, NADE_EXPLODE_BLUE,        "nade_blue_explode")
EFFECT(0, NADE_EXPLODE_YELLOW,      "nade_yellow_explode")
EFFECT(0, NADE_EXPLODE_PINK,        "nade_pink_explode")
EFFECT(0, NADE_EXPLODE_NEUTRAL,     "nade_neutral_explode")
entity EFFECT_NADE_EXPLODE(int teamid)
{
    switch (teamid) {
        case NUM_TEAM_1:    return EFFECT_NADE_EXPLODE_RED;
        case NUM_TEAM_2:    return EFFECT_NADE_EXPLODE_BLUE;
        case NUM_TEAM_3:    return EFFECT_NADE_EXPLODE_YELLOW;
        case NUM_TEAM_4:    return EFFECT_NADE_EXPLODE_PINK;
        default:		    return EFFECT_NADE_EXPLODE_NEUTRAL;
    }
}

EFFECT(1, NADE_TRAIL_RED,           "nade_red")
EFFECT(1, NADE_TRAIL_BLUE,          "nade_blue")
EFFECT(1, NADE_TRAIL_YELLOW,        "nade_yellow")
EFFECT(1, NADE_TRAIL_PINK,          "nade_pink")
EFFECT(1, NADE_TRAIL_NEUTRAL,       "nade_neutral")
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
