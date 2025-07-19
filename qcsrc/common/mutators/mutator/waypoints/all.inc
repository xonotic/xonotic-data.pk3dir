/** If you register a new waypoint, make sure to add it to this list */

REGISTER_WAYPOINT(Waypoint, _("Waypoint"), "", '0 1 1', 1);
REGISTER_WAYPOINT(Helpme, _("Help me!"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(Here, _("Here"), "", '0 1 0', 1);
REGISTER_WAYPOINT(Danger, _("DANGER"), "", '1 0.5 0', 1);

const vector WP_FROZEN_COLOR = '0.25 0.9 1';
const vector WP_REVIVING_COLOR = '1 0.5 0';
REGISTER_WAYPOINT(Frozen, _("Frozen!"), "", WP_FROZEN_COLOR, 1);
REGISTER_WAYPOINT(Reviving, _("Reviving"), "", WP_REVIVING_COLOR, 1);

REGISTER_WAYPOINT(Item, _("Item"), "", '1 0 1', 1);

REGISTER_WAYPOINT(RaceCheckpoint, _("Checkpoint"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(RaceFinish, _("Finish"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(RaceStart, _("Start"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(RaceStartFinish, _("Start"), "", '1 0.5 0', 1);

REGISTER_WAYPOINT(AssaultDefend, _("Defend"), "as_defend", '1 0.5 0', 1);
REGISTER_WAYPOINT(AssaultDestroy, _("Destroy"), "as_destroy", '1 0.5 0', 1);
REGISTER_WAYPOINT(AssaultPush, _("Push"), "", '1 0.5 0', 1);

REGISTER_WAYPOINT(FlagCarrier, _("Flag carrier"), "", '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagBaseNeutral, _("White base"),  "flag_neutral_taken", '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagBaseRed,     _("Red base"),    "flag_red_taken",     '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagBaseBlue,    _("Blue base"),   "flag_blue_taken",    '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagBaseYellow,  _("Yellow base"), "flag_yellow_taken",  '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagBasePink,    _("Pink base"),   "flag_pink_taken",    '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagDroppedNeutral, _("Dropped flag"), "flag_neutral_lost", '1 1 1', 1);
REGISTER_WAYPOINT(FlagDroppedRed,     _("Dropped flag"), "flag_red_lost",     '1 1 1', 1);
REGISTER_WAYPOINT(FlagDroppedBlue,    _("Dropped flag"), "flag_blue_lost",    '1 1 1', 1);
REGISTER_WAYPOINT(FlagDroppedYellow,  _("Dropped flag"), "flag_yellow_lost",  '1 1 1', 1);
REGISTER_WAYPOINT(FlagDroppedPink,    _("Dropped flag"), "flag_pink_lost",    '1 1 1', 1);
REGISTER_WAYPOINT(FlagCarrierEnemyNeutral, _("Enemy carrier"), "flag_neutral_carrying", '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagCarrierEnemyRed,     _("Enemy carrier"), "flag_red_carrying",     '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagCarrierEnemyBlue,    _("Enemy carrier"), "flag_blue_carrying",    '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagCarrierEnemyYellow,  _("Enemy carrier"), "flag_yellow_carrying",  '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagCarrierEnemyPink,    _("Enemy carrier"), "flag_pink_carrying",    '0.8 0.8 0', 1);
REGISTER_WAYPOINT(FlagReturn, _("Return flag here"), "", '0 0.8 0.8', 1);

REGISTER_WAYPOINT(DomNeut, _("Control point"), "dom_icon_neutral-highlighted", '0 1 1', 1);
REGISTER_WAYPOINT(DomRed, _("Control point"), "dom_icon_red-highlighted", '0 1 1', 1);
REGISTER_WAYPOINT(DomBlue, _("Control point"), "dom_icon_blue-highlighted", '0 1 1', 1);
REGISTER_WAYPOINT(DomYellow, _("Control point"), "dom_icon_yellow-highlighted", '0 1 1', 1);
REGISTER_WAYPOINT(DomPink, _("Control point"), "dom_icon_pink-highlighted", '0 1 1', 1);

REGISTER_WAYPOINT(KeyDropped, _("Dropped key"), "kh_dropped", '0 1 1', 1);
REGISTER_WAYPOINT(KeyCarrierFriend, _("Key carrier"), "", '0 1 0', 1);
REGISTER_WAYPOINT(KeyCarrierFinish, _("Run here"), "", '0 1 1', 1);
REGISTER_WAYPOINT(KeyCarrierRed, _("Key carrier"), "kh_red_carrying", '0 1 1', 1);
REGISTER_WAYPOINT(KeyCarrierBlue, _("Key carrier"), "kh_blue_carrying", '0 1 1', 1);
REGISTER_WAYPOINT(KeyCarrierYellow, _("Key carrier"), "kh_yellow_carrying", '0 1 1', 1);
REGISTER_WAYPOINT(KeyCarrierPink, _("Key carrier"), "kh_pink_carrying", '0 1 1', 1);

REGISTER_WAYPOINT(KaBall, _("Ball"), "notify_ballpickedup", '0 1 1', 1);
REGISTER_WAYPOINT(KaBallCarrier, _("Ball carrier"), "keepawayball_carrying", '1 0 0', 1);
REGISTER_WAYPOINT(TkaBallCarrierRed, _("Ball carrier"), "tka_taken_red", '0 1 1', 1);
REGISTER_WAYPOINT(TkaBallCarrierBlue, _("Ball carrier"), "tka_taken_blue", '0 1 1', 1);
REGISTER_WAYPOINT(TkaBallCarrierYellow, _("Ball carrier"), "tka_taken_yellow", '0 1 1', 1);
REGISTER_WAYPOINT(TkaBallCarrierPink, _("Ball carrier"), "tka_taken_pink", '0 1 1', 1);

REGISTER_WAYPOINT(LmsLeader, _("Leader"), "", '0 1 1', 1);

REGISTER_WAYPOINT(NbBall, _("Ball"), "", '0.91 0.85 0.62', 1);
REGISTER_WAYPOINT(NbGoal, _("Goal"), "", '1 0.5 0', 1);

REGISTER_WAYPOINT(OnsCP, _("Control point"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(OnsCPDefend, _("Control point"), "", '1 0.5 0', 0.5);
REGISTER_WAYPOINT(OnsCPAttack, _("Control point"), "", '1 0.5 0', 2);
REGISTER_WAYPOINT(OnsGen, _("Generator"), "", '1 0.5 0', 1);
REGISTER_WAYPOINT(OnsGenShielded, _("Generator"), "", '1 0.5 0', 1);

REGISTER_WAYPOINT(Weapon, _("Weapon"), "", '0 0 0', 1);

REGISTER_WAYPOINT(Monster, _("Monster"), "", '1 0 0', 1);

REGISTER_WAYPOINT(Vehicle, _("Vehicle"), "", '1 1 1', 1);
REGISTER_WAYPOINT(VehicleIntruder, _("Intruder!"), "", '1 1 1', 1);

REGISTER_WAYPOINT(Seeker, _("Tagged"), "", '0.5 1 0', 2);

REGISTER_WAYPOINT(Buff, _("Buff"), "", '1 0.5 0', 1);
