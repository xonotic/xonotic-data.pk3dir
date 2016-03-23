#include "tests.qh"

void test_weapons_hurt() {
    SELFPARAM();
    EXPECT_NE(100, this.health);
    remove(this.enemy);
    remove(this);
}

TEST(Weapons, Hurt)
{
    entity it;

    Client a = it = NEW(Client, "A");
    WITH(float, autocvar_g_spawnshieldtime, 0, Client_Add(it, NUM_TEAM_1));
    it.origin = '-100 0 0';
    it.angles = '0 0 0';

    Client b = it = NEW(Client, "B");
    WITH(float, autocvar_g_spawnshieldtime, 0, Client_Add(it, NUM_TEAM_2));
    it.origin = '100 0 0';
    it.angles = '0 180 0';

    it = a;
    PHYS_INPUT_BUTTON_ATCK(it) = true;
    it.items |= IT_UNLIMITED_AMMO;
    Weapon wep = WEP_VORTEX;
    W_GiveWeapon(it, wep.m_id);
    W_SwitchWeapon_Force(it, wep);

    it = b;
    PHYS_INPUT_BUTTON_JUMP(it) = true;
    it.enemy = a;

    defer(it, wep.switchdelay_raise + 0.1, test_weapons_hurt);

    SUCCEED();
}
