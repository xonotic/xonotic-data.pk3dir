#define nade(name, colormin1, colormax1, colormin2, colormax2) \
    DEF(nade_##name); \
    SUB(nade_##name) { \
        MY(alpha_min) = 100; \
        MY(alpha_max) = 100; \
        MY(alpha_fade) = 250; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(sizeincrease) = -1; \
        MY(size_min) = 3; \
        MY(size_max) = 3; \
        MY(tex_min) = 65; \
        MY(tex_max) = 65; \
        MY(trailspacing) = 1; \
        MY(type) = "smoke"; \
    } \
    SUB(nade_##name) /* fire */ { \
        MY(alpha_min) = 30; \
        MY(alpha_max) = 30; \
        MY(alpha_fade) = 150; \
        MY(color_min) = colormin2; \
        MY(color_max) = colormax2; \
        MY(notunderwater) = true; \
        MY(sizeincrease) = -10; \
        MY(size_min) = 15; \
        MY(size_max) = 25; \
        MY(tex_min) = 65; \
        MY(tex_max) = 65; \
        MY(trailspacing) = 8; \
        MY(type) = "smoke"; \
    } \
    SUB(nade_##name) /* bubbles */ { \
        MY(alpha_min) = 256; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 256; \
        MY(bounce) = 1.500000; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(gravity) = -0.125000; \
        MY(liquidfriction) = 4; \
        MY(size_min) = 1; \
        MY(size_max) = 1; \
        MY(tex_min) = 62; \
        MY(tex_max) = 62; \
        MY(trailspacing) = 16; \
        MY(type) = "bubble"; \
        MY(underwater) = true; \
        MY(velocityjitter) = '16.0 16.0 16.0'; \
    } \
    /**/

nade(blue,      "0x006cff", "0x0600ff", "0x0600ff", "0x9794ff")
nade(red,       "0xff0000", "0xff3c00", "0xff0000", "0xffa2a2")
nade(yellow,    "0xFFFF0F", "0xFFFF0F", "0xFFFF0F", "0xFFFF0F")
nade(pink,      "0xFF0FFF", "0xFF0FFF", "0xFF0FFF", "0xFF0FFF")
nade(neutral,   "0xFFFFFF", "0xFFFFFF", "0xFFFFFF", "0xFFFFFF")
nade(green,     "0x40ff9b", "0x40ff9b", "0x40ff9b", "0xffa2a2")
nade(brown,     "0x5454ff", "0x5454ff", "0x5454ff", "0xa2a2ff")
nade(purple,    "0x540054", "0x540054", "0x540054", "0xffa2a2")
#undef nade

#define nade_burn(name, colormin1, colormax1, colormin2, colormax2) \
    DEF(nade_##name##_burn); \
    SUB(nade_##name##_burn) { \
        MY(alpha_min) = 100; \
        MY(alpha_max) = 100; \
        MY(alpha_fade) = 250; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(sizeincrease) = -1; \
        MY(size_min) = 5; \
        MY(size_max) = 5; \
        MY(tex_min) = 65; \
        MY(tex_max) = 65; \
        MY(trailspacing) = 1; \
        MY(type) = "smoke"; \
    } \
    SUB(nade_##name##_burn) /* fire */ { \
        MY(alpha_min) = 200; \
        MY(alpha_max) = 200; \
        MY(alpha_fade) = 1000; \
        MY(color_min) = colormin2; \
        MY(color_max) = colormax2; \
        MY(notunderwater) = true; \
        MY(sizeincrease) = -30; \
        MY(size_min) = 45; \
        MY(size_max) = 25; \
        MY(tex_min) = 65; \
        MY(tex_max) = 65; \
        MY(trailspacing) = 64; \
        MY(type) = "smoke"; \
    } \
    SUB(nade_##name##_burn) /* bubbles */ { \
        MY(alpha_min) = 256; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 256; \
        MY(bounce) = 1.500000; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(gravity) = -0.125000; \
        MY(liquidfriction) = 4; \
        MY(size_min) = 1; \
        MY(size_max) = 1; \
        MY(tex_min) = 62; \
        MY(tex_max) = 62; \
        MY(trailspacing) = 16; \
        MY(type) = "bubble"; \
        MY(underwater) = true; \
        MY(velocityjitter) = '16.0 16.0 16.0'; \
    } \
    SUB(nade_##name##_burn) { \
        MY(alpha_min) = 300; \
        MY(alpha_max) = 900; \
        MY(alpha_fade) = 1500; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(originjitter) = '2.0 2.0 2.0'; \
        MY(startangle_min) = -180; \
        MY(startangle_max) = 180; \
        MY(spin_min) = 20; \
        MY(spin_max) = -20; \
        MY(sizeincrease) = -40; \
        MY(size_min) = 15; \
        MY(size_max) = 25; \
        MY(tex_min) = 71; \
        MY(tex_max) = 73; \
        MY(trailspacing) = 16; \
        MY(type) = "smoke"; \
        MY(velocityjitter) = '10.0 10.0 10.0'; \
    } \
    /**/

nade_burn(red,      "0xff0000", "0xff3c00", "0xff0000", "0xffa2a2")
nade_burn(blue,     "0x006cff", "0x0600ff", "0x0600ff", "0x9794ff")
nade_burn(yellow,   "0xFFFF0F", "0xFFFF0F", "0xFFFF0F", "0xFFFF0F")
nade_burn(pink,     "0xFF0FFF", "0xFF0FFF", "0xFF0FFF", "0xFF0FFF")
nade_burn(neutral,  "0xFFFFFF", "0xFFFFFF", "0xFFFFFF", "0xFFFFFF")
nade_burn(green,    "0x40ff9b", "0x40ff9b", "0x40ff9b", "0xffa2a2")
nade_burn(brown,    "0x5454ff", "0x5454ff", "0x5454ff", "0xa2a2ff")
nade_burn(purple,   "0x540054", "0x540054", "0x540054", "0xffa2a2")
#undef nade_burn

#define nade_explode(name, colorlight, colormin1, colormax1, colormin2, colormax2, colormin3, colormax3) \
    DEF(nade_##name##_explode); \
    SUB(nade_##name##_explode) { \
        MY(alpha_min) = 256; \
        MY(alpha_max) = 256; \
        MY(countabsolute) = 1; \
        MY(lightcolor) = colorlight; \
        MY(lightradiusfade) = 1500; \
        MY(lightradius) = 300; \
        MY(originjitter) = '26.0 26.0 26.0'; \
        MY(size_min) = 88; \
        MY(size_max) = 88; \
        MY(tex_min) = 8; \
        MY(tex_max) = 16; \
        MY(type) = "decal"; \
    } \
    SUB(nade_##name##_explode) /* shockwave */ { \
        MY(alpha_min) = 80; \
        MY(alpha_max) = 80; \
        MY(alpha_fade) = 650; \
        MY(color_min) = colormin1; \
        MY(color_max) = colormax1; \
        MY(countabsolute) = 1; \
        MY(sizeincrease) = 1800; \
        MY(size_min) = 32; \
        MY(size_max) = 32; \
        MY(tex_min) = 33; \
        MY(tex_max) = 33; \
        MY(type) = "smoke"; \
        MY(velocitymultiplier) = 44; \
    } \
    SUB(nade_##name##_explode) /* fire */ { \
        MY(airfriction) = 30; \
        MY(alpha_min) = 400; \
        MY(alpha_max) = 656; \
        MY(alpha_fade) = 2000; \
        MY(color_min) = colormin2; \
        MY(color_max) = colormax2; \
        MY(count) = 16; \
        MY(notunderwater) = true; \
        MY(originjitter) = '50.0 50.0 50.0'; \
        MY(startangle_min) = -180; \
        MY(startangle_max) = 180; \
        MY(spin_min) = -9; \
        MY(spin_max) = 9; \
        MY(sizeincrease) = 555; \
        MY(size_min) = 20; \
        MY(size_max) = 24; \
        MY(tex_min) = 48; \
        MY(tex_max) = 55; \
        MY(type) = "smoke"; \
        MY(velocityjitter) = '320.0 320.0 320.0'; \
    } \
    SUB(nade_##name##_explode) /* fire stretched */ { \
        MY(airfriction) = -9; \
        MY(alpha_min) = 1500; \
        MY(alpha_max) = 3000; \
        MY(alpha_fade) = 13000; \
        MY(color_min) = colormin2; \
        MY(color_max) = colormax2; \
        MY(count) = 8; \
        MY(sizeincrease) = 40; \
        MY(size_min) = 60; \
        MY(size_max) = 90; \
        MY(stretchfactor) = 80; \
        MY(tex_min) = 48; \
        MY(tex_max) = 55; \
        MY(type) = "spark"; \
        MY(velocityjitter) = '30.0 30.0 30.0'; \
    } \
    SUB(nade_##name##_explode) /* smoke */ { \
        MY(airfriction) = 0.040000; \
        MY(alpha_min) = 128; \
        MY(alpha_max) = 328; \
        MY(alpha_fade) = 390; \
        MY(blend) = "alpha"; \
        MY(color_min) = "0x222222"; \
        MY(color_max) = "0x000000"; \
        MY(count) = 32; \
        MY(gravity) = 0.400000; \
        MY(originjitter) = '50.0 50.0 10.0'; \
        MY(startangle_min) = -180; \
        MY(startangle_max) = 180; \
        MY(spin_min) = 2; \
        MY(spin_max) = -2; \
        MY(sizeincrease) = 50; \
        MY(size_min) = 60; \
        MY(size_max) = 30; \
        MY(tex_max) = 7; \
        MY(type) = "smoke"; \
        MY(velocityjitter) = '200.0 200.0 200.0'; \
        MY(velocityoffset) = '0.0 0.0 180.0'; \
    } \
    SUB(nade_##name##_explode) /* underwater bubbles */ { \
        MY(alpha_min) = 128; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 64; \
        MY(bounce) = 1.500000; \
        MY(color_min) = "0x404040"; \
        MY(color_max) = "0x808080"; \
        MY(count) = 32; \
        MY(gravity) = -0.125000; \
        MY(liquidfriction) = 0.250000; \
        MY(originjitter) = '16.0 16.0 16.0'; \
        MY(size_min) = 3; \
        MY(size_max) = 6; \
        MY(tex_min) = 62; \
        MY(tex_max) = 62; \
        MY(type) = "bubble"; \
        MY(underwater) = true; \
        MY(velocityjitter) = '196.0 196.0 196.0'; \
    } \
    SUB(nade_##name##_explode) /* bouncing sparks */ { \
        MY(airfriction) = 1; \
        MY(alpha_min) = 644; \
        MY(alpha_max) = 956; \
        MY(alpha_fade) = 484; \
        MY(bounce) = 1.600000; \
        MY(color_min) = colormin3; \
        MY(color_max) = colormax3; \
        MY(count) = 8; \
        MY(gravity) = 1; \
        MY(liquidfriction) = 0.800000; \
        MY(notunderwater) = true; \
        MY(originjitter) = '16.0 16.0 16.0'; \
        MY(size_min) = 1; \
        MY(size_max) = 2; \
        MY(tex_min) = 40; \
        MY(tex_max) = 40; \
        MY(type) = "spark"; \
        MY(velocityjitter) = '424.0 424.0 624.0'; \
        MY(velocityoffset) = '0.0 0.0 80.0'; \
    } \
    SUB(nade_##name##_explode) /* notbouncing sparks */ { \
        MY(airfriction) = 0.700000; \
        MY(alpha_min) = 644; \
        MY(alpha_max) = 956; \
        MY(alpha_fade) = 684; \
        MY(color_min) = colormin3; \
        MY(color_max) = colormax3; \
        MY(count) = 16; \
        MY(gravity) = 0.500000; \
        MY(liquidfriction) = 0.800000; \
        MY(originjitter) = '16.0 16.0 16.0'; \
        MY(size_min) = 1; \
        MY(size_max) = 2; \
        MY(tex_min) = 40; \
        MY(tex_max) = 40; \
        MY(type) = "spark"; \
        MY(velocityjitter) = '424.0 424.0 624.0'; \
        MY(velocityoffset) = '0.0 0.0 80.0'; \
    } \
    SUB(nade_##name##_explode) /* debris */ { \
        MY(alpha_min) = 644; \
        MY(alpha_max) = 956; \
        MY(alpha_fade) = 2500; \
        MY(color_min) = colormin3; \
        MY(color_max) = colormax3; \
        MY(count) = 8; \
        MY(notunderwater) = true; \
        MY(originjitter) = '64.0 64.0 64.0'; \
        MY(startangle_min) = -180; \
        MY(startangle_max) = 180; \
        MY(spin_min) = -100; \
        MY(spin_max) = 100; \
        MY(size_min) = 20; \
        MY(size_max) = 40; \
        MY(tex_min) = 71; \
        MY(tex_max) = 73; \
        MY(type) = "smoke"; \
        MY(velocityjitter) = '324.0 324.0 324.0'; \
    } \
    /**/

nade_explode(blue,      '20.0 20.0 100.0', "0x80C0FF", "0x80C0FF", "0x629dff", "0x0018ff", "0x006cff", "0x0600ff")
nade_explode(red,       '100.0 20.0 20.0', "0xff0000", "0xffa2a2", "0xff0000", "0xff4200", "0xff0000", "0xffa2a2")
nade_explode(yellow,    '100.0 20.0 20.0', "0xff0000", "0xffa2a2", "0xFFFF0F", "0xFFFF0F", "0xff0000", "0xffa2a2")
nade_explode(pink,      '100.0 20.0 20.0', "0xff0000", "0xffa2a2", "0xFF0FFF", "0xFF0FFF", "0xff0000", "0xffa2a2")
nade_explode(neutral,   '100.0 20.0 20.0', "0xff0000", "0xffa2a2", "0xFFFFFF", "0xFFFFFF", "0xff0000", "0xffa2a2")
nade_explode(green,     '100.0 20.0 20.0', "0x40ff9b", "0xffa2a2", "0x40ff9b", "0x40ff9b", "0xff0000", "0xffa2a2")
nade_explode(brown,     '100.0 20.0 20.0', "0x5454ff", "0xa2a2ff", "0x5454ff", "0x5454ff", "0x0000ff", "0xa2a2ff")
nade_explode(purple,    '100.0 20.0 20.0', "0x540054", "0xffa2a2", "0x540054", "0x540054", "0xff0000", "0xffa2a2")
#undef nade_explode
