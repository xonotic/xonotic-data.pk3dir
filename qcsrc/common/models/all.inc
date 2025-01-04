// Global list of models
// TODO: remove uses of _setmodel

string W_Model(string w_mdl);

MODEL(CTF_SHIELD,                       "models/ctf/shield.md3");
MODEL(CTF_CAPTURE,                      "models/ctf/shockwavetransring.md3");
MODEL(CTF_FLAG,                         "models/ctf/flags.md3");

MODEL(DOM_NEUTRAL,                      "models/domination/dom_unclaimed.md3");
MODEL(DOM_RED,                          "models/domination/dom_red.md3");
MODEL(DOM_BLUE,                         "models/domination/dom_blue.md3");
MODEL(DOM_YELLOW,                       "models/domination/dom_yellow.md3");
MODEL(DOM_PINK,                         "models/domination/dom_pink.md3");

MODEL(ICE,                              "models/ice/ice.md3");

MODEL(KH_KEY,                           "models/keyhunt/key.md3");
#ifdef KH_PLAYER_USE_CARRIEDMODEL
MODEL(KH_KEY_CARRIED,                   "models/keyhunt/key-carried.md3");
#endif

MODEL(ONS_CP,                           "models/onslaught/controlpoint_icon.md3");
MODEL(ONS_CP_SHIELD,                    "models/onslaught/controlpoint_shield.md3");
MODEL(ONS_CP_PAD1,                      "models/onslaught/controlpoint_pad.md3");
MODEL(ONS_CP_PAD2,                      "models/onslaught/controlpoint_pad2.md3");
MODEL(ONS_CP1,                          "models/onslaught/controlpoint_icon_dmg1.md3");
MODEL(ONS_CP1_GIB,                      "models/onslaught/controlpoint_icon_gib1.md3");
MODEL(ONS_CP2,                          "models/onslaught/controlpoint_icon_dmg2.md3");
MODEL(ONS_CP2_GIB,                      "models/onslaught/controlpoint_icon_gib2.md3");
MODEL(ONS_CP3,                          "models/onslaught/controlpoint_icon_dmg3.md3");
MODEL(ONS_CP3_GIB,                      "models/onslaught/controlpoint_icon_gib4.md3");
MODEL(ONS_RAY,                          "models/onslaught/ons_ray.md3");
MODEL(ONS_GEN,                          "models/onslaught/generator.md3");
MODEL(ONS_GEN_SHIELD,                   "models/onslaught/generator_shield.md3");
MODEL(ONS_GEN_GIB1,                     "models/onslaught/gen_gib1.md3");
MODEL(ONS_GEN_GIB2,                     "models/onslaught/gen_gib2.md3");
MODEL(ONS_GEN_GIB3,                     "models/onslaught/gen_gib3.md3");
MODEL(ONS_GEN1,                         "models/onslaught/generator_dmg1.md3");
MODEL(ONS_GEN2,                         "models/onslaught/generator_dmg2.md3");
MODEL(ONS_GEN3,                         "models/onslaught/generator_dmg3.md3");
MODEL(ONS_GEN4,                         "models/onslaught/generator_dmg4.md3");
MODEL(ONS_GEN5,                         "models/onslaught/generator_dmg5.md3");
MODEL(ONS_GEN6,                         "models/onslaught/generator_dmg6.md3");
MODEL(ONS_GEN7,                         "models/onslaught/generator_dmg7.md3");
MODEL(ONS_GEN8,                         "models/onslaught/generator_dmg8.md3");
MODEL(ONS_GEN9,                         "models/onslaught/generator_dmg9.md3");
MODEL(ONS_GEN_DEAD,                     "models/onslaught/generator_dead.md3");

MODEL(PROJECTILE_ELECTRO,               "models/ebomb.mdl");
MODEL(PROJECTILE_ELECTRO_BEAM,          "models/elaser.mdl");

