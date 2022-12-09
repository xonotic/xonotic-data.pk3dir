#include "bot_null.qh"

#if 0
bool bot_aim(entity this, .entity weaponentity, float shotspeed, float shotspeedupward, float maxshottime, float applygravity, bool shot_accurate) { return false; }
void bot_clientconnect(entity this) { }
void bot_clientdisconnect(entity this) { }
void bot_cmdhelp(string scmd) { }
void bot_endgame() { }
bool bot_fixcount(bool multiple_per_frame) { return true; }
void bot_list_commands() { }
void bot_queuecommand(entity bot, string cmdstring) { }
void bot_relinkplayerlist() { }
void bot_resetqueues() { }
void bot_serverframe() { }
bool bot_shouldattack(entity this, entity e) { return false; }
void bot_think(entity this) { }

entity find_bot_by_name(string name) { return NULL; }
entity find_bot_by_number(float number) { return NULL; }

void havocbot_goalrating_enemyplayers(entity this, float ratingscale, vector org, float sradius) { }
void havocbot_goalrating_items(entity this, float ratingscale, vector org, float sradius) { }

entity navigation_findnearestwaypoint(entity ent, float walkfromwp) { return NULL; }
void navigation_goalrating_end(entity this) { }
void navigation_goalrating_start(entity this) { }
void navigation_markroutes(entity this, entity fixed_source_waypoint) { }
void navigation_markroutes_inverted(entity fixed_source_waypoint) { }
void navigation_routerating(entity this, entity e, float f, float rangebias) { }

bool tracewalk(entity e, vector start, vector m1, vector m2, vector end, float end_height, float movemode) { return false; }

void waypoint_remove_fromeditor(entity pl) { }
void waypoint_remove(entity wp) { }
void waypoint_saveall() { }
void waypoint_schedulerelinkall() { }
void waypoint_schedulerelink(entity wp) { }
void waypoint_spawnforitem(entity e) { }
void waypoint_spawnforitem_force(entity e, vector org) { }
void waypoint_spawnforteleporter(entity e, vector destination, float timetaken, entity tracetest_ent) { }
void waypoint_spawnforteleporter_wz(entity e, entity tracetest_ent) { }
void waypoint_spawn_fromeditor(entity pl, bool at_crosshair, bool is_jump_wp, bool is_crouch_wp, bool is_support_wp) { }
entity waypoint_spawn(vector m1, vector m2, float f) { return NULL; }
#endif
