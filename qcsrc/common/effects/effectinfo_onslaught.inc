DEF(onslaught_generator_gib_explode);
// fire effect which expands then slows
SUB(onslaught_generator_gib_explode) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 356;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 17;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '8.0 8.0 8.0';
    MY(sizeincrease) = 45;
    MY(size_min) = 20;
    MY(size_max) = 26;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '286.0 286.0 286.0';
}
// smoke
SUB(onslaught_generator_gib_explode) {
    MY(airfriction) = 5;
    MY(alpha_min) = 200;
    MY(alpha_max) = 500;
    MY(alpha_fade) = 600;
    MY(bounce) = 2;
    MY(color_min) = "0x000000";
    MY(color_max) = "0x111111";
    MY(count) = 6;
    MY(gravity) = -0.300000;
    MY(notunderwater) = true;
    MY(sizeincrease) = 90;
    MY(size_min) = 1;
    MY(size_max) = 10;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '244.0 244.0 244.0';
}
// underwater bubbles
SUB(onslaught_generator_gib_explode) {
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 64;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x404040";
    MY(color_max) = "0x808080";
    MY(count) = 16;
    MY(gravity) = -0.125000;
    MY(liquidfriction) = 0.250000;
    MY(originjitter) = '16.0 16.0 16.0';
    MY(size_min) = 3;
    MY(size_max) = 3;
    MY(tex_min) = 62;
    MY(tex_max) = 62;
    MY(type) = "bubble";
    MY(underwater) = true;
    MY(velocityjitter) = '96.0 96.0 96.0';
}

DEF(onslaught_generator_gib_flame);
// fire effect which expands then slows
SUB(onslaught_generator_gib_flame) {
    MY(airfriction) = 5;
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 356;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 15;
    MY(gravity) = -0.500000;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '3.0 3.0 3.0';
    MY(sizeincrease) = 25;
    MY(size_min) = 5;
    MY(size_max) = 10;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '86.0 86.0 86.0';
}
// smoke
SUB(onslaught_generator_gib_flame) {
    MY(airfriction) = 5;
    MY(alpha_min) = 200;
    MY(alpha_max) = 500;
    MY(alpha_fade) = 600;
    MY(bounce) = 2;
    MY(color_min) = "0x000000";
    MY(color_max) = "0x111111";
    MY(count) = 1;
    MY(gravity) = -0.800000;
    MY(notunderwater) = true;
    MY(sizeincrease) = 30;
    MY(size_min) = 10;
    MY(size_max) = 20;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '44.0 44.0 44.0';
}
// underwater bubbles
SUB(onslaught_generator_gib_flame) {
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 64;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x404040";
    MY(color_max) = "0x808080";
    MY(count) = 16;
    MY(gravity) = -0.125000;
    MY(liquidfriction) = 0.250000;
    MY(originjitter) = '16.0 16.0 16.0';
    MY(size_min) = 3;
    MY(size_max) = 3;
    MY(tex_min) = 62;
    MY(tex_max) = 62;
    MY(type) = "bubble";
    MY(underwater) = true;
    MY(velocityjitter) = '96.0 96.0 96.0';
}