MODEL(PROJECTILE_ROCKET,                "models/rocket.md3");

MODEL(PROJECTILE_CRYLINK,               "models/plasmatrail.mdl");
MODEL(PROJECTILE_CRYLINK_BOUNCING,      "models/plasmatrail.mdl");

MODEL(PROJECTILE_GRENADE,               "models/grenademodel.md3");
MODEL(PROJECTILE_GRENADE_BOUNCING,      "models/grenademodel.md3");

MODEL(PROJECTILE_MINE,                  "models/mine.md3");

MODEL(PROJECTILE_BLASTER,               "models/laser.mdl");

MODEL(PROJECTILE_HLAC,                  "models/hlac_bullet.md3");

MODEL(PROJECTILE_PORTO_RED,             "models/grenademodel.md3");
MODEL(PROJECTILE_PORTO_BLUE,            "models/grenademodel.md3");

MODEL(PROJECTILE_HOOKBOMB,              "models/grenademodel.md3");

MODEL(PROJECTILE_HAGAR,                 "models/hagarmissile.mdl");
MODEL(PROJECTILE_HAGAR_BOUNCING,        "models/hagarmissile.mdl");

MODEL(PROJECTILE_ARC_BOLT,              "models/ebomb.mdl");

// napalm grenade
MODEL(PROJECTILE_NAPALM_FOUNTAIN,       "null");
// fireball primary
MODEL(PROJECTILE_FIREBALL,              "null");
// fireball secondary
MODEL(PROJECTILE_FIREMINE,              "null");

MODEL(PROJECTILE_TAG,                   "models/laser.mdl");

MODEL(PROJECTILE_FLAC,                  "models/hagarmissile.mdl");

MODEL(PROJECTILE_SEEKER,                "models/tagrocket.md3");

MODEL(PROJECTILE_MAGE_SPIKE,            "models/ebomb.mdl");
MODEL(PROJECTILE_GOLEM_LIGHTNING,       "models/ebomb.mdl");

MODEL(PROJECTILE_RAPTORBOMB,            "models/vehicles/clusterbomb.md3");
MODEL(PROJECTILE_RAPTORBOMBLET,         "models/vehicles/bomblet.md3");
MODEL(PROJECTILE_RAPTORCANNON,          "models/plasmatrail.mdl");

MODEL(PROJECTILE_SPIDERROCKET,          "models/vehicles/rocket02.md3");

MODEL(PROJECTILE_WAKIROCKET,            "models/vehicles/rocket01.md3");
MODEL(PROJECTILE_WAKICANNON,            "models/laser.mdl");

MODEL(PROJECTILE_BUMBLE_GUN,            "models/elaser.mdl");
MODEL(PROJECTILE_BUMBLE_BEAM,           "models/elaser.mdl");

MODEL(PROJECTILE_RPC,                   W_Model("ok_rocket.md3"));

MODEL(PROJECTILE_ROCKETMINSTA_LASER,    "models/elaser.mdl");

MODEL(PROJECTILE_NADE,                  W_Model("v_ok_grenade.md3"));
MODEL(NADE_VIEW,                        W_Model("h_ok_grenade.iqm"));
MODEL(NADE_TIMER,                       "models/ok_nade_counter/ok_nade_counter.md3");
MODEL(NADE_ORB,                         "models/ctf/shield.md3");

MODEL(GIB_CHUNK,                        "models/gibs/chunk.mdl");
MODEL(GIB_LEG1,                         "models/gibs/leg1.md3");
MODEL(GIB_LEG2,                         "models/gibs/leg2.md3");
MODEL(GIB_CHEST,                        "models/gibs/chest.md3");
MODEL(GIB_SMALLCHEST,                   "models/gibs/smallchest.md3");
MODEL(GIB_ARM,                          "models/gibs/arm.md3");
MODEL(GIB_BLOODYSKULL,                  "models/gibs/bloodyskull.md3");
MODEL(GIB_EYE,                          "models/gibs/eye.md3");

