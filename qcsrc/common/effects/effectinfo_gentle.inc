// cl_gentle impact effect indicating damage
// NOTE: maintained by div0, make your own new effect instead of changing this one without asking!
DEF(damage_hit);
SUB(damage_hit) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 128;
    MY(alpha_fade) = 192;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x00FFFF";
    MY(color_max) = "0xFF00FF";
    MY(count) = 0.500000;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 10;
    MY(sizeincrease) = -24;
    MY(size_min) = 16;
    MY(size_max) = 16;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '256.0 256.0 256.0';
}
SUB(damage_hit) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 128;
    MY(alpha_fade) = 192;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xFF00FF";
    MY(color_max) = "0xFFFF00";
    MY(count) = 0.500000;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 10;
    MY(sizeincrease) = -24;
    MY(size_min) = 16;
    MY(size_max) = 16;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '256.0 256.0 256.0';
}
SUB(damage_hit) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 128;
    MY(alpha_fade) = 192;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xFFFF00";
    MY(color_max) = "0x00FFFF";
    MY(count) = 0.500000;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 10;
    MY(sizeincrease) = -24;
    MY(size_min) = 16;
    MY(size_max) = 16;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '256.0 256.0 256.0';
}

// effect for removing player model
DEF(damage_dissolve);
// large sparks
SUB(damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 128;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x00FFFF";
    MY(color_max) = "0xFF00FF";
    MY(count) = 15;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 6;
    MY(sizeincrease) = -16;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '512.0 512.0 512.0';
}
SUB(damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 128;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xFF00FF";
    MY(color_max) = "0xFFFF00";
    MY(count) = 15;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 6;
    MY(sizeincrease) = -16;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '512.0 512.0 512.0';
}
SUB(damage_dissolve) {
    MY(airfriction) = 3;
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 128;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xFFFF00";
    MY(color_max) = "0x00FFFF";
    MY(count) = 15;
    MY(gravity) = -0.400000;
    MY(liquidfriction) = 6;
    MY(sizeincrease) = -16;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '512.0 512.0 512.0';
}
