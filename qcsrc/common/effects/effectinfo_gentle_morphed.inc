// cl_gentle impact effect indicating damage
DEF(morphed_damage_hit);
SUB(morphed_damage_hit) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 128;
    MY(alpha_fade) = 292;
    MY(color_min) = "0xffffff";
    MY(color_max) = "0x9271fb";
    MY(count) = 0.500000;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 10;
    MY(sizeincrease) = -24;
    MY(size_min) = 14;
    MY(size_max) = 24;
    MY(tex_min) = 43;
    MY(tex_max) = 43;
    MY(type) = "spark";
    MY(velocityjitter) = '356.0 356.0 456.0';
}
SUB(morphed_damage_hit) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 128;
    MY(alpha_fade) = 292;
    MY(color_min) = "0xffffff";
    MY(color_max) = "0x9271fb";
    MY(count) = 0.500000;
    MY(liquidfriction) = 10;
    MY(originjitter) = '10.0 10.0 10.0';
    MY(sizeincrease) = -24;
    MY(size_min) = 24;
    MY(size_max) = 24;
    MY(tex_max) = 8;
    MY(type) = "smoke";
}

// effect for removing player model
DEF(morphed_damage_dissolve);
SUB(morphed_damage_dissolve) {
    MY(airfriction) = 8;
    MY(alpha_min) = 456;
    MY(alpha_max) = 456;
    MY(alpha_fade) = 1828;
    MY(color_min) = "0xffffff";
    MY(color_max) = "0x9271fb";
    MY(count) = 10;
    MY(gravity) = -1.900000;
    MY(liquidfriction) = 6;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -399;
    MY(spin_max) = -99;
    MY(sizeincrease) = -16;
    MY(size_min) = 40;
    MY(size_max) = 40;
    MY(tex_min) = 43;
    MY(tex_max) = 43;
    MY(type) = "smoke";
    MY(velocityjitter) = '256.0 256.0 512.0';
}
SUB(morphed_damage_dissolve) {
    MY(airfriction) = 9;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 628;
    MY(color_min) = "0x7bdbff";
    MY(color_max) = "0xbed2ff";
    MY(count) = 2.500000;
    MY(gravity) = -0.800000;
    MY(liquidfriction) = 6;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(sizeincrease) = -16;
    MY(size_min) = 40;
    MY(size_max) = 40;
    MY(tex_min) = 43;
    MY(tex_max) = 43;
    MY(type) = "smoke";
    MY(velocityjitter) = '256.0 256.0 512.0';
}
SUB(morphed_damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 156;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 128;
    MY(color_min) = "0xffffff";
    MY(color_max) = "0x9271fb";
    MY(count) = 5;
    MY(liquidfriction) = 6;
    MY(originjitter) = '22.0 22.0 76.0';
    MY(sizeincrease) = -16;
    MY(size_min) = 44;
    MY(size_max) = 44;
    MY(tex_min) = 65;
    MY(tex_max) = 65;
    MY(type) = "smoke";
}
SUB(morphed_damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 56;
    MY(alpha_max) = 56;
    MY(alpha_fade) = 128;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xffffff";
    MY(color_max) = "0x9271fb";
    MY(count) = 15;
    MY(gravity) = 1;
    MY(liquidfriction) = 6;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 999;
    MY(spin_max) = -999;
    MY(sizeincrease) = -16;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(tex_min) = 46;
    MY(tex_max) = 46;
    MY(type) = "smoke";
    MY(velocityjitter) = '400.0 400.0 0.0';
}
