#define rocketminsta_laser(name, color) \
    DEF(rocketminsta_laser_##name); \
    SUB(rocketminsta_laser_##name) { \
        MY(alpha_min) = 256; \
        MY(alpha_max) = 256; \
        MY(alpha_fade) = 968; \
        MY(color_min) = color; \
        MY(color_max) = color; \
        MY(lightcolor) = '1.5 3.0 6.0'; \
        MY(lightradius) = 90; \
        MY(size_min) = 3; \
        MY(size_max) = 3; \
        MY(tex_min) = 38; \
        MY(tex_max) = 38; \
        MY(trailspacing) = 2; \
        MY(type) = "static"; \
        MY(velocitymultiplier) = -0.100000; \
    } \
    SUB(rocketminsta_laser_##name) /* bright sparks */ { \
        MY(airfriction) = 12; \
        MY(alpha_min) = 444; \
        MY(alpha_max) = 512; \
        MY(alpha_fade) = 1866; \
        MY(bounce) = 1; \
        MY(color_min) = color; \
        MY(color_max) = color; \
        MY(count) = 1.500000; \
        MY(originjitter) = '1.0 1.0 1.0'; \
        MY(sizeincrease) = -20; \
        MY(size_min) = 2; \
        MY(size_max) = 4; \
        MY(tex_min) = 42; \
        MY(tex_max) = 42; \
        MY(trailspacing) = 12; \
        MY(type) = "snow"; \
        MY(velocityjitter) = '50.0 50.0 50.0'; \
        MY(velocityoffset) = '0.0 0.0 15.0'; \
    } \
    /**/

rocketminsta_laser(red,     "0xFF0F0F")
rocketminsta_laser(blue,    "0x0F0FFF")
rocketminsta_laser(yellow,  "0xFFFF0F")
rocketminsta_laser(pink,    "0xFF0FFF")
rocketminsta_laser(neutral, "0xFFFFFF")
#undef rocketminsta_laser