MODEL(GIB_ROBO,                         "models/gibs/robo.md3");
MODEL(GIB_ROBO_1,                       "models/gibs/robo1.md3");
MODEL(GIB_ROBO_2,                       "models/gibs/robo2.md3");
MODEL(GIB_ROBO_3,                       "models/gibs/robo3.md3");
MODEL(GIB_ROBO_4,                       "models/gibs/robo4.md3");
MODEL(GIB_ROBO_5,                       "models/gibs/robo5.md3");
MODEL(GIB_ROBO_6,                       "models/gibs/robo6.md3");
MODEL(GIB_ROBO_7,                       "models/gibs/robo7.md3");
MODEL(GIB_ROBO_8,                       "models/gibs/robo8.md3");
Model MDL_GIB_ROBO_RANDOM() {
    int i = floor(random() * 8);
    return REGISTRY_GET(Models, MDL_GIB_ROBO_1.m_id + i);
}

MODEL(CASING_SHELL,                     "models/casing_shell.mdl");
MODEL(CASING_BULLET,                    "models/casing_bronze.iqm");

MODEL(BUFF,                             "models/relics/relic.md3");

MODEL(TUR_GIB_BASE1,                    "models/turrets/base-gib1.md3");
MODEL(TUR_GIB_BASE2,                    "models/turrets/base-gib2.md3");
MODEL(TUR_GIB_BASE3,                    "models/turrets/base-gib3.md3");
MODEL(TUR_GIB_BASE4,                    "models/turrets/base-gib4.md3");
MODEL(TUR_GIB_HEAD1,                    "models/turrets/head-gib1.md3");
MODEL(TUR_GIB_HEAD2,                    "models/turrets/head-gib2.md3");
MODEL(TUR_GIB_HEAD3,                    "models/turrets/head-gib3.md3");
MODEL(TUR_GIB_HEAD4,                    "models/turrets/head-gib4.md3");
MODEL(TUR_BASE,                         "models/turrets/base.md3");

MODEL(TUR_EWHEEL_BASE,                  "models/turrets/ewheel-base2.md3");
MODEL(TUR_EWHEEL_HEAD,                  "models/turrets/ewheel-gun1.md3");

MODEL(TUR_FLAC_BASE,                    "models/turrets/base.md3");
MODEL(TUR_FLAC_HEAD,                    "models/turrets/flac.md3");

MODEL(TUR_FUSIONREACTOR_BASE,           "models/turrets/base.md3");
MODEL(TUR_FUSIONREACTOR_HEAD,           "models/turrets/reactor.md3");

MODEL(TUR_HELLION_BASE,                 "models/turrets/base.md3");
MODEL(TUR_HELLION_HEAD,                 "models/turrets/hellion.md3");

MODEL(TUR_HK_BASE,                      "models/turrets/base.md3");
MODEL(TUR_HK_HEAD,                      "models/turrets/hk.md3");

MODEL(TUR_MACHINEGUN_BASE,              "models/turrets/base.md3");
MODEL(TUR_MACHINEGUN_HEAD,              "models/turrets/machinegun.md3");

MODEL(TUR_MIRS_BASE,                    "models/turrets/base.md3");
MODEL(TUR_MIRS_HEAD,                    "models/turrets/mlrs.md3");

MODEL(TUR_PHASER_BASE,                  "models/turrets/base.md3");
MODEL(TUR_PHASER_BEAM,                  "models/turrets/phaser_beam.md3");
MODEL(TUR_PHASER_HEAD,                  "models/turrets/phaser.md3");

MODEL(TUR_PLASMA_BASE,                  "models/turrets/base.md3");
MODEL(TUR_PLASMA_HEAD,                  "models/turrets/plasma.md3");

MODEL(TUR_PLASMA_DUAL_BASE,             "models/turrets/base.md3");
MODEL(TUR_PLASMA_DUAL_HEAD,             "models/turrets/plasmad.md3");

