#include "map_background.qh"

int autocvar_map_background_state;
STATIC_INIT(map_background) {
    cvar_set("map_background_state", ftos(autocvar_map_background_state > 1));
}
