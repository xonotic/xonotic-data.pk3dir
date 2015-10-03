// cl_gentle impact effect indicating damage
DEF(particlegibs_damage_hit);
// core decal
SUB(particlegibs_damage_hit) {
    MY(airfriction) = 3;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 428;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 0.500000;
    MY(gravity) = 1;
    MY(liquidfriction) = 6;
    MY(size_min) = 5;
    MY(size_max) = 10;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_max) = 8;
    MY(type) = "blood";
    MY(velocityjitter) = '156.0 156.0 212.0';
}
// front blood
SUB(particlegibs_damage_hit) {
    MY(airfriction) = 1;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 0.100000;
    MY(gravity) = 0.500000;
    MY(liquidfriction) = 3;
    MY(sizeincrease) = -15;
    MY(size_min) = 10;
    MY(size_max) = 20;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_min) = 24;
    MY(tex_max) = 32;
    MY(type) = "blood";
    MY(velocityjitter) = '6.0 6.0 30.0';
    MY(velocitymultiplier) = -1;
}
// back blood
SUB(particlegibs_damage_hit) {
    MY(airfriction) = 1;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 0.100000;
    MY(gravity) = 1;
    MY(liquidfriction) = 3;
    MY(originjitter) = '3.0 3.0 3.0';
    MY(sizeincrease) = 10;
    MY(size_min) = 5;
    MY(size_max) = 15;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_min) = 24;
    MY(tex_max) = 32;
    MY(type) = "blood";
    MY(velocityjitter) = '26.0 26.0 112.0';
    MY(velocitymultiplier) = 2;
}

// effect for removing player model
DEF(particlegibs_damage_dissolve);
// small core blood no decals
SUB(particlegibs_damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(color_min) = "0x00ffff";
    MY(color_max) = "0x82ffff";
    MY(count) = 32;
    MY(gravity) = 1;
    MY(liquidfriction) = 6;
    MY(originjitter) = '10.0 10.0 25.0';
    MY(size_min) = 15;
    MY(size_max) = 20;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_max) = 8;
    MY(type) = "blood";
    MY(velocityjitter) = '256.0 256.0 312.0';
}
// core decal
SUB(particlegibs_damage_dissolve) {
    MY(airfriction) = 2;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 528;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 12;
    MY(gravity) = 2;
    MY(liquidfriction) = 6;
    MY(originjitter) = '10.0 10.0 25.0';
    MY(size_min) = 20;
    MY(size_max) = 40;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_max) = 8;
    MY(type) = "blood";
    MY(velocityjitter) = '356.0 356.0 412.0';
}
// front blood
SUB(particlegibs_damage_dissolve) {
    MY(airfriction) = 1;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 32;
    MY(gravity) = 0.500000;
    MY(liquidfriction) = 3;
    MY(originjitter) = '5.0 5.0 10.0';
    MY(sizeincrease) = -15;
    MY(size_min) = 10;
    MY(size_max) = 20;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_min) = 24;
    MY(tex_max) = 32;
    MY(type) = "blood";
    MY(velocityjitter) = '56.0 56.0 212.0';
    MY(velocitymultiplier) = -0.300000;
}
// back blood
SUB(particlegibs_damage_dissolve) {
    MY(airfriction) = 1;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(bounce) = -1;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 32;
    MY(gravity) = 1;
    MY(liquidfriction) = 3;
    MY(originjitter) = '5.0 5.0 10.0';
    MY(sizeincrease) = 10;
    MY(size_min) = 5;
    MY(size_max) = 15;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_min) = 24;
    MY(tex_max) = 32;
    MY(type) = "blood";
    MY(velocityjitter) = '56.0 56.0 212.0';
    MY(velocitymultiplier) = 0.500000;
}
// small bits
SUB(particlegibs_damage_dissolve) {
    MY(airfriction) = 1.500000;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 328;
    MY(color_min) = "0xA8FFFF";
    MY(color_max) = "0xA8FFFFF";
    MY(count) = 75;
    MY(gravity) = 1;
    MY(liquidfriction) = 3;
    MY(originjitter) = '10.0 10.0 25.0';
    MY(sizeincrease) = 10;
    MY(size_min) = 1;
    MY(size_max) = 1;
    MY(staincolor_min) = "0x808080";
    MY(staincolor_max) = "0x808080";
    MY(staintex_min) = 16;
    MY(staintex_max) = 24;
    MY(tex_min) = 24;
    MY(tex_max) = 32;
    MY(type) = "blood";
    MY(velocityjitter) = '656.0 656.0 912.0';
}