MODEL(TUR_TESLA_BASE,                   "models/turrets/tesla_base.md3");
MODEL(TUR_TESLA_HEAD,                   "models/turrets/tesla_head.md3");

MODEL(TUR_WALKER_BASE,                  "models/turrets/walker_body.md3");
MODEL(TUR_WALKER_HEAD,                  "models/turrets/walker_head_minigun.md3");

MODEL(VEH_SHIELD,                       "models/vhshield.md3");

MODEL(VEH_BUMBLEBEE_BODY,               "models/vehicles/bumblebee_body.dpm");
MODEL(VEH_BUMBLEBEE_CANNON_CENTER,      "models/vehicles/bumblebee_ray.dpm");
MODEL(VEH_BUMBLEBEE_CANNON_LEFT,        "models/vehicles/bumblebee_plasma_left.dpm");
MODEL(VEH_BUMBLEBEE_CANNON_RIGHT,       "models/vehicles/bumblebee_plasma_right.dpm");
MODEL(VEH_BUMBLEBEE_SHIELD,             "models/vhshield.md3");

MODEL(VEH_RACER_BODY,                   "models/vehicles/wakizashi.dpm");
MODEL(VEH_RACER_VIEW,                   "models/vehicles/wakizashi_cockpit.dpm");

MODEL(VEH_RAPTOR_BODY,                  "models/vehicles/raptor.dpm");
MODEL(VEH_RAPTOR_CB_FOLDED,             "models/vehicles/clusterbomb_folded.md3");
MODEL(VEH_RAPTOR_CB_FRAGMENT,           "models/vehicles/clusterbomb_fragment.md3");
MODEL(VEH_RAPTOR_FLARE,                 "models/runematch/rune.mdl");
MODEL(VEH_RAPTOR_GUN,                   "models/vehicles/raptor_gun.dpm");
MODEL(VEH_RAPTOR_PROP,                  "models/vehicles/spinner.dpm");
MODEL(VEH_RAPTOR_TAIL,                  "models/vehicles/raptor_body.dpm");
MODEL(VEH_RAPTOR_VIEW,                  "models/vehicles/raptor_cockpit.dpm");

MODEL(VEH_SPIDERBOT_BODY,               "models/vehicles/spiderbot.dpm");
MODEL(VEH_SPIDERBOT_GUN,                "models/vehicles/spiderbot_barrels.dpm");
MODEL(VEH_SPIDERBOT_MUZZLEFLASH,        "models/uziflash.md3");
MODEL(VEH_SPIDERBOT_TOP,                "models/vehicles/spiderbot_top.dpm");
MODEL(VEH_SPIDERBOT_VIEW,               "models/vehicles/spiderbot_cockpit.dpm");

MODEL(CHAT,                             "models/misc/chatbubble.spr");
MODEL(CHAT_MINIGAME,                    "models/sprites/minigame_busy.iqm");

MODEL(0,                                "models/sprites/0.spr32");
MODEL(1,                                "models/sprites/1.spr32");
MODEL(2,                                "models/sprites/2.spr32");
MODEL(3,                                "models/sprites/3.spr32");
MODEL(4,                                "models/sprites/4.spr32");
MODEL(5,                                "models/sprites/5.spr32");
MODEL(6,                                "models/sprites/6.spr32");
MODEL(7,                                "models/sprites/7.spr32");
MODEL(8,                                "models/sprites/8.spr32");
MODEL(9,                                "models/sprites/9.spr32");
MODEL(10,                               "models/sprites/10.spr32");
Model MDL_NUM(int i) {
    if ((i >= 0 && i <= 10))
        return REGISTRY_GET(Models, MDL_0.m_id + i);
    return MDL_Null;
}

MODEL(WAYPOINT,                         "models/runematch/rune.mdl");
MODEL(MARKER,                           "models/marker.md3");
