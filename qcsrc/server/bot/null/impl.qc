bool bot_aim(float shotspeed, float shotspeedupward, float maxshottime, float applygravity) { return false; }
void bot_clientconnect() { }
void bot_clientdisconnect() { }
void bot_cmdhelp(string scmd) { }
void bot_endgame() { }
bool bot_fixcount() { return true; }
void bot_list_commands() { }
void bot_queuecommand(entity bot, string cmdstring) { }
void bot_relinkplayerlist() { }
void bot_resetqueues() { }
void bot_serverframe() { }
bool bot_shouldattack(entity e) { return false; }
void bot_think() { }

entity find_bot_by_name(string name) { return NULL; }
entity find_bot_by_number(float number) { return NULL; }

void havocbot_goalrating_controlpoints(float ratingscale, vector org, float sradius) { }
void havocbot_goalrating_enemyplayers(float ratingscale, vector org, float sradius) { }
void havocbot_goalrating_items(float ratingscale, vector org, float sradius) { }

entity navigation_findnearestwaypoint(entity ent, float walkfromwp) { return NULL; }
void navigation_goalrating_end() { }
void navigation_goalrating_start() { }
void navigation_markroutes(entity fixed_source_waypoint) { }
void navigation_markroutes_inverted(entity fixed_source_waypoint) { }
void navigation_routerating(entity e, float f, float rangebias) { }

bool tracewalk(entity e, vector start, vector m1, vector m2, vector end, float movemode) { return false; }

void waypoint_remove(entity e) { }
void waypoint_saveall() { }
void waypoint_schedulerelinkall() { }
void waypoint_schedulerelink(entity wp) { }
void waypoint_spawnforitem(entity e) { }
void waypoint_spawnforitem_force(entity e, vector org) { }
void waypoint_spawnforteleporter(entity e, vector destination, float timetaken) { }
void waypoint_spawnforteleporter_v(entity e, vector org, vector destination, float timetaken) { }
entity waypoint_spawn(vector m1, vector m2, float f) { return NULL; }
