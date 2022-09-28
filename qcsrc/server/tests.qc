#include "tests.qh"

void test_weapons_hurt(entity this)
{
    EXPECT_NE(100, GetResource(this, RES_HEALTH));
    delete(this.enemy);
    delete(this);
}

TEST(Weapons, Hurt)
{
    entity it;

    noref Client a = it = NEW(Client, "A");
    WITH(float, autocvar_g_spawnshieldtime, 0, Client_Add(it, NUM_TEAM_1));
    it.origin = '-100 0 0';
    it.angles = '0 0 0';

    noref Client b = it = NEW(Client, "B");
    WITH(float, autocvar_g_spawnshieldtime, 0, Client_Add(it, NUM_TEAM_2));
    it.origin = '100 0 0';
    it.angles = '0 180 0';

    it = a;
    PHYS_INPUT_BUTTON_ATCK(it) = true;
    it.items |= IT_UNLIMITED_AMMO;
    Weapon wep = WEP_VORTEX;
    W_GiveWeapon(it, wep.m_id);
    W_SwitchWeapon_Force(it, wep, weaponentities[0]);

    it = b;
    PHYS_INPUT_BUTTON_JUMP(it) = true;
    it.enemy = a;

    defer(it, wep.switchdelay_raise + 0.1, test_weapons_hurt);

    SUCCEED();
}

TEST(Vehicles, Spawn)
{
    entity it;

    noref Client bot = it = NEW(Client, "Rider");
    Client_Add(it, NUM_TEAM_1);
    it.origin = '0 0 100';

    noref entity v = it = new(vehicle);
    Vehicle veh = VEH_BUMBLEBEE;
    it.active = ACTIVE_NOT;
    vehicle_initialize(it, veh, false);
    it.nextthink = time;

    SUCCEED();
}
