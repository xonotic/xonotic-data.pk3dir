// flag_touch -- effects for touching the flag
#define flag_touch(name, colormin, colormax) \
    DEF(name##flag_touch); \
    SUB(name##flag_touch) { \
        MY(airfriction) = 3; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 556; \
        MY(bounce) = 1.500000; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(count) = 35; \
        MY(gravity) = 1; \
        MY(originjitter) = '1.0 1.0 1.0'; \
        MY(size_min) = 1; \
        MY(size_max) = 3; \
        MY(tex_min) = 40; \
        MY(tex_max) = 40; \
        MY(type) = "spark"; \
        MY(velocityjitter) = '300.0 300.0 300.0'; \
        MY(velocitymultiplier) = 0.500000; \
    }

flag_touch(red,     "0xFF0000", "0x970000")
flag_touch(blue,    "0x0000FF", "0x000097")
flag_touch(yellow,  "0xFFFF0F", "0xFFFF0F")
flag_touch(pink,    "0xFF0FFF", "0xFF0FFF")
flag_touch(neutral, "0xFFFFFF", "0xFFFFFF")
#undef flag_touch

#define pass(name, colormin, colormax) \
    DEF(name##_pass); \
    SUB(name##_pass) { \
        MY(airfriction) = 5; \
        MY(alpha_min) = 64; \
        MY(alpha_max) = 128; \
        MY(alpha_fade) = 64; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(sizeincrease) = 2; \
        MY(size_min) = 2; \
        MY(size_max) = 2; \
        MY(tex_min) = 32; \
        MY(tex_max) = 32; \
        MY(trailspacing) = 64; \
        MY(type) = "static"; \
    } \
    SUB(name##_pass) { \
        MY(airfriction) = 9; \
        MY(alpha_min) = 32; \
        MY(alpha_max) = 64; \
        MY(alpha_fade) = 32; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(sizeincrease) = 8; \
        MY(size_min) = 1; \
        MY(size_max) = 1; \
        MY(tex_max) = 8; \
        MY(trailspacing) = 12; \
        MY(type) = "static"; \
        MY(velocityjitter) = '64.0 64.0 64.0'; \
    } \
    SUB(name##_pass) { \
        MY(alpha_min) = 256; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 1280; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(size_min) = 4; \
        MY(size_max) = 4; \
        MY(trailspacing) = 12; \
        MY(type) = "static"; \
    } \
    /**/

pass(red,       "0xFF0000", "0x970000")
pass(blue,      "0x0000FF", "0x000097")
pass(yellow,    "0xFFFF0F", "0xFFFF0F")
pass(pink,      "0xFFFFFF", "0xFFFFFF")
pass(neutral,   "0xFFFFFF", "0xFFFFFF")
#undef pass

// cap -- team capture effect
#define cap(name, colormin, colormax) \
    DEF(name##_cap); \
    SUB(name##_cap) { \
        MY(airfriction) = 2; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 100; \
        MY(bounce) = 1.500000; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(count) = 500; \
        MY(originjitter) = '1.0 1.0 1.0'; \
        MY(size_min) = 1; \
        MY(size_max) = 1; \
        MY(stretchfactor) = 0.600000; \
        MY(tex_min) = 64; \
        MY(tex_max) = 64; \
        MY(type) = "spark"; \
        MY(velocityjitter) = '1000.0 1000.0 1500.0'; \
        MY(velocitymultiplier) = 0.500000; \
    } \
    SUB(name##_cap) { \
        MY(alpha_min) = 190; \
        MY(alpha_max) = 190; \
        MY(alpha_fade) = 180; \
        MY(color_min) = colormin; \
        MY(color_max) = colormax; \
        MY(countabsolute) = 1; \
        MY(sizeincrease) = -80; \
        MY(size_min) = 150; \
        MY(size_max) = 150; \
        MY(tex_min) = 65; \
        MY(tex_max) = 65; \
        MY(type) = "smoke"; \
    } \
    /**/

cap(red,    "0xFF0000", "0x970000")
cap(blue,   "0x0000FF", "0x000097")
cap(yellow, "0xFFFF0F", "0xFFFF0F")
cap(pink,   "0xFF0FFF", "0xFF0FFF")
#undef cap
