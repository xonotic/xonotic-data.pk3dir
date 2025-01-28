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

// TODO: clean this up
PRECACHE(Models_GlobalPrecache)
{
    precache_model(MDL_CTF_SHIELD);
    precache_model(MDL_CTF_CAPTURE);
    precache_model(MDL_CTF_FLAG);
    precache_model(MDL_DOM_NEUTRAL);
    precache_model(MDL_DOM_RED);
    precache_model(MDL_DOM_BLUE);
    precache_model(MDL_DOM_YELLOW);
    precache_model(MDL_DOM_PINK);
    precache_model(MDL_ICE);
    precache_model(MDL_KH_KEY);
#ifdef KH_PLAYER_USE_CARRIEDMODEL
    precache_model(MDL_KH_KEY_CARRIED);
#endif
    precache_model(MDL_ONS_CP);
    precache_model(MDL_ONS_CP_SHIELD);
    precache_model(MDL_ONS_CP_PAD1);
    precache_model(MDL_ONS_CP_PAD2);
    precache_model(MDL_ONS_CP1);
    precache_model(MDL_ONS_CP1_GIB);
    precache_model(MDL_ONS_CP2);
    precache_model(MDL_ONS_CP2_GIB);
    precache_model(MDL_ONS_CP3);
    precache_model(MDL_ONS_CP3_GIB);
    precache_model(MDL_ONS_RAY);
    precache_model(MDL_ONS_GEN);
    precache_model(MDL_ONS_GEN_SHIELD);
    precache_model(MDL_ONS_GEN_GIB1);
    precache_model(MDL_ONS_GEN_GIB2);
    precache_model(MDL_ONS_GEN_GIB3);
    precache_model(MDL_ONS_GEN1);
    precache_model(MDL_ONS_GEN2);
    precache_model(MDL_ONS_GEN3);
    precache_model(MDL_ONS_GEN4);
    precache_model(MDL_ONS_GEN5);
    precache_model(MDL_ONS_GEN6);
    precache_model(MDL_ONS_GEN7);
    precache_model(MDL_ONS_GEN8);
    precache_model(MDL_ONS_GEN9);
    precache_model(MDL_ONS_GEN_DEAD);
    precache_model(MDL_PROJECTILE_ELECTRO);
    precache_model(MDL_PROJECTILE_ELECTRO_BEAM);
    precache_model(MDL_PROJECTILE_ROCKET);
    precache_model(MDL_PROJECTILE_CRYLINK);
    precache_model(MDL_PROJECTILE_CRYLINK_BOUNCING);
    precache_model(MDL_PROJECTILE_GRENADE);
    precache_model(MDL_PROJECTILE_GRENADE_BOUNCING);
    precache_model(MDL_PROJECTILE_MINE);
    precache_model(MDL_PROJECTILE_BLASTER);
    precache_model(MDL_PROJECTILE_HLAC);
    precache_model(MDL_PROJECTILE_PORTO_RED);
    precache_model(MDL_PROJECTILE_PORTO_BLUE);
    precache_model(MDL_PROJECTILE_HOOKBOMB);
    precache_model(MDL_PROJECTILE_HAGAR);
    precache_model(MDL_PROJECTILE_HAGAR_BOUNCING);
    precache_model(MDL_PROJECTILE_ARC_BOLT);
    precache_model(MDL_PROJECTILE_NAPALM_FOUNTAIN);
    precache_model(MDL_PROJECTILE_FIREBALL);
    precache_model(MDL_PROJECTILE_FIREMINE);
    precache_model(MDL_PROJECTILE_TAG);
    precache_model(MDL_PROJECTILE_FLAC);
    precache_model(MDL_PROJECTILE_SEEKER);
    precache_model(MDL_PROJECTILE_MAGE_SPIKE);
    precache_model(MDL_PROJECTILE_GOLEM_LIGHTNING);
    precache_model(MDL_PROJECTILE_RAPTORBOMB);
    precache_model(MDL_PROJECTILE_RAPTORBOMBLET);
    precache_model(MDL_PROJECTILE_RAPTORCANNON);
    precache_model(MDL_PROJECTILE_SPIDERROCKET);
    precache_model(MDL_PROJECTILE_WAKIROCKET);
    precache_model(MDL_PROJECTILE_WAKICANNON);
    precache_model(MDL_PROJECTILE_BUMBLE_GUN);
    precache_model(MDL_PROJECTILE_BUMBLE_BEAM);
    precache_model(MDL_PROJECTILE_RPC);
    precache_model(MDL_PROJECTILE_ROCKETMINSTA_LASER);
    precache_model(MDL_PROJECTILE_NADE);
    precache_model(MDL_GIB_CHUNK);
    precache_model(MDL_GIB_LEG1);
    precache_model(MDL_GIB_LEG2);
    precache_model(MDL_GIB_CHEST);
    precache_model(MDL_GIB_SMALLCHEST);
    precache_model(MDL_GIB_ARM);
    precache_model(MDL_GIB_BLOODYSKULL);
    precache_model(MDL_GIB_EYE);
    precache_model(MDL_GIB_ROBO);
    precache_model(MDL_GIB_ROBO_1);
    precache_model(MDL_GIB_ROBO_2);
    precache_model(MDL_GIB_ROBO_3);
    precache_model(MDL_GIB_ROBO_4);
    precache_model(MDL_GIB_ROBO_5);
    precache_model(MDL_GIB_ROBO_6);
    precache_model(MDL_GIB_ROBO_7);
    precache_model(MDL_GIB_ROBO_8);
    precache_model(MDL_CASING_SHELL);
    precache_model(MDL_CASING_BULLET);
    precache_model(MDL_BUFF);
    precache_model(MDL_TUR_GIB_BASE1);
    precache_model(MDL_TUR_GIB_BASE2);
    precache_model(MDL_TUR_GIB_BASE3);
    precache_model(MDL_TUR_GIB_BASE4);
    precache_model(MDL_TUR_GIB_HEAD1);
    precache_model(MDL_TUR_GIB_HEAD2);
    precache_model(MDL_TUR_GIB_HEAD3);
    precache_model(MDL_TUR_GIB_HEAD4);
    precache_model(MDL_TUR_BASE);
    precache_model(MDL_TUR_EWHEEL_BASE);
    precache_model(MDL_TUR_EWHEEL_HEAD);
    precache_model(MDL_TUR_FLAC_BASE);
    precache_model(MDL_TUR_FLAC_HEAD);
    precache_model(MDL_TUR_FUSIONREACTOR_BASE);
    precache_model(MDL_TUR_FUSIONREACTOR_HEAD);
    precache_model(MDL_TUR_HELLION_BASE);
    precache_model(MDL_TUR_HELLION_HEAD);
    precache_model(MDL_TUR_HK_BASE);
    precache_model(MDL_TUR_HK_HEAD);
    precache_model(MDL_TUR_MACHINEGUN_BASE);
    precache_model(MDL_TUR_MACHINEGUN_HEAD);
    precache_model(MDL_TUR_MIRS_BASE);
    precache_model(MDL_TUR_MIRS_HEAD);
    precache_model(MDL_TUR_PHASER_BASE);
    precache_model(MDL_TUR_PHASER_BEAM);
    precache_model(MDL_TUR_PHASER_HEAD);
    precache_model(MDL_TUR_PLASMA_BASE);
    precache_model(MDL_TUR_PLASMA_HEAD);
    precache_model(MDL_TUR_PLASMA_DUAL_BASE);
    precache_model(MDL_TUR_PLASMA_DUAL_HEAD);
    precache_model(MDL_TUR_TESLA_BASE);
    precache_model(MDL_TUR_TESLA_HEAD);
    precache_model(MDL_TUR_WALKER_BASE);
    precache_model(MDL_TUR_WALKER_HEAD);
    precache_model(MDL_VEH_SHIELD);
    precache_model(MDL_VEH_BUMBLEBEE_BODY);
    precache_model(MDL_VEH_BUMBLEBEE_CANNON_CENTER);
    precache_model(MDL_VEH_BUMBLEBEE_CANNON_LEFT);
    precache_model(MDL_VEH_BUMBLEBEE_CANNON_RIGHT);
    precache_model(MDL_VEH_BUMBLEBEE_SHIELD);
    precache_model(MDL_VEH_RACER_BODY);
    precache_model(MDL_VEH_RACER_VIEW);
    precache_model(MDL_VEH_RAPTOR_BODY);
    precache_model(MDL_VEH_RAPTOR_CB_FOLDED);
    precache_model(MDL_VEH_RAPTOR_CB_FRAGMENT);
    precache_model(MDL_VEH_RAPTOR_FLARE);
    precache_model(MDL_VEH_RAPTOR_GUN);
    precache_model(MDL_VEH_RAPTOR_PROP);
    precache_model(MDL_VEH_RAPTOR_TAIL);
    precache_model(MDL_VEH_RAPTOR_VIEW);
    precache_model(MDL_VEH_SPIDERBOT_BODY);
    precache_model(MDL_VEH_SPIDERBOT_GUN);
    precache_model(MDL_VEH_SPIDERBOT_MUZZLEFLASH);
    precache_model(MDL_VEH_SPIDERBOT_TOP);
    precache_model(MDL_VEH_SPIDERBOT_VIEW);
    precache_model(MDL_CHAT);
    precache_model(MDL_CHAT_MINIGAME);
    precache_model(MDL_0);
    precache_model(MDL_1);
    precache_model(MDL_2);
    precache_model(MDL_3);
    precache_model(MDL_4);
    precache_model(MDL_5);
    precache_model(MDL_6);
    precache_model(MDL_7);
    precache_model(MDL_8);
    precache_model(MDL_9);
    precache_model(MDL_10);
    precache_model(MDL_WAYPOINT);
    precache_model(MDL_MARKER);
}
