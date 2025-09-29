// docs: https://www.quakewiki.net/darkplaces-wiki/effectinfo-scripting-reference/
// use `cl_particles_reloadeffects` to reload effects without restarting engine
// use `chase_active 1` and `cl_lockview 1` to see effects from different perspectives
// `dumpeffectinfo` currently doesn't work so edit effectinfo.txt manually, just try to keep the files in sync
// always add new effects to the bottom of the list

// `tex` are indices into particles/particlefont.tga (see particles/particlefont-template.tga for numbers)
// the first index is inclusive, second exclusive (so `tex 0 8` will use images 0 though 7)
// unless they're equal (`tex 69 69` is the same as `tex 69 70`)

// item respawn effect
DEF(TE_WIZSPIKE);
// flare particle and light
SUB(TE_WIZSPIKE) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0x63f2EA";
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.4 0.9 0.9';
	MY(lightradiusfade) = 200;
	MY(lightradius) = 200;
	MY(size_min) = 20;
	MY(size_max) = 20;
	MY(type) = "static";
}
// cloud of particles which expand rapidly and then slow to form a ball
SUB(TE_WIZSPIKE) {
	MY(airfriction) = 2;
	MY(alpha_min) = 64;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0x63f2EA";
	MY(count) = 50;
	MY(liquidfriction) = 2;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
}

// laser impact
DEF(TE_KNIGHTSPIKE);
// decal
SUB(TE_KNIGHTSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 0.2 0.2';
	MY(lightradiusfade) = 1000;
	MY(lightradius) = 200;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// flare effect
SUB(TE_KNIGHTSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xFF2010";
	MY(color_max) = "0xFF2010";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// sparks that rapidly expand and rapidly slow down to form an interesting spherical effect
SUB(TE_KNIGHTSPIKE) {
	MY(airfriction) = 6;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(count) = 128;
	MY(liquidfriction) = 6;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

// machinegun bullet impact
DEF(TE_SPIKE);
// bullet impact decal
SUB(TE_SPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(TE_SPIKE) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x101010";
	MY(count) = 4;
	MY(sizeincrease) = 3;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}
// dust/smoke staying at the impact
SUB(TE_SPIKE) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x505050";
	MY(color_max) = "0x505050";
	MY(count) = 0.500000;
	MY(sizeincrease) = 4;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
}
// bouncing sparks
SUB(TE_SPIKE) {
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 10;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// electro combo explosion
DEF(TE_SPIKEQUAD);
// decal
SUB(TE_SPIKEQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '2.0 2.5 3.0';
	MY(lightradiusfade) = 200;
	MY(lightradius) = 400;
	MY(originjitter) = '34.0 34.0 34.0';
	MY(size_min) = 64;
	MY(size_max) = 64;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// flare effect
SUB(TE_SPIKEQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// large sparks
SUB(TE_SPIKEQUAD) {
	MY(airfriction) = 4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x2030FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 10;
	MY(liquidfriction) = 16;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}

// quake effect
DEF(TE_SUPERSPIKE);
// decal
SUB(TE_SUPERSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(TE_SUPERSPIKE) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x101010";
	MY(count) = 4;
	MY(sizeincrease) = 3;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}
// dust/smoke staying at the impact
SUB(TE_SUPERSPIKE) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x505050";
	MY(color_max) = "0x505050";
	MY(count) = 0.500000;
	MY(sizeincrease) = 4;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
}
// sparks that disappear on impact
SUB(TE_SUPERSPIKE) {
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 15;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// quake effect
DEF(TE_SUPERSPIKEQUAD);
// decal
SUB(TE_SUPERSPIKEQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.2 0.2 1.5';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 100;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(TE_SUPERSPIKEQUAD) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x101010";
	MY(count) = 4;
	MY(sizeincrease) = 3;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}
// dust/smoke staying at the impact
SUB(TE_SUPERSPIKEQUAD) {
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x505050";
	MY(color_max) = "0x505050";
	MY(count) = 0.500000;
	MY(sizeincrease) = 4;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
}
// sparks that disappear on impact
SUB(TE_SUPERSPIKEQUAD) {
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 15;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// shotgun pellet impact
DEF(TE_GUNSHOT);
// decal
SUB(TE_GUNSHOT) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(TE_GUNSHOT) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x101010";
	MY(count) = 0.800000;
	MY(sizeincrease) = 3;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}
// dust/smoke staying at the impact
SUB(TE_GUNSHOT) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x505050";
	MY(color_max) = "0x505050";
	MY(count) = 0.200000;
	MY(sizeincrease) = 4;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
}
// bouncing sparks
SUB(TE_GUNSHOT) {
	MY(alpha_max) = 64;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 2.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// crylink impact effect
DEF(TE_GUNSHOTQUAD);
// decal
SUB(TE_GUNSHOTQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '12.0 12.0 12.0';
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// purple flare effect
SUB(TE_GUNSHOTQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x504060";
	MY(color_max) = "0x504060";
	MY(countabsolute) = 1;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// purple sparks
SUB(TE_GUNSHOTQUAD) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xA040C0";
	MY(color_max) = "0xFFFFFF";
	MY(count) = 6;
	MY(gravity) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(type) = "spark";
	MY(velocityjitter) = '128.0 128.0 128.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// mortar/hagar explosion (smaller than rocket)
DEF(TE_EXPLOSION);
// decal
SUB(TE_EXPLOSION) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 2.0 0.5';
	MY(lightradiusfade) = 300;
	MY(lightradius) = 150;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// flare effect
SUB(TE_EXPLOSION) {
	MY(alpha_min) = 192;
	MY(alpha_max) = 192;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x404040";
	MY(countabsolute) = 1;
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 35;
	MY(tex_max) = 37;
	MY(type) = "static";
}
// fire effect which expands then slows
SUB(TE_EXPLOSION) {
	MY(airfriction) = 4;
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x902010";
	MY(color_max) = "0xFFD080";
	MY(count) = 64;
	MY(liquidfriction) = 4;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
// underwater bubbles
SUB(TE_EXPLOSION) {
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
// bouncing sparks
SUB(TE_EXPLOSION) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 16;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// quake effect
DEF(TE_EXPLOSIONQUAD);
// decal
SUB(TE_EXPLOSIONQUAD) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 2.0 8.0';
	MY(lightradiusfade) = 700;
	MY(lightradius) = 350;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// smoke cloud
SUB(TE_EXPLOSIONQUAD) {
	MY(alpha_min) = 32;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 16;
	MY(notunderwater) = true;
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '48.0 48.0 48.0';
}
// underwater bubbles
SUB(TE_EXPLOSIONQUAD) {
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
// sparks which go through walls
SUB(TE_EXPLOSIONQUAD) {
	MY(airfriction) = 0.200000;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 64;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// quake effect
DEF(TE_TAREXPLOSION);
// decal
SUB(TE_TAREXPLOSION) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '1.6 0.8 2.0';
	MY(lightradiusfade) = 1200;
	MY(lightradius) = 600;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// smoke cloud
SUB(TE_TAREXPLOSION) {
	MY(alpha_min) = 32;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 16;
	MY(notunderwater) = true;
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '48.0 48.0 48.0';
}
// underwater bubbles
SUB(TE_TAREXPLOSION) {
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
// sparks which go through walls
SUB(TE_TAREXPLOSION) {
	MY(airfriction) = 0.200000;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 64;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// bloody impact effect indicating damage
DEF(TE_BLOOD);
SUB(TE_BLOOD) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(count) = 0.167000;
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 1;
}

// sparks (quake effect)
DEF(TE_SPARK);
SUB(TE_SPARK) {
	MY(alpha_min) = 64;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.600000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 1;
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// vortex impact
DEF(TE_PLASMABURN);
// decal
SUB(TE_PLASMABURN) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '1.0 1.0 1.0';
	MY(lightradiusfade) = 400;
	MY(lightradius) = 200;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// flare effect
SUB(TE_PLASMABURN) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(tex_min) = 37;
	MY(tex_max) = 37;
	MY(type) = "static";
}
// small sparks which form a sphere as they slow down
SUB(TE_PLASMABURN) {
	MY(airfriction) = 8;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0x2030FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 128;
	MY(liquidfriction) = 8;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(type) = "spark";
	MY(velocityjitter) = '128.0 128.0 128.0';
}

// quake effect
DEF(TE_SMALLFLASH);
SUB(TE_SMALLFLASH) {
	MY(lightcolor) = '2.0 2.0 2.0';
	MY(lightradiusfade) = 1000;
	MY(lightradius) = 200;
}

// quake effect
DEF(TE_FLAMEJET);
SUB(TE_FLAMEJET) {
	MY(airfriction) = 1;
	MY(alpha_min) = 64;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.100000;
	MY(color_min) = "0x6f0f00";
	MY(color_max) = "0xe3974f";
	MY(count) = 0.500000;
	MY(gravity) = -1;
	MY(liquidfriction) = 4;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '128.0 128.0 128.0';
	MY(velocitymultiplier) = 1;
}

// quake effect
DEF(TE_LAVASPLASH);
SUB(TE_LAVASPLASH) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x6f0f00";
	MY(color_max) = "0xe3974f";
	MY(count) = 32;
	MY(gravity) = 0.050000;
	MY(originjitter) = '128.0 128.0 32.0';
	MY(originoffset) = '0.0 0.0 32.0';
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '128.0 128.0 0.0';
	MY(velocityoffset) = '0.0 0.0 256.0';
}

// player teleport effect
DEF(TE_TELEPORT);
SUB(TE_TELEPORT) {
	MY(airfriction) = 1;
	MY(alpha_min) = 64;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(color_min) = "0xA0A0A0";
	MY(color_max) = "0xFFFFFF";
	MY(count) = 56;
	MY(liquidfriction) = 4;
	MY(originjitter) = '16.0 16.0 28.0';
	MY(originoffset) = '0.0 0.0 28.0';
	MY(size_min) = 10;
	MY(size_max) = 10;
	MY(type) = "static";
	MY(velocityjitter) = '0.0 0.0 256.0';
}

// vortex beam
DEF(TE_TEI_G3);
SUB(TE_TEI_G3) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xFFFFFF";
	MY(countabsolute) = 1;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}
SUB(TE_TEI_G3) {
	MY(airfriction) = -4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}

// smoke effect
DEF(TE_TEI_SMOKE);
SUB(TE_TEI_SMOKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 0.167000;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 1;
}

// rocket explosion (bigger than mortar and hagar)
DEF(TE_TEI_BIGEXPLOSION);
// decal
SUB(TE_TEI_BIGEXPLOSION) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 2.0 0.5';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 500;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// flare effect
SUB(TE_TEI_BIGEXPLOSION) {
	MY(alpha_min) = 192;
	MY(alpha_max) = 192;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x404040";
	MY(countabsolute) = 1;
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 35;
	MY(tex_max) = 37;
	MY(type) = "static";
}
// fire effect
SUB(TE_TEI_BIGEXPLOSION) {
	MY(airfriction) = 4;
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x902010";
	MY(color_max) = "0xFFD080";
	MY(count) = 128;
	MY(liquidfriction) = 4;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// underwater bubbles
SUB(TE_TEI_BIGEXPLOSION) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '144.0 144.0 144.0';
}
// bouncing sparks
SUB(TE_TEI_BIGEXPLOSION) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 64;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(type) = "spark";
	MY(velocityjitter) = '384.0 384.0 384.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// electro explosion
DEF(TE_TEI_PLASMAHIT);
// decal
SUB(TE_TEI_PLASMAHIT) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '2.4 4.8 8.0';
	MY(lightradiusfade) = 600;
	MY(lightradius) = 200;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// flare effect
SUB(TE_TEI_PLASMAHIT) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// cloud of bouncing sparks
SUB(TE_TEI_PLASMAHIT) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x2030FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 0.500000;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}

// bloody impact effect indicating damage
DEF(blood);
SUB(blood) {
	MY(airfriction) = 0.400000;
	MY(alpha_min) = 1560;
	MY(alpha_max) = 2560;
	MY(alpha_fade) = 7000;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 0.400000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 11;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 20;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "spark";
	MY(velocityjitter) = '99.0 99.0 55.0';
}
//blood mist
SUB(blood) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(blend) = "invmod";
	MY(color_min) = "0x000000";
	MY(color_max) = "0x420000";
	MY(countabsolute) = 1;
	MY(originjitter) = '11.0 11.0 11.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 25;
	MY(size_max) = 30;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "alphastatic";
}

// player teleport effect
DEF(teleport);
SUB(teleport) {
	MY(airfriction) = 2;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 100;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(count) = 500;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(stretchfactor) = 0.600000;
	MY(tex_min) = 64;
	MY(tex_max) = 64;
	MY(type) = "spark";
	MY(velocityjitter) = '1000.0 1000.0 1500.0';
	MY(velocitymultiplier) = 0.500000;
}
SUB(teleport) {
	MY(alpha_min) = 190;
	MY(alpha_max) = 190;
	MY(alpha_fade) = 180;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(countabsolute) = 1;
	MY(sizeincrease) = -80;
	MY(size_min) = 150;
	MY(size_max) = 150;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
}

// normal super gory blood trail (used by gibs)
DEF(TR_BLOOD);
SUB(TR_BLOOD) {
	MY(airfriction) = -2;
	MY(alpha_min) = 384;
	MY(alpha_max) = 984;
	MY(alpha_fade) = 1492;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFF";
	MY(gravity) = 0.400000;
	MY(liquidfriction) = 1;
	MY(sizeincrease) = -5;
	MY(size_min) = 4;
	MY(size_max) = 19;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 7;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 20;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = -0.100000;
}
// splash around gib
SUB(TR_BLOOD) {
	MY(alpha_min) = 684;
	MY(alpha_max) = 684;
	MY(alpha_fade) = 7492;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFF";
	MY(sizeincrease) = 500;
	MY(size_min) = 4;
	MY(size_max) = 6;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 42;
	MY(type) = "blood";
}

// thinner blood trail (used by quake zombies)
DEF(TR_SLIGHTBLOOD);
SUB(TR_SLIGHTBLOOD) {
	MY(airfriction) = 1;
	MY(alpha_min) = 384;
	MY(alpha_max) = 384;
	MY(alpha_fade) = 192;
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFF";
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 64;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 0.500000;
}

// func_stardust effect, used in some maps to indicate teleporters
DEF(EF_STARDUST);
SUB(EF_STARDUST) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 128;
	MY(color_min) = "0xfff368";
	MY(color_max) = "0xfff368";
	MY(count) = 37.500000;
	MY(gravity) = -0.100000;
	MY(liquidfriction) = 0.800000;
	MY(originjitter) = '16.0 16.0 64.0';
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 0.0';
}

// flare particle and light
DEF(item_respawn);
SUB(item_respawn) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0x63f2EA";
	MY(countabsolute) = 1;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(type) = "static";
}
// cloud of particles which expand rapidly and then slow to form a ball
SUB(item_respawn) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1280;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0x63f2EA";
	MY(count) = 128;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

DEF(jumppad_activate);
SUB(jumppad_activate) {
	MY(lightcolor) = '2.0 2.0 2.0';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
}

DEF(laser_muzzleflash);
// glow and light
SUB(laser_muzzleflash) {
	MY(airfriction) = 10;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xcc0000";
	MY(color_max) = "0xff0000";
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.0 0.1 0.1';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(sizeincrease) = -100;
	MY(size_min) = 10;
	MY(size_max) = 15;
	MY(stretchfactor) = 2;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
}
// electricity
SUB(laser_muzzleflash) {
	MY(airfriction) = 10;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xb44215";
	MY(color_max) = "0xff0000";
	MY(count) = 3;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(sizeincrease) = -100;
	MY(size_min) = 5;
	MY(size_max) = 7;
	MY(stretchfactor) = 2.300000;
	MY(tex_min) = 43;
	MY(tex_max) = 43;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.200000;
}
// fire
SUB(laser_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xff4200";
	MY(color_max) = "0xff0000";
	MY(count) = 6;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -100;
	MY(size_min) = 7;
	MY(size_max) = 9;
	MY(stretchfactor) = 2;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.200000;
}

DEF(laser_impact);
// decal
SUB(laser_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 0.4 0.4';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 200;
	MY(originjitter) = '14.0 14.0 14.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// flare effect
SUB(laser_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xFF2010";
	MY(color_max) = "0xFF2010";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// sparks that rapidly expand and rapidly slow down to form an interesting spherical effect
SUB(laser_impact) {
	MY(airfriction) = 6;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(count) = 128;
	MY(liquidfriction) = 6;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
SUB(laser_impact) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(count) = 4;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 6;
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '16.0 16.0 16.0';
	MY(velocitymultiplier) = 0.010000;
}

DEF(shotgun_muzzleflash);
SUB(shotgun_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 1.500000;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = 12;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.050000;
}
SUB(shotgun_muzzleflash) {
	MY(airfriction) = 5;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xffdb96";
	MY(color_max) = "0xff5400";
	MY(count) = 16;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 10;
	MY(size_max) = 20;
	MY(stretchfactor) = 2.500000;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.500000;
}

// shotgun pellet impact
DEF(shotgun_impact);
// decal
SUB(shotgun_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(size_min) = 5;
	MY(size_max) = 8;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(shotgun_impact) {
	MY(airfriction) = 5;
	MY(alpha_min) = 300;
	MY(alpha_max) = 550;
	MY(alpha_fade) = 756;
	MY(color_min) = "0x473a37";
	MY(color_max) = "0x0b0a07";
	MY(count) = 1;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -50;
	MY(spin_max) = 50;
	MY(sizeincrease) = 25;
	MY(size_min) = 10;
	MY(size_max) = 20;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.200000;
}
// dust/smoke staying at the impact
SUB(shotgun_impact) {
	MY(airfriction) = 5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 350;
	MY(alpha_fade) = 500;
	MY(bounce) = 6;
	MY(color_min) = "0x201d1a";
	MY(color_max) = "0x000000";
	MY(count) = 0.200000;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -50;
	MY(spin_max) = 50;
	MY(sizeincrease) = 74;
	MY(size_min) = 10;
	MY(size_max) = 11;
	MY(tex_min) = 36;
	MY(tex_max) = 36;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 11.0';
	MY(velocitymultiplier) = 0.030000;
}
// sparks
SUB(shotgun_impact) {
	MY(airfriction) = 1.100000;
	MY(alpha_max) = 356;
	MY(alpha_fade) = 268;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xFDFFD9";
	MY(color_max) = "0xFDFFD9";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(notunderwater) = true;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.600000;
	MY(size_max) = 0.600000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 200.0';
	MY(velocitymultiplier) = 0.200000;
}

DEF(uzi_muzzleflash);
SUB(uzi_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 1;
	MY(gravity) = -0.100000;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "static";
	MY(velocityjitter) = '1.0 1.0 1.0';
	MY(velocitymultiplier) = 0.030000;
}
SUB(uzi_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 6000;
	MY(color_min) = "0xff9c00";
	MY(color_max) = "0xffd200";
	MY(count) = 3;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.300000;
	MY(size_max) = 0.400000;
	MY(stretchfactor) = 0.150000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '555.0 555.0 555.0';
	MY(velocitymultiplier) = 3;
}

DEF(machinegun_impact);
// decal
SUB(machinegun_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '6.0 3.6 0.6';
	MY(lightradiusfade) = 800;
	MY(lightradius) = 80;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(machinegun_impact) {
	MY(airfriction) = 5;
	MY(alpha_min) = 300;
	MY(alpha_max) = 550;
	MY(alpha_fade) = 456;
	MY(color_min) = "0x473a37";
	MY(color_max) = "0x0b0a07";
	MY(count) = 1.500000;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -50;
	MY(spin_max) = 50;
	MY(sizeincrease) = 15;
	MY(size_min) = 10;
	MY(size_max) = 20;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.100000;
}
// dust/smoke staying at the impact
SUB(machinegun_impact) {
	MY(airfriction) = 5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 350;
	MY(alpha_fade) = 500;
	MY(bounce) = 6;
	MY(color_min) = "0x201d1a";
	MY(color_max) = "0x000000";
	MY(count) = 0.500000;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -50;
	MY(spin_max) = 50;
	MY(sizeincrease) = 74;
	MY(size_min) = 10;
	MY(size_max) = 11;
	MY(tex_min) = 36;
	MY(tex_max) = 36;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 11.0';
	MY(velocitymultiplier) = 0.030000;
}
// debris
SUB(machinegun_impact) {
	MY(airfriction) = 1;
	MY(alpha_min) = 300;
	MY(alpha_max) = 550;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.700000;
	MY(color_min) = "0x63493e";
	MY(color_max) = "0xffffff";
	MY(count) = 1;
	MY(gravity) = 1.400000;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -500;
	MY(spin_max) = 500;
	MY(size_min) = 1;
	MY(size_max) = 5;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '350.0 350.0 350.0';
	MY(velocitymultiplier) = 0.200000;
}
// sparks
SUB(machinegun_impact) {
	MY(airfriction) = 2;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 168;
	MY(bounce) = 1;
	MY(color_min) = "0xFDFFD9";
	MY(color_max) = "0xFDFFD9";
	MY(count) = 1;
	MY(gravity) = 1;
	MY(notunderwater) = true;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.300000;
	MY(size_max) = 0.300000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.200000;
}

DEF(grenadelauncher_muzzleflash);
SUB(grenadelauncher_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 1.500000;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '20.0 20.0 20.0';
	MY(velocitymultiplier) = 0.030000;
}
SUB(grenadelauncher_muzzleflash) {
	MY(airfriction) = 5;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xffdb96";
	MY(color_max) = "0xff5400";
	MY(count) = 16;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 10;
	MY(size_max) = 20;
	MY(stretchfactor) = 2.500000;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.500000;
}

// mortar trail
DEF(TR_GRENADE);
// smoke
SUB(TR_GRENADE) {
	MY(alpha_min) = 300;
	MY(alpha_max) = 400;
	MY(alpha_fade) = 780;
	MY(bounce) = 1;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x000000";
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 3;
	MY(size_max) = 2;
	MY(tex_max) = 8;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '1.0 1.0 1.0';
	MY(velocitymultiplier) = -0.020000;
}
// fire
SUB(TR_GRENADE) {
	MY(airfriction) = 8;
	MY(alpha_min) = 100;
	MY(alpha_max) = 144;
	MY(alpha_fade) = 988;
	MY(color_min) = "0xffdf72";
	MY(color_max) = "0x811200";
	MY(notunderwater) = true;
	MY(sizeincrease) = -15;
	MY(size_min) = 5;
	MY(size_max) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = -1;
}
// bubbles
SUB(TR_GRENADE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 16;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// hookbomb trail
DEF(TR_KNIGHTSPIKE);
// smoke
SUB(TR_KNIGHTSPIKE) {
	MY(alpha_min) = 300;
	MY(alpha_max) = 400;
	MY(alpha_fade) = 600;
	MY(bounce) = 1;
	MY(color_min) = "0x303030";
	MY(color_max) = "0x000000";
	MY(gravity) = -0.110000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = 11;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(trailspacing) = 6;
	MY(type) = "smoke";
	MY(velocityjitter) = '3.0 3.0 3.0';
	MY(velocitymultiplier) = -0.020000;
}
// marker
SUB(TR_KNIGHTSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 720;
	MY(color_min) = "0x666666";
	MY(color_max) = "0x000000";
	MY(sizeincrease) = -0.100000;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 2;
	MY(type) = "alphastatic";
}
// bubbles
SUB(TR_KNIGHTSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 32;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

DEF(grenade_explode);
// decal
SUB(grenade_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 1.0';
	MY(lightradiusfade) = 400;
	MY(lightradius) = 250;
	MY(originjitter) = '26.0 26.0 26.0';
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// fire effect which expands then slows
SUB(grenade_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 128;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 356;
	MY(bounce) = 4.500000;
	MY(color_min) = "0xe03f00";
	MY(color_max) = "0x5e0000";
	MY(count) = 40;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 16;
	MY(size_max) = 26;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
// fire effect which make bright dot inside
SUB(grenade_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 228;
	MY(alpha_max) = 328;
	MY(alpha_fade) = 756;
	MY(bounce) = 1;
	MY(color_min) = "0xe03f00";
	MY(color_max) = "0xffdf92";
	MY(count) = 15;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 40;
	MY(size_min) = 6;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
// smoke
SUB(grenade_explode) {
	MY(airfriction) = 5;
	MY(alpha_min) = 300;
	MY(alpha_max) = 550;
	MY(alpha_fade) = 556;
	MY(bounce) = 6;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 10;
	MY(notunderwater) = true;
	MY(sizeincrease) = 34;
	MY(size_min) = 20;
	MY(size_max) = 40;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
// underwater bubbles
SUB(grenade_explode) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 3;
	MY(size_max) = 6;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '196.0 196.0 196.0';
}
// underwatershockwave
SUB(grenade_explode) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 300;
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1500;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(underwater) = true;
	MY(velocitymultiplier) = 0.300000;
}
// bouncing sparks
SUB(grenade_explode) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 484;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xffa35b";
	MY(color_max) = "0xfff2be";
	MY(count) = 16;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1;
	MY(size_max) = 0.100000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '424.0 424.0 624.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}
// debris
SUB(grenade_explode) {
	MY(airfriction) = 0.500000;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 684;
	MY(bounce) = 1.600000;
	MY(color_min) = "0x6a3d25";
	MY(color_max) = "0xcac5b4";
	MY(count) = 12;
	MY(gravity) = 1.300000;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -1000;
	MY(spin_max) = 1000;
	MY(size_min) = 2;
	MY(size_max) = 6;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '324.0 324.0 524.0';
}

DEF(electro_muzzleflash);
SUB(electro_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x283880";
	MY(color_max) = "0x283880";
	MY(countabsolute) = 1;
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = -10;
	MY(size_min) = 15;
	MY(size_max) = 15;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(electro_muzzleflash) {
	MY(airfriction) = 2;
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 2024;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 7;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 5;
	MY(size_max) = 15;
	MY(stretchfactor) = 1.500000;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.500000;
}
SUB(electro_muzzleflash) {
	MY(airfriction) = 8;
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 5;
	MY(gravity) = 1.300000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 7;
	MY(size_max) = 6;
	MY(stretchfactor) = 0.100000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '350.0 350.0 350.0';
	MY(velocitymultiplier) = 2.500000;
}

// electro trail
DEF(TR_NEXUIZPLASMA);
// glowing vapor trail
SUB(TR_NEXUIZPLASMA) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 968;
	MY(color_min) = "0x283880";
	MY(color_max) = "0x283880";
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradius) = 90;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(trailspacing) = 2;
	MY(type) = "static";
	MY(velocitymultiplier) = -0.100000;
}
// bright sparks
SUB(TR_NEXUIZPLASMA) {
	MY(airfriction) = 12;
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 1866;
	MY(bounce) = 1;
	MY(color_min) = "0x629dff";
	MY(color_max) = "0x0018ff";
	MY(count) = 1.500000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = -20;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_min) = 42;
	MY(tex_max) = 42;
	MY(trailspacing) = 12;
	MY(type) = "snow";
	MY(velocityjitter) = '50.0 50.0 50.0';
	MY(velocityoffset) = '0.0 0.0 15.0';
}

DEF(electro_impact);
// decal
SUB(electro_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.1 4.4 10.0';
	MY(lightradiusfade) = 250;
	MY(lightradius) = 250;
	MY(originjitter) = '17.0 17.0 17.0';
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// shockwave
SUB(electro_impact) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1000;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 44;
}
// flare effect
SUB(electro_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 12;
	MY(size_max) = 32;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// cloud of bouncing sparks
SUB(electro_impact) {
	MY(airfriction) = 6;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0x629dff";
	MY(color_max) = "0x0018ff";
	MY(count) = 30;
	MY(gravity) = -0.300000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -9999;
	MY(spin_max) = 9999;
	MY(sizeincrease) = -50;
	MY(size_min) = 36;
	MY(size_max) = 36;
	MY(tex_min) = 42;
	MY(tex_max) = 42;
	MY(type) = "smoke";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// inner cloud of smoke
SUB(electro_impact) {
	MY(airfriction) = 30;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x629dff";
	MY(color_max) = "0x0018ff";
	MY(count) = 30;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(sizeincrease) = 50;
	MY(size_min) = 20;
	MY(size_max) = 24;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '320.0 320.0 320.0';
}

DEF(electro_ballexplode);
// decal
SUB(electro_ballexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.1 4.4 10.0';
	MY(lightradiusfade) = 250;
	MY(lightradius) = 250;
	MY(originjitter) = '17.0 17.0 17.0';
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// flare effect
SUB(electro_ballexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// cloud of bouncing sparks
SUB(electro_ballexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0xFDFFD9";
	MY(color_max) = "0xFDFFD9";
	MY(count) = 64;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(stretchfactor) = 0.400000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// inner cloud of smoke
SUB(electro_ballexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 8;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '32.0 32.0 32.0';
}

DEF(electro_combo);
// decal
SUB(electro_combo) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 5.0 6.0';
	MY(lightradiusfade) = 300;
	MY(lightradius) = 400;
	MY(originjitter) = '17.0 17.0 17.0';
	MY(size_min) = 64;
	MY(size_max) = 64;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// flare effect
SUB(electro_combo) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// large sparks
SUB(electro_combo) {
	MY(airfriction) = 6;
	MY(alpha_min) = 156;
	MY(alpha_max) = 156;
	MY(alpha_fade) = 156;
	MY(bounce) = 2;
	MY(color_min) = "0x2030FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 5;
	MY(liquidfriction) = 16;
	MY(sizeincrease) = 50;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_max) = 7;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
SUB(electro_combo) {
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 500;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xa9cacf";
	MY(color_max) = "0x0054ff";
	MY(count) = 32;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(stretchfactor) = 2;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '128.0 128.0 128.0';
	MY(velocitymultiplier) = 0.300000;
}
// inner cloud of smoke
SUB(electro_combo) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 0.125000;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '32.0 32.0 32.0';
}
// shockwave
SUB(electro_combo) {
	MY(alpha_min) = 64;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 40;
	MY(color_min) = "0xa9cacf";
	MY(color_max) = "0x0054ff";
	MY(countabsolute) = 1;
	MY(size_min) = 120;
	MY(size_max) = 120;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 0.300000;
}

DEF(crylink_muzzleflash);
SUB(crylink_muzzleflash) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 2024;
	MY(color_min) = "0xdd9cff";
	MY(color_max) = "0xff0090";
	MY(count) = 0.500000;
	MY(lightcolor) = '1.6 0.2 2.0';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(size_min) = 15;
	MY(size_max) = 20;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 0.010000;
}
SUB(crylink_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xA080C0";
	MY(color_max) = "0xA080C0";
	MY(count) = 5;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(stretchfactor) = 1.500000;
	MY(tex_min) = 35;
	MY(tex_max) = 36;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 200.0';
	MY(velocitymultiplier) = 0.300000;
}

DEF(crylink_impact);
// decal
SUB(crylink_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '12.0 12.0 12.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// purple flare effect
SUB(crylink_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x504060";
	MY(color_max) = "0x504060";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// purple sparks
SUB(crylink_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0xA040C0";
	MY(color_max) = "0xA040C0";
	MY(count) = 40;
	MY(size_min) = 6;
	MY(size_max) = 6;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// purple splash
SUB(crylink_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 1.500000;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
}
// purple splash
SUB(crylink_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 3;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

DEF(nex_muzzleflash);
SUB(nex_muzzleflash) {
	MY(airfriction) = 9;
	MY(alpha_min) = 328;
	MY(alpha_max) = 328;
	MY(alpha_fade) = 4000;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x0072ff";
	MY(count) = 12;
	MY(lightcolor) = '2.0 2.5 3.0';
	MY(lightradiusfade) = 200;
	MY(lightradius) = 200;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = -100;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(stretchfactor) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '180.0 180.0 180.0';
	MY(velocitymultiplier) = 1.400000;
}
SUB(nex_muzzleflash) {
	MY(airfriction) = 9;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 50;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '600.0 600.0 600.0';
	MY(velocitymultiplier) = 1.500000;
}

// vortex beam
DEF(nex_beam);
SUB(nex_beam) {
	MY(airfriction) = 5;
	MY(alpha_min) = 64;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x1680A0";
	MY(color_max) = "0x1680A0";
	MY(sizeincrease) = 2;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_min) = 32;
	MY(tex_max) = 32;
	MY(trailspacing) = 64;
	MY(type) = "static";
}
// drifting smoke
SUB(nex_beam) {
	MY(airfriction) = 9;
	MY(alpha_min) = 32;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 32;
	MY(color_min) = "0x5080A0";
	MY(color_max) = "0x5080A0";
	MY(sizeincrease) = 8;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(trailspacing) = 12;
	MY(type) = "static";
	MY(velocityjitter) = '64.0 64.0 64.0';
}
// bright core
SUB(nex_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1280;
	MY(color_min) = "0x80CDFF";
	MY(color_max) = "0x80CDFF";
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(trailspacing) = 12;
	MY(type) = "static";
}
// sparks
SUB(nex_beam) {
	MY(airfriction) = 5;
	MY(alpha_min) = 64;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 80;
	MY(color_min) = "0x1680A0";
	MY(color_max) = "0x1680A0";
	MY(gravity) = -0.010000;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 63;
	MY(tex_max) = 63;
	MY(trailspacing) = 16;
	MY(type) = "snow";
}

DEF(nex_impact);
// decal
SUB(nex_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 6.0 8.0';
	MY(lightradiusfade) = 250;
	MY(lightradius) = 200;
	MY(originjitter) = '14.0 14.0 14.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// rotating something
SUB(nex_impact) {
	MY(alpha_min) = 55;
	MY(alpha_max) = 55;
	MY(alpha_fade) = 50;
	MY(color_min) = "0x1680A0";
	MY(color_max) = "0x1680A0";
	MY(count) = 5;
	MY(startangle_min) = 180;
	MY(startangle_max) = -180;
	MY(spin_min) = 500;
	MY(spin_max) = -500;
	MY(sizeincrease) = 20;
	MY(size_min) = 25;
	MY(size_max) = 28;
	MY(tex_min) = 46;
	MY(tex_max) = 46;
	MY(type) = "smoke";
}
// shockwave
SUB(nex_impact) {
	MY(alpha_min) = 50;
	MY(alpha_max) = 50;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x1680A0";
	MY(color_max) = "0x1680A0";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 900;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "static";
}
// shockwave2
SUB(nex_impact) {
	MY(alpha_min) = 50;
	MY(alpha_max) = 50;
	MY(alpha_fade) = 100;
	MY(color_min) = "0x1680A0";
	MY(color_max) = "0x1680A0";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 500;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "static";
}
// flare effect
SUB(nex_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(tex_min) = 37;
	MY(tex_max) = 37;
	MY(type) = "static";
}
// small sparks which glow brightly but live briefly
SUB(nex_impact) {
	MY(airfriction) = 9;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 512;
	MY(bounce) = 2;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 64;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(stretchfactor) = 3;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '600.0 600.0 600.0';
	MY(velocitymultiplier) = 0.500000;
}
// small sparks that live longer
SUB(nex_impact) {
	MY(airfriction) = 2;
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 112;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 16;
	MY(gravity) = 1;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(stretchfactor) = 0.700000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 600.0';
	MY(velocitymultiplier) = 2.500000;
}

DEF(hagar_muzzleflash);
SUB(hagar_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 2;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(hagar_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xff8400";
	MY(color_max) = "0xff4200";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -400;
	MY(spin_max) = 400;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(stretchfactor) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 200.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(hagar_bounce);
SUB(hagar_bounce) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 2;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 300;
	MY(lightradius) = 60;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(hagar_bounce) {
	MY(airfriction) = 12;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 15;
	MY(gravity) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '600.0 600.0 600.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(hagar_explode);
// decal
SUB(hagar_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 1.0';
	MY(lightradiusfade) = 400;
	MY(lightradius) = 120;
	MY(originjitter) = '14.0 14.0 14.0';
	MY(size_min) = 28;
	MY(size_max) = 38;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// fire effect which make bright dot inside
SUB(hagar_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 80;
	MY(alpha_max) = 200;
	MY(alpha_fade) = 356;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xffe955";
	MY(color_max) = "0xff5a00";
	MY(count) = 3.500000;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 16;
	MY(size_max) = 26;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '156.0 156.0 156.0';
}
// fire effect which expands then slows
SUB(hagar_explode) {
	MY(airfriction) = 12;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 456;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 12;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 15;
	MY(size_min) = 20;
	MY(size_max) = 26;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '286.0 286.0 286.0';
}
// smoke
SUB(hagar_explode) {
	MY(airfriction) = 5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 500;
	MY(alpha_fade) = 600;
	MY(bounce) = 2;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 7;
	MY(notunderwater) = true;
	MY(sizeincrease) = 20;
	MY(size_min) = 20;
	MY(size_max) = 40;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '244.0 244.0 244.0';
}
// underwater bubbles
SUB(hagar_explode) {
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
// bouncing sparks
SUB(hagar_explode) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 684;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xffa35b";
	MY(color_max) = "0xfff2be";
	MY(count) = 4;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1;
	MY(size_max) = 0.100000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '224.0 224.0 224.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

DEF(rocketlauncher_muzzleflash);
SUB(rocketlauncher_muzzleflash) {
	MY(airfriction) = 2;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 10;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = 20;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 40.0';
	MY(velocitymultiplier) = -0.130000;
}
SUB(rocketlauncher_muzzleflash) {
	MY(airfriction) = 9;
	MY(alpha_min) = 10;
	MY(alpha_max) = 25;
	MY(alpha_fade) = 20;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 6;
	MY(originjitter) = '3.0 3.0 3.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_min) = 35;
	MY(tex_max) = 36;
	MY(type) = "smoke";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.300000;
}

// rocket trail
DEF(TR_ROCKET);
// smoke
SUB(TR_ROCKET) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 200;
	MY(bounce) = 1;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x666666";
	MY(lightcolor) = '6.0 3.0 1.0';
	MY(lightradius) = 150;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 11;
	MY(size_min) = 3;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(trailspacing) = 10;
	MY(type) = "smoke";
	MY(velocityjitter) = '3.0 3.0 3.0';
	MY(velocitymultiplier) = -0.020000;
}
// fire
SUB(TR_ROCKET) {
	MY(airfriction) = 8;
	MY(alpha_min) = 100;
	MY(alpha_max) = 144;
	MY(alpha_fade) = 588;
	MY(color_min) = "0xffdf72";
	MY(color_max) = "0x811200";
	MY(sizeincrease) = -30;
	MY(size_min) = 7;
	MY(size_max) = 7;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = -1.500000;
}
// bubbles
SUB(TR_ROCKET) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 16;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
	MY(velocitymultiplier) = -0.310000;
}
// sparks
SUB(TR_ROCKET) {
	MY(airfriction) = 5;
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 1866;
	MY(bounce) = 1;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(notunderwater) = true;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.500000;
	MY(size_max) = 0.500000;
	MY(stretchfactor) = 0.300000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(trailspacing) = 20;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = -0.310000;
}

// rocket explosion (bigger than mortar and hagar)
DEF(rocket_explode);
SUB(rocket_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 1.0';
	MY(lightradiusfade) = 750;
	MY(lightradius) = 400;
	MY(originjitter) = '23.0 23.0 23.0';
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// fire effect
SUB(rocket_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 32;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 45;
	MY(size_min) = 33;
	MY(size_max) = 44;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// fire effect 2
SUB(rocket_explode) {
	MY(airfriction) = 19;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 612;
	MY(bounce) = 2.500000;
	MY(color_min) = "0xea691b";
	MY(color_max) = "0xeed05a";
	MY(count) = 14;
	MY(liquidfriction) = 19;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 55;
	MY(size_min) = 33;
	MY(size_max) = 44;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '912.0 912.0 912.0';
}
// smoke
SUB(rocket_explode) {
	MY(airfriction) = 5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 450;
	MY(alpha_fade) = 456;
	MY(bounce) = 2;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 32;
	MY(notunderwater) = true;
	MY(sizeincrease) = 44;
	MY(size_min) = 20;
	MY(size_max) = 40;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '444.0 444.0 444.0';
}
// underwater bubbles
SUB(rocket_explode) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '144.0 144.0 144.0';
}
// underwatershockwave
SUB(rocket_explode) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 300;
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1900;
	MY(size_min) = 30;
	MY(size_max) = 30;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(underwater) = true;
	MY(velocitymultiplier) = 0.300000;
}
// bouncing sparks
SUB(rocket_explode) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 484;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xffa35b";
	MY(color_max) = "0xfff2be";
	MY(count) = 16;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1;
	MY(size_max) = 0.100000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '424.0 424.0 624.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}
// debris
SUB(rocket_explode) {
	MY(airfriction) = 0.500000;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 684;
	MY(bounce) = 1.600000;
	MY(color_min) = "0x6a3d25";
	MY(color_max) = "0xcac5b4";
	MY(count) = 12;
	MY(gravity) = 1.300000;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -1000;
	MY(spin_max) = 1000;
	MY(size_min) = 2;
	MY(size_max) = 6;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '324.0 324.0 524.0';
}

DEF(grapple_muzzleflash);
SUB(grapple_muzzleflash) {
	MY(lightcolor) = '1.0 0.0 0.0';
	MY(lightradiusfade) = 800;
	MY(lightradius) = 160;
}

DEF(grapple_impact);
SUB(grapple_impact) {
	MY(lightcolor) = '1.0 0.0 0.0';
	MY(lightradiusfade) = 800;
	MY(lightradius) = 160;
}

DEF(nex242_misc_laser_beam);
SUB(nex242_misc_laser_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xff0000";
	MY(color_max) = "0xff0000";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_beam_end);
SUB(nex242_misc_laser_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_beam_fast);
SUB(nex242_misc_laser_beam_fast) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 640;
	MY(color_min) = "0xff0000";
	MY(color_max) = "0xff0000";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 0.100000;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_beam_fast_end);
SUB(nex242_misc_laser_beam_fast_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_green_beam);
SUB(nex242_misc_laser_green_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x00ff00";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_green_beam_end);
SUB(nex242_misc_laser_green_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_blue_beam);
SUB(nex242_misc_laser_blue_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x0000ff";
	MY(color_max) = "0x0000ff";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_blue_beam_end);
SUB(nex242_misc_laser_blue_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_yellow_beam);
SUB(nex242_misc_laser_yellow_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xffff00";
	MY(color_max) = "0xffff00";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_yellow_beam_end);
SUB(nex242_misc_laser_yellow_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_cyan_beam);
SUB(nex242_misc_laser_cyan_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x00ffff";
	MY(color_max) = "0x00ffff";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_cyan_beam_end);
SUB(nex242_misc_laser_cyan_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_magenta_beam);
SUB(nex242_misc_laser_magenta_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xff00ff";
	MY(color_max) = "0xff00ff";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_magenta_beam_end);
SUB(nex242_misc_laser_magenta_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_white_beam);
SUB(nex242_misc_laser_white_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xffffff";
	MY(color_max) = "0xffffff";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_white_beam_end);
SUB(nex242_misc_laser_white_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_black_beam);
SUB(nex242_misc_laser_black_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x000000";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_black_beam_end);
SUB(nex242_misc_laser_black_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

DEF(nex242_misc_laser_orange_beam);
SUB(nex242_misc_laser_orange_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xff6600";
	MY(color_max) = "0xff6600";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}

DEF(nex242_misc_laser_orange_beam_end);
SUB(nex242_misc_laser_orange_beam_end) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = -1;
	MY(color_min) = "0x8f4333";
	MY(color_max) = "0xfff31b";
	MY(count) = 0.500000;
	MY(gravity) = 1;
	MY(size_min) = 0.400000;
	MY(size_max) = 0.400000;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 100;
}

// bigger crylink impact effect
DEF(crylink_impactbig);
// decal
SUB(crylink_impactbig) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '12.0 12.0 12.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// purple flare effect
SUB(crylink_impactbig) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x504060";
	MY(color_max) = "0x504060";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// purple sparks
SUB(crylink_impactbig) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0xA040C0";
	MY(color_max) = "0xA040C0";
	MY(count) = 40;
	MY(size_min) = 6;
	MY(size_max) = 6;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// purple splash
SUB(crylink_impactbig) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 1.500000;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
}
// purple splash
SUB(crylink_impactbig) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 3;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

#include "effectinfo_gentle.inc"

DEF(laser_deadly);
// decal
SUB(laser_deadly) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 56;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// dust/smoke drifting away from the impact
SUB(laser_deadly) {
	MY(airfriction) = 7;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xFFFFFF";
	MY(count) = 0.025000;
	MY(liquidfriction) = 16;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 2;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '15.0 15.0 15.0';
	MY(velocitymultiplier) = 20;
}
// sparks
SUB(laser_deadly) {
	MY(airfriction) = 5;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 768;
	MY(bounce) = 1;
	MY(color_min) = "0xFDFFD9";
	MY(color_max) = "0xFDFFD9";
	MY(count) = 0.025000;
	MY(gravity) = 1;
	MY(notunderwater) = true;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.600000;
	MY(size_max) = 0.600000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 100;
}

DEF(torch_small);
// fire
SUB(torch_small) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 8;
	MY(gravity) = -0.500000;
	MY(originjitter) = '5.0 5.0 5.0';
	MY(sizeincrease) = -1;
	MY(size_min) = 1;
	MY(size_max) = 11;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '1.0 1.0 50.0';
}
// smoke
SUB(torch_small) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 4;
	MY(gravity) = -0.300000;
	MY(originjitter) = '3.0 3.0 3.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

DEF(fountain01);
SUB(fountain01) {
	MY(alpha_max) = 100;
	MY(alpha_fade) = 100;
	MY(bounce) = 1;
	MY(color_min) = "0x7cbaff";
	MY(color_max) = "0xcfd1ff";
	MY(count) = 16;
	MY(gravity) = 0.600000;
	MY(originjitter) = '5.0 5.0 5.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 10;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(type) = "snow";
	MY(velocityjitter) = '81.0 81.0 150.0';
	MY(velocitymultiplier) = 2;
}

DEF(hookbomb_explode);
// decal
SUB(hookbomb_explode) {
	MY(airfriction) = 10;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(count) = 25;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = -160;
	MY(size_min) = 150;
	MY(size_max) = 200;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
	MY(velocityjitter) = '550.0 550.0 550.0';
}
// decal in the air
SUB(hookbomb_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 265;
	MY(alpha_fade) = 100;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(countabsolute) = 3;
	MY(originoffset) = '0.0 0.0 6.0';
	MY(sizeincrease) = -60;
	MY(size_min) = 160;
	MY(size_max) = 200;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
}
// decal on the ground
SUB(hookbomb_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 80;
	MY(size_max) = 100;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "decal";
}
// some sparks
SUB(hookbomb_explode) {
	MY(airfriction) = 2;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 456;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(count) = 30;
	MY(gravity) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = -60;
	MY(size_min) = 20;
	MY(size_max) = 30;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "spark";
	MY(velocityjitter) = '1900.0 1900.0 1300.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(EF_MGTURRETTRAIL);
// smoke
SUB(EF_MGTURRETTRAIL) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 196;
	MY(alpha_fade) = 768;
	MY(color_min) = "0xd0d0a0";
	MY(color_max) = "0xffffff";
	MY(gravity) = -0.010000;
	MY(notunderwater) = true;
	MY(sizeincrease) = -8;
	MY(size_min) = 5;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(trailspacing) = 10;
	MY(type) = "smoke";
}
// bubbles
SUB(EF_MGTURRETTRAIL) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 32;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

DEF(fire_big);
// fire
SUB(fire_big) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 356;
	MY(alpha_fade) = 512;
	MY(bounce) = 2;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 26;
	MY(gravity) = -0.500000;
	MY(originjitter) = '33.0 33.0 33.0';
	MY(sizeincrease) = -3;
	MY(size_min) = 11;
	MY(size_max) = 31;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(fire_big) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 2;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 11;
	MY(gravity) = -0.300000;
	MY(originjitter) = '44.0 44.0 44.0';
	MY(sizeincrease) = 11;
	MY(size_min) = 22;
	MY(size_max) = 33;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

#define flare(name, colormin, colormax) \
	DEF(name##_flare); \
	SUB(name##_flare) /* smoke */ { \
		MY(alpha_min) = 200; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 160; \
		MY(bounce) = 1; \
		MY(color_min) = colormin; \
		MY(color_max) = colormax; \
		MY(count) = 10.500000; \
		MY(gravity) = -0.240000; \
		MY(originjitter) = '2.0 2.0 0.0'; \
		MY(sizeincrease) = 11; \
		MY(size_min) = 1; \
		MY(size_max) = 11; \
		MY(tex_max) = 8; \
		MY(type) = "alphastatic"; \
		MY(velocityjitter) = '15.0 15.0 30.0'; \
	}

flare(red, 	"0xff0000", "0xdc7171")
flare(blue, "0x0000ff", "0x7194dc")
#undef flare

DEF(smoke_ring);
// smoke
SUB(smoke_ring) {
	MY(airfriction) = 3;
	MY(alpha_min) = 100;
	MY(alpha_max) = 156;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.100000;
	MY(color_min) = "0x111111";
	MY(color_max) = "0x979797";
	MY(count) = 45;
	MY(gravity) = 0.100000;
	MY(notunderwater) = true;
	MY(sizeincrease) = 21;
	MY(size_min) = 1;
	MY(size_max) = 11;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '190.0 190.0 50.0';
}

DEF(smoke_large);
// smoke
SUB(smoke_large) {
	MY(airfriction) = 7;
	MY(alpha_min) = 140;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 190;
	MY(bounce) = 1.100000;
	MY(color_min) = "0x9e895f";
	MY(color_max) = "0xffd39b";
	MY(count) = 25;
	MY(gravity) = -0.150000;
	MY(notunderwater) = true;
	MY(sizeincrease) = 21;
	MY(size_min) = 11;
	MY(size_max) = 21;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '390.0 390.0 390.0';
}

DEF(sparks);
SUB(sparks) {
	MY(airfriction) = 3;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 15;
	MY(gravity) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 200.0';
	MY(velocitymultiplier) = 1.500000;
}

DEF(electricity_sparks);
SUB(electricity_sparks) {
	MY(airfriction) = 3;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 556;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x807aff";
	MY(color_max) = "0x4463d5";
	MY(count) = 35;
	MY(gravity) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(steam);
SUB(steam) {
	MY(airfriction) = 5;
	MY(alpha_min) = 140;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 190;
	MY(bounce) = 1.100000;
	MY(color_min) = "0xfffbdf";
	MY(color_max) = "0xffffff";
	MY(count) = 1;
	MY(gravity) = -0.250000;
	MY(notunderwater) = true;
	MY(sizeincrease) = 7;
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '19.0 19.0 19.0';
	MY(velocitymultiplier) = 14;
}

DEF(smoking);
SUB(smoking) {
	MY(airfriction) = -1;
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 100;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x292929";
	MY(color_max) = "0x000000";
	MY(count) = 10;
	MY(gravity) = -0.100000;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 10;
	MY(size_max) = 40;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '5.0 5.0 20.0';
}

// golden dust (create it once per second to cover large area in small yellow particles)
DEF(goldendust);
SUB(goldendust) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 70;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xff9600";
	MY(color_max) = "0xffefb8";
	MY(count) = 25;
	MY(originjitter) = '500.0 500.0 500.0';
	MY(sizeincrease) = -0.300000;
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "snow";
	MY(velocityjitter) = '0.1 0.1 0.1';
}

DEF(healing_fx);
SUB(healing_fx) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 170;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xff0000";
	MY(color_max) = "0xff0000";
	MY(count) = 25;
	MY(gravity) = -0.100000;
	MY(originjitter) = '5.0 5.0 100.0';
	MY(sizeincrease) = -0.050000;
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '50.0 50.0 0.0';
}

DEF(armorrepair_fx);
SUB(armorrepair_fx) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 170;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x00ff00";
	MY(count) = 25;
	MY(gravity) = -0.100000;
	MY(originjitter) = '5.0 5.0 50.0';
	MY(sizeincrease) = -0.050000;
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '50.0 50.0 0.0';
}

DEF(ammoregen_fx);
SUB(ammoregen_fx) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 170;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x0000ff";
	MY(color_max) = "0x0000ff";
	MY(count) = 25;
	MY(gravity) = -0.100000;
	MY(originjitter) = '5.0 5.0 50.0';
	MY(sizeincrease) = -0.050000;
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '50.0 50.0 0.0';
}

// red-yellow flame like fx
DEF(rage);
SUB(rage) {
	MY(airfriction) = 2;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 190;
	MY(color_min) = "0xff0000";
	MY(color_max) = "0xff7800";
	MY(count) = 2.500000;
	MY(gravity) = -0.060000;
	MY(originjitter) = '5.0 5.0 5.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 35;
	MY(tex_max) = 36;
	MY(type) = "smoke";
	MY(velocityjitter) = '25.0 25.0 25.0';
}

// pieces of glass or ice falling on the floor
DEF(iceorglass);
SUB(iceorglass) {
	MY(airfriction) = 3;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(bounce) = 2;
	MY(color_min) = "0xffffff";
	MY(color_max) = "0xb2d3e6";
	MY(count) = 15;
	MY(gravity) = 1.300000;
	MY(originjitter) = '30.0 30.0 30.0';
	MY(size_min) = 3;
	MY(size_max) = 7;
	MY(tex_min) = 44;
	MY(tex_max) = 44;
	MY(time_min) = 1;
	MY(time_max) = 3;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '100.0 100.0 100.0';
}

// cover small area in poison gas, spawn it once per second
DEF(poisonfield);
SUB(poisonfield) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 50;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x7db843";
	MY(count) = 15;
	MY(gravity) = -0.010000;
	MY(originjitter) = '333.0 333.0 50.0';
	MY(sizeincrease) = 30;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '5.0 5.0 5.0';
}

// cover small area in dark fog, spawn it once per second
DEF(darkfield);
SUB(darkfield) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 50;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x600089";
	MY(color_max) = "0x000000";
	MY(count) = 10;
	MY(gravity) = -0.010000;
	MY(originjitter) = '333.0 333.0 0.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '5.0 5.0 30.0';
}
SUB(darkfield) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 50;
	MY(color_min) = "0x600089";
	MY(color_max) = "0x000000";
	MY(count) = 5;
	MY(gravity) = -0.001000;
	MY(originjitter) = '333.0 333.0 0.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
}

// cover small area in icy mist, spawn it once per second
DEF(icefield);
SUB(icefield) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 50;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x008aff";
	MY(color_max) = "0x75e7ff";
	MY(count) = 10;
	MY(gravity) = -0.010000;
	MY(originjitter) = '333.0 333.0 0.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '5.0 5.0 30.0';
}
SUB(icefield) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 50;
	MY(color_min) = "0x008aff";
	MY(color_max) = "0x75e7ff";
	MY(count) = 5;
	MY(gravity) = -0.001000;
	MY(originjitter) = '333.0 333.0 0.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
}

// cover very small area in flames, spawn it 3 times per second (or more often to get better looking fire at cost of fps hit )
DEF(firefield);
// flames that go up
SUB(firefield) {
	MY(airfriction) = 1;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 100;
	MY(gravity) = -0.060000;
	MY(originjitter) = '180.0 180.0 0.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '5.0 5.0 30.0';
}
// flames that stay on the ground
SUB(firefield) {
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 50;
	MY(originjitter) = '180.0 180.0 0.0';
	MY(sizeincrease) = 40;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
}
// smoke
SUB(firefield) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 70;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 20;
	MY(gravity) = -0.020000;
	MY(originjitter) = '180.0 180.0 0.0';
	MY(sizeincrease) = 7;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// flamethrower, spawn it as fast as you can  20 times per second or more, it needs direction
DEF(flamethrower);
// fast fire
SUB(flamethrower) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 250;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 3;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 11.0';
	MY(velocitymultiplier) = 30;
}
// slow fire
SUB(flamethrower) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 2.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 40.0';
	MY(velocitymultiplier) = 20;
}
// very slow and small fire
SUB(flamethrower) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 1.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 10;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '30.0 30.0 30.0';
	MY(velocitymultiplier) = 10;
}
// decreasing fire
SUB(flamethrower) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 2;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = -10;
	MY(size_min) = 20;
	MY(size_max) = 30;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '10.0 10.0 10.0';
	MY(velocitymultiplier) = 15;
}
// smoke
SUB(flamethrower) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 90;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 0.500000;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 7;
	MY(size_min) = 5;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocitymultiplier) = 20;
	MY(velocityoffset) = '0.0 0.0 10.0';
}

// port-o-launch trail
DEF(TR_WIZSPIKE);
// glowing vapor trail
SUB(TR_WIZSPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 968;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x404040";
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradius) = 90;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocitymultiplier) = -0.100000;
}
// bright sparks
SUB(TR_WIZSPIKE) {
	MY(airfriction) = 12;
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 1866;
	MY(bounce) = 1;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x404040";
	MY(count) = 1.500000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = -20;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_min) = 42;
	MY(tex_max) = 42;
	MY(trailspacing) = 12;
	MY(type) = "snow";
	MY(velocityjitter) = '50.0 50.0 50.0';
	MY(velocityoffset) = '0.0 0.0 15.0';
}

// TAG trail
DEF(TR_VORESPIKE);
// glowing vapor trail
SUB(TR_VORESPIKE) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 968;
	MY(color_min) = "0x804000";
	MY(color_max) = "0x804000";
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradius) = 90;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocitymultiplier) = -0.100000;
}
// bright sparks
SUB(TR_VORESPIKE) {
	MY(airfriction) = 12;
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 1866;
	MY(bounce) = 1;
	MY(color_min) = "0xff8000";
	MY(color_max) = "0xff8000";
	MY(count) = 1.500000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = -20;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_min) = 42;
	MY(tex_max) = 42;
	MY(trailspacing) = 12;
	MY(type) = "snow";
	MY(velocityjitter) = '50.0 50.0 50.0';
	MY(velocityoffset) = '0.0 0.0 15.0';
}

DEF(flac_explode);
SUB(flac_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 1.0';
	MY(lightradiusfade) = 400;
	MY(lightradius) = 150;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(size_min) = 18;
	MY(size_max) = 28;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// fire effect which make bright dot inside
SUB(flac_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 456;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xffe955";
	MY(color_max) = "0xff5a00";
	MY(count) = 3;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 6;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '156.0 156.0 156.0';
}
// fire effect which expands then slows
SUB(flac_explode) {
	MY(airfriction) = 12;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 456;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 6;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 15;
	MY(size_min) = 10;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
// smoke
SUB(flac_explode) {
	MY(airfriction) = 5;
	MY(alpha_min) = 500;
	MY(alpha_max) = 600;
	MY(alpha_fade) = 556;
	MY(bounce) = 2;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 5;
	MY(notunderwater) = true;
	MY(sizeincrease) = 20;
	MY(size_min) = 10;
	MY(size_max) = 20;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '244.0 244.0 244.0';
}
// underwater bubbles
SUB(flac_explode) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 8;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '96.0 96.0 96.0';
}
// bouncing sparks
SUB(flac_explode) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 4;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// bullet trail (somewhat like a tracer)
DEF(tr_bullet);
SUB(tr_bullet) {
	MY(alpha) = '500 600 10000';
	MY(color_min) = "0xf03000";
	MY(color_max) = "0xff6010";
	MY(countabsolute) = 1;
	MY(sizeincrease) = -3;
	MY(size_min) = 0.6;
	MY(size_max) = 0.8;
	my(tex_min) = 200;
	my(tex_max) = 200;
	MY(type) = "beam";
}
SUB(tr_bullet) {
	MY(airfriction) = -4;
	MY(alpha) = '256 256 350';
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(notunderwater) = true;
	MY(sizeincrease) = 0.4;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 0;
	MY(tex_max) = 8;
	MY(trailspacing) = 16;
	MY(type) = "smoke";
	MY(velocityjitter) = '4 4 4';
}
SUB(tr_bullet) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 128;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 0.5;
	MY(size_max) = 0.6;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 16;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// smoke emitter for small pipes
DEF(smoking_smallemitter);
SUB(smoking_smallemitter) {
	MY(airfriction) = -1;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 100;
	MY(color_min) = "0x292929";
	MY(color_max) = "0x000000";
	MY(count) = 10;
	MY(gravity) = -0.100000;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 6;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '5.0 5.0 20.0';
}

// crylink trail
DEF(TR_CRYLINKPLASMA);
// plasma smoke
SUB(TR_CRYLINKPLASMA) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x5522aa";
	MY(color_max) = "0x6622ff";
	MY(sizeincrease) = 8;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 32;
	MY(tex_max) = 32;
	MY(trailspacing) = 128;
	MY(type) = "static";
	MY(velocityjitter) = '8.0 8.0 8.0';
	MY(velocitymultiplier) = -0.010000;
}
// crylink main trail
SUB(TR_CRYLINKPLASMA) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 2600;
	MY(color_min) = "0x5522aa";
	MY(color_max) = "0x6622ff";
	MY(sizeincrease) = 15;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 3;
	MY(tex_max) = 3;
	MY(trailspacing) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '2.0 2.0 2.0';
	MY(velocitymultiplier) = 0.010000;
}

DEF(cherryblossom);
SUB(cherryblossom) {
	MY(airfriction) = 1;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 32;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xb123ff";
	MY(color_max) = "0xb183ff";
	MY(count) = 1.500000;
	MY(gravity) = 0.050000;
	MY(liquidfriction) = 1;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1.500000;
	MY(size_max) = 2;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 0.0';
}

DEF(alien_blood);
SUB(alien_blood) {
	MY(airfriction) = 0.400000;
	MY(alpha_min) = 1560;
	MY(alpha_max) = 2560;
	MY(alpha_fade) = 7000;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xDC9BCD";
	MY(color_max) = "0xDC9BCD";
	MY(count) = 0.400000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 11;
	MY(staincolor_min) = "0xDC9BCD";
	MY(staincolor_max) = "0xDC9BCD";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 25;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "spark";
	MY(velocityjitter) = '99.0 99.0 55.0';
}
// blood mist
SUB(alien_blood) {
	MY(alpha_min) = 3000;
	MY(alpha_max) = 5560;
	MY(alpha_fade) = 12000;
	MY(blend) = "invmod";
	MY(color_min) = "0xDC9BCD";
	MY(color_max) = "0xDC9BCD";
	MY(countabsolute) = 1;
	MY(originjitter) = '11.0 11.0 11.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 25;
	MY(size_max) = 30;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "smoke";
}

DEF(robot_blood);
SUB(robot_blood) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xff3000";
	MY(color_max) = "0xff7373";
	MY(count) = 0.167000;
	MY(gravity) = 1;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "spark";
	MY(velocityjitter) = '264.0 264.0 264.0';
	MY(velocityoffset) = '0.0 0.0 100.0';
}
// shockwave
SUB(robot_blood) {
	MY(alpha_max) = 90;
	MY(alpha_fade) = 1000;
	MY(color_min) = "0xff8400";
	MY(color_max) = "0xffbb72";
	MY(countabsolute) = 1;
	MY(originjitter) = '11.0 11.0 11.0';
	MY(sizeincrease) = 800;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 74;
	MY(tex_max) = 74;
	MY(type) = "smoke";
}
// electo sparks
SUB(robot_blood) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 5120;
	MY(color_min) = "0xff3000";
	MY(color_max) = "0xff8585";
	MY(count) = 0.100000;
	MY(originjitter) = '41.0 41.0 21.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(size_min) = 20;
	MY(size_max) = 40;
	MY(tex_min) = 71;
	MY(tex_max) = 73;
	MY(type) = "smoke";
}

DEF(alien_TR_BLOOD);
SUB(alien_TR_BLOOD) {
	MY(airfriction) = -2;
	MY(alpha_min) = 384;
	MY(alpha_max) = 984;
	MY(alpha_fade) = 1492;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xC080B0";
	MY(color_max) = "0xC080B0";
	MY(gravity) = 0.400000;
	MY(liquidfriction) = 1;
	MY(sizeincrease) = -5;
	MY(size_min) = 4;
	MY(size_max) = 19;
	MY(staincolor_min) = "0xC080B0";
	MY(staincolor_max) = "0xC080B0";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 7;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 20;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = -0.100000;
}

// splash around gib
SUB(TR_BLOOD) {
	MY(alpha_min) = 684;
	MY(alpha_max) = 684;
	MY(alpha_fade) = 7492;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFF";
	MY(sizeincrease) = 500;
	MY(size_min) = 4;
	MY(size_max) = 6;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 42;
	MY(type) = "blood";
}

DEF(robot_TR_BLOOD);
SUB(robot_TR_BLOOD) {
	MY(airfriction) = -2;
	MY(alpha_min) = 384;
	MY(alpha_max) = 984;
	MY(alpha_fade) = 1892;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(gravity) = 0.400000;
	MY(liquidfriction) = 1;
	MY(sizeincrease) = -6;
	MY(size_min) = 4;
	MY(size_max) = 13;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 3;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 6;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 16;
	MY(type) = "spark";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = -0.300000;
}
// fire
SUB(robot_TR_BLOOD) {
	MY(airfriction) = 4;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 900;
	MY(color_min) = "0x902010";
	MY(color_max) = "0xff3600";
	MY(gravity) = -1;
	MY(liquidfriction) = 4;
	MY(notunderwater) = true;
	MY(sizeincrease) = 10;
	MY(size_min) = 5;
	MY(size_max) = 20;
	MY(stretchfactor) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 16;
	MY(type) = "spark";
	MY(velocityjitter) = '44.0 44.0 44.0';
}
// arcs
SUB(robot_TR_BLOOD) {
	MY(alpha_min) = 1128;
	MY(alpha_max) = 1256;
	MY(alpha_fade) = 44900;
	MY(color_min) = "0xff3000";
	MY(color_max) = "0xff8585";
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(size_min) = 25;
	MY(size_max) = 30;
	MY(tex_min) = 71;
	MY(tex_max) = 73;
	MY(trailspacing) = 128;
	MY(type) = "smoke";
	MY(velocityjitter) = '44.0 44.0 44.0';
}

DEF(alien_TR_SLIGHTBLOOD);
SUB(alien_TR_SLIGHTBLOOD) {
	MY(airfriction) = 1;
	MY(alpha_min) = 384;
	MY(alpha_max) = 384;
	MY(alpha_fade) = 192;
	MY(bounce) = -1;
	MY(color_min) = "0xC080B0";
	MY(color_max) = "0xC080B0";
	MY(liquidfriction) = 4;
	MY(size_min) = 80;
	MY(size_max) = 80;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 64;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(robot_TR_SLIGHTBLOOD);
SUB(robot_TR_SLIGHTBLOOD) {
	MY(airfriction) = 1;
	MY(alpha_min) = 384;
	MY(alpha_max) = 384;
	MY(alpha_fade) = 192;
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(trailspacing) = 64;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(item_pickup);
// flare particle and light
SUB(item_pickup) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0xB0C5C4";
	MY(countabsolute) = 1;
	MY(size_min) = 8;
	MY(size_max) = 16;
	MY(type) = "static";
}
// cloud of particles which expand rapidly and then slow to form a ball
SUB(item_pickup) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1280;
	MY(color_min) = "0x63F2EA";
	MY(color_max) = "0xB0C5C4";
	MY(count) = 32;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

DEF(bloodshower);
SUB(bloodshower) {
	MY(alpha_min) = 156;
	MY(alpha_max) = 656;
	MY(alpha_fade) = 1664;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 125;
	MY(gravity) = 1;
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 28;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 3;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "spark";
	MY(velocityjitter) = '764.0 764.0 764.0';
}
// center blood
SUB(bloodshower) {
	MY(alpha_min) = 156;
	MY(alpha_max) = 656;
	MY(alpha_fade) = 1664;
	MY(blend) = "invmod";
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(countabsolute) = 0.100000;
	MY(originjitter) = '50.0 50.0 50.0';
	MY(sizeincrease) = 300;
	MY(size_min) = 1;
	MY(size_max) = 28;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "smoke";
}

DEF(alien_bloodshower);
SUB(alien_bloodshower) {
	MY(alpha_min) = 156;
	MY(alpha_max) = 656;
	MY(alpha_fade) = 1664;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xC080B0";
	MY(color_max) = "0xC080B0";
	MY(count) = 125;
	MY(gravity) = 1;
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 28;
	MY(staincolor_min) = "0xC080B0";
	MY(staincolor_max) = "0xC080B0";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 3;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "spark";
	MY(velocityjitter) = '764.0 764.0 764.0';
}
// center blood
SUB(bloodshower) {
	MY(alpha_min) = 156;
	MY(alpha_max) = 656;
	MY(alpha_fade) = 1664;
	MY(blend) = "invmod";
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(countabsolute) = 0.100000;
	MY(originjitter) = '50.0 50.0 50.0';
	MY(sizeincrease) = 300;
	MY(size_min) = 1;
	MY(size_max) = 28;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "smoke";
}

DEF(robot_bloodshower);
SUB(robot_bloodshower) {
	MY(alpha_min) = 156;
	MY(alpha_max) = 656;
	MY(alpha_fade) = 1664;
	MY(blend) = "invmod";
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(count) = 100;
	MY(gravity) = 1;
	MY(liquidfriction) = 4;
	MY(size_min) = 8;
	MY(size_max) = 28;
	MY(staincolor_min) = "0xC0D890";
	MY(staincolor_max) = "0xC0D890";
	MY(stainsize_min) = 1;
	MY(stainsize_max) = 2;
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(stretchfactor) = 3;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "spark";
	MY(velocityjitter) = '764.0 764.0 764.0';
}
// arc
SUB(robot_bloodshower) {
	MY(alpha_min) = 1128;
	MY(alpha_max) = 1256;
	MY(alpha_fade) = 4200;
	MY(color_min) = "0xff3000";
	MY(color_max) = "0xff8585";
	MY(count) = 2.500000;
	MY(originjitter) = '150.0 150.0 150.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 99;
	MY(spin_max) = -99;
	MY(size_min) = 25;
	MY(size_max) = 40;
	MY(tex_min) = 71;
	MY(tex_max) = 73;
	MY(type) = "smoke";
	MY(velocityjitter) = '44.0 44.0 44.0';
}
// shockwave
SUB(robot_bloodshower) {
	MY(alpha_min) = 11;
	MY(alpha_max) = 125;
	MY(alpha_fade) = 990;
	MY(color_min) = "0xff3000";
	MY(color_max) = "0xff8585";
	MY(count) = 2.500000;
	MY(sizeincrease) = 3000;
	MY(size_min) = 5;
	MY(size_max) = 50;
	MY(tex_min) = 74;
	MY(tex_max) = 74;
	MY(type) = "smoke";
}

#define ground_quake(name, colormin, colormax) \
	DEF(name##_ground_quake); \
	SUB(name##_ground_quake) /* smoke */ { \
		MY(airfriction) = 3; \
		MY(alpha_min) = 100; \
		MY(alpha_max) = 126; \
		MY(alpha_fade) = 200; \
		MY(bounce) = 1.100000; \
		MY(color_min) = "0x111111"; \
		MY(color_max) = "0xbbbbbb"; \
		MY(count) = 90; \
		MY(gravity) = 0.500000; \
		MY(notunderwater) = true; \
		MY(sizeincrease) = 100; \
		MY(size_min) = 20; \
		MY(size_max) = 50; \
		MY(tex_max) = 8; \
		MY(time_min) = 5; \
		MY(time_max) = 10; \
		MY(type) = "smoke"; \
		MY(velocityjitter) = '190.0 190.0 50.0'; \
	} \
	SUB(name##_ground_quake) { \
		MY(airfriction) = 4; \
		MY(alpha_min) = 100; \
		MY(alpha_max) = 126; \
		MY(alpha_fade) = 200; \
		MY(bounce) = 1.200000; \
		MY(color_min) = "0x111111"; \
		MY(color_max) = "0x979797"; \
		MY(count) = 40; \
		MY(gravity) = 0.200000; \
		MY(notunderwater) = true; \
		MY(sizeincrease) = 60; \
		MY(size_min) = 10; \
		MY(size_max) = 30; \
		MY(tex_max) = 8; \
		MY(time_min) = 10; \
		MY(time_max) = 15; \
		MY(type) = "smoke"; \
		MY(velocityjitter) = '190.0 190.0 50.0'; \
	} \
	SUB(name##_ground_quake) { \
		MY(alpha_min) = 200; \
		MY(alpha_max) = 356; \
		MY(alpha_fade) = 512; \
		MY(bounce) = 6; \
		MY(color_min) = colormin; \
		MY(color_max) = colormax; \
		MY(count) = 16; \
		MY(gravity) = -0.500000; \
		MY(originjitter) = '33.0 33.0 33.0'; \
		MY(sizeincrease) = 5; \
		MY(size_min) = 4; \
		MY(size_max) = 20; \
		MY(tex_min) = 48; \
		MY(tex_max) = 55; \
		MY(time_min) = 15; \
		MY(time_max) = 25; \
		MY(type) = "smoke"; \
		MY(velocityjitter) = '22.0 22.0 50.0'; \
	} \
	SUB(name##_ground_quake) /* smoke */ { \
		MY(alpha_min) = 200; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 200; \
		MY(bounce) = 2; \
		MY(color_min) = "0x000000"; \
		MY(color_max) = "0xffffff"; \
		MY(count) = 11; \
		MY(gravity) = -0.300000; \
		MY(originjitter) = '44.0 44.0 44.0'; \
		MY(sizeincrease) = 11; \
		MY(size_min) = 22; \
		MY(size_max) = 33; \
		MY(tex_max) = 8; \
		MY(time_min) = 25; \
		MY(time_max) = 35; \
		MY(type) = "alphastatic"; \
		MY(velocityjitter) = '11.0 11.0 50.0'; \
	} \
	/**/

ground_quake(red, 	"0x9E6A64", "0x91302D")
ground_quake(blue, 	"0x64679E", "0x2D4C91")
#undef ground_quake

#include "effectinfo_gentle_morphed.inc"

// Team / hit vaporizer effects
#define TE_TEI_G3(name, colormin1, colormax1, colormin2, colormax2) \
	DEF(TE_TEI_G3##name); \
	SUB(TE_TEI_G3##name) { \
		MY(alpha_min) = 128; \
		MY(alpha_max) = 128; \
		MY(alpha_fade) = 256; \
		MY(color_min) = colormin1; \
		MY(color_max) = colormax1; \
		MY(countabsolute) = 1; \
		MY(size_min) = 4; \
		MY(size_max) = 4; \
		MY(tex_min) = 200; \
		MY(tex_max) = 200; \
		MY(type) = "beam"; \
	} \
	SUB(TE_TEI_G3##name) { \
		MY(airfriction) = -4; \
		MY(alpha_min) = 256; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 512; \
		MY(color_min) = colormin2; \
		MY(color_max) = colormax2; \
		MY(sizeincrease) = 3; \
		MY(size_min) = 0.300000; \
		MY(size_max) = 0.300000; \
		MY(tex_min) = 46; \
		MY(tex_max) = 46; \
		MY(trailspacing) = 8; \
		MY(type) = "smoke"; \
		MY(velocityjitter) = '3.0 3.0 3.0'; \
	} \
	DEF(TE_TEI_G3##name##_HIT); \
	SUB(TE_TEI_G3##name##_HIT) { \
		MY(alpha_min) = 128; \
		MY(alpha_max) = 128; \
		MY(alpha_fade) = 256; \
		MY(color_min) = colormin1; \
		MY(color_max) = colormax1; \
		MY(countabsolute) = 1; \
		MY(size_min) = 8; \
		MY(size_max) = 8; \
		MY(tex_min) = 200; \
		MY(tex_max) = 200; \
		MY(type) = "beam"; \
	} \
	SUB(TE_TEI_G3##name##_HIT) /* rings */ { \
		MY(airfriction) = -4; \
		MY(alpha_min) = 256; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 512; \
		MY(color_min) = "0xFFFFFF"; \
		MY(color_max) = colormax1; \
		MY(sizeincrease) = -2; \
		MY(size_min) = 2; \
		MY(size_max) = 2; \
		MY(trailspacing) = 20; \
		MY(type) = "smoke"; \
		MY(velocityjitter) = '2.0 2.0 2.0'; \
	} \
	SUB(TE_TEI_G3##name##_HIT) { \
		MY(airfriction) = -4; \
		MY(alpha_min) = 256; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 512; \
		MY(color_min) = colormin1; \
		MY(color_max) = colormax1; \
		MY(sizeincrease) = -6; \
		MY(size_min) = 10; \
		MY(size_max) = 10; \
		MY(trailspacing) = 40; \
		MY(type) = "smoke"; \
	} \
	/**/
TE_TEI_G3(RED, "0xFF0000", "0xFF0011", "0x200000", "0x400000")
TE_TEI_G3(BLUE, "0x0000FF", "0x1100FF", "0x000020", "0x000040")
TE_TEI_G3(YELLOW, "0xffff00", "0xffff11", "0x202000", "0x404000")
TE_TEI_G3(PINK, "0xFF00FF", "0xFF11FF", "0x200020", "0x400040")
#undef TE_TEI_G3

#include "effectinfo_gentle_particlegibs.inc"

#include "effectinfo_onslaught.inc"

DEF(firemine);
SUB(firemine) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 250;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 5;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 2;
	MY(type) = "smoke";
	MY(velocityjitter) = '10.0 10.0 2.0';
}
// slowfire
SUB(firemine) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 5;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 2;
	MY(type) = "smoke";
	MY(velocityjitter) = '10.0 10.0 10.0';
}
// very slow and small fire
SUB(firemine) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 2;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '8.0 8.0 8.0';
}
// decreasing fire
SUB(firemine) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = -3;
	MY(size_min) = 5;
	MY(size_max) = 7;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '3.0 3.0 3.0';
}
// smoke
SUB(firemine) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 90;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 0.500000;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = 1;
	MY(size_min) = 1;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(trailspacing) = 8;
	MY(type) = "alphastatic";
	MY(velocityoffset) = '0.0 0.0 3.0';
}
// fastfire
SUB(firemine) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1600;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 1;
	MY(type) = "smoke";
}
// light only
SUB(firemine) {
	MY(lightcolor) = '2.7 2.7 0.6';
	MY(lightradiusfade) = 50000;
	MY(lightradius) = 50;
	MY(trailspacing) = 16;
}

DEF(fireball);
SUB(fireball) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 250;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 2;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 11.0';
}
// slow fire
SUB(fireball) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 2;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 40.0';
}
// very slow and small fire
SUB(fireball) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 10;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '30.0 30.0 30.0';
}
// decreasing fire
SUB(fireball) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = -10;
	MY(size_min) = 20;
	MY(size_max) = 30;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '10.0 10.0 10.0';
}
// smoke
SUB(fireball) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 90;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 0.500000;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 7;
	MY(size_min) = 5;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(trailspacing) = 8;
	MY(type) = "alphastatic";
	MY(velocityoffset) = '0.0 0.0 10.0';
}
// fast fire
SUB(fireball) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1600;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 0.500000;
	MY(size_min) = 48;
	MY(size_max) = 48;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 1;
	MY(type) = "smoke";
}
// light only
SUB(fireball) {
	MY(lightcolor) = '2.7 2.7 0.6';
	MY(lightradiusfade) = 3000;
	MY(lightradius) = 300;
	MY(trailspacing) = 16;
}

DEF(fireball_laser);
SUB(fireball_laser) {
	MY(alpha_min) = 192;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 2560;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(count) = 10;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(stretchfactor) = 0.700000;
	MY(type) = "spark";
	MY(velocityjitter) = '1.0 1.0 1.0';
	MY(velocitymultiplier) = 10;
}

// rocket explosion (bigger than mortar and hagar)
DEF(fireball_explode);
// decal
SUB(fireball_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '4.0 2.0 0.5';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 500;
	MY(originjitter) = '56.0 56.0 56.0';
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// flare effect
SUB(fireball_explode) {
	MY(alpha_min) = 192;
	MY(alpha_max) = 192;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x404040";
	MY(countabsolute) = 1;
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 35;
	MY(tex_max) = 37;
	MY(type) = "static";
}
// fire effect
SUB(fireball_explode) {
	MY(airfriction) = 4;
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x902010";
	MY(color_max) = "0xFFD080";
	MY(count) = 128;
	MY(liquidfriction) = 4;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// underwater bubbles
SUB(fireball_explode) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '144.0 144.0 144.0';
}
// bouncing sparks
SUB(fireball_explode) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 384;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 64;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(type) = "spark";
	MY(velocityjitter) = '384.0 384.0 384.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

DEF(fireball_muzzleflash);
SUB(fireball_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 2;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(fireball_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(fireball_preattack_muzzleflash);
SUB(fireball_preattack_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 2;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(fireball_preattack_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(fireball_bfgdamage);
SUB(fireball_bfgdamage) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(count) = 2;
	MY(lightcolor) = '2.0 1.5 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(fireball_bfgdamage) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(EF_FLAME);
// fire
SUB(EF_FLAME) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 356;
	MY(alpha_fade) = 512;
	MY(bounce) = 2;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 100;
	MY(gravity) = -0.500000;
	MY(originjitter) = '12.0 12.0 24.0';
	MY(originoffset) = '0.0 0.0 10.0';
	MY(sizeincrease) = -1;
	MY(size_min) = 5;
	MY(size_max) = 21;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(EF_FLAME) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 156;
	MY(alpha_fade) = 200;
	MY(bounce) = 2;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x444444";
	MY(count) = 30;
	MY(gravity) = -0.500000;
	MY(originjitter) = '6.0 6.0 24.0';
	MY(originoffset) = '0.0 0.0 40.0';
	MY(sizeincrease) = 6;
	MY(size_min) = 11;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// rifle bullet trail (somewhat like a tracer)
DEF(tr_rifle);
SUB(tr_rifle) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 2560;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(size_min) = 1.500000;
	MY(size_max) = 1.500000;
	MY(stretchfactor) = 1;
	MY(trailspacing) = 128;
	MY(type) = "spark";
	MY(velocitymultiplier) = 0.700000;
}
SUB(tr_rifle) {
	MY(airfriction) = -4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(notunderwater) = true;
	MY(sizeincrease) = 0.400000;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(trailspacing) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '4.0 4.0 4.0';
}
SUB(tr_rifle) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 128;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 32;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// rocket guiding start
DEF(rocket_guide);
// underwater bubbles
SUB(rocket_guide) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 2;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(size_min) = 1.500000;
	MY(size_max) = 1.500000;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '48.0 48.0 48.0';
	MY(velocitymultiplier) = -0.100000;
}
// bouncing sparks
SUB(rocket_guide) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 984;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(count) = 8;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(size_min) = 0.300000;
	MY(size_max) = 0.700000;
	MY(stretchfactor) = 0.400000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '156.0 156.0 156.0';
	MY(velocitymultiplier) = -0.300000;
	MY(velocityoffset) = '0.0 0.0 80.0';
}
SUB(rocket_guide) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 100;
	MY(alpha_fade) = 500;
	MY(color_min) = "0x903010";
	MY(color_max) = "0xFFD030";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 300;
	MY(size_min) = 10;
	MY(size_max) = 10;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
}

// gauntlet laser
DEF(laser_gauntlet);
SUB(laser_gauntlet) {
	MY(airfriction) = 10;
	MY(alpha_min) = 128;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xb44215";
	MY(color_max) = "0x880000";
	MY(count) = 3;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(sizeincrease) = -100;
	MY(size_min) = 7;
	MY(size_max) = 10;
	MY(stretchfactor) = 2.300000;
	MY(tex_min) = 43;
	MY(tex_max) = 43;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.200000;
}
SUB(laser_gauntlet) {
	MY(airfriction) = 12;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xff4200";
	MY(color_max) = "0xff0000";
	MY(count) = 6;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -100;
	MY(size_min) = 7;
	MY(size_max) = 9;
	MY(stretchfactor) = 2;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.200000;
}

DEF(laser_gauntletmuzzleflash);
// glow and light
SUB(laser_gauntletmuzzleflash) {
	MY(airfriction) = 10;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0x220000";
	MY(color_max) = "0x880000";
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.0 0.1 0.1';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 150;
	MY(sizeincrease) = -100;
	MY(size_min) = 10;
	MY(size_max) = 15;
	MY(stretchfactor) = 2;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
}
// electricity
SUB(laser_gauntletmuzzleflash) {
	MY(airfriction) = 10;
	MY(alpha_min) = 128;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xb44215";
	MY(color_max) = "0x880000";
	MY(count) = 3;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(sizeincrease) = -100;
	MY(size_min) = 7;
	MY(size_max) = 10;
	MY(stretchfactor) = 2.300000;
	MY(tex_min) = 43;
	MY(tex_max) = 43;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.200000;
}
// fire
SUB(laser_gauntletmuzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_min) = 256;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0xff4200";
	MY(color_max) = "0xff0000";
	MY(count) = 6;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -100;
	MY(size_min) = 7;
	MY(size_max) = 9;
	MY(stretchfactor) = 2;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 0.200000;
}

// torch flame, spawn it as fast as you can  20 times per second or more, supports direction but not required
DEF(torchflame);
// fast fire
SUB(torchflame) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 250;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 3;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 11.0';
	MY(velocitymultiplier) = 30;
}
// slow fire
SUB(torchflame) {
	MY(airfriction) = 1.200000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 2.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 20;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '40.0 40.0 40.0';
	MY(velocitymultiplier) = 20;
}
// very slow and small fire
SUB(torchflame) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 1.500000;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = 10;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '30.0 30.0 30.0';
	MY(velocitymultiplier) = 10;
}
// decreasing fire
SUB(torchflame) {
	MY(airfriction) = 0.300000;
	MY(alpha_min) = 50;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 2;
	MY(gravity) = -0.060000;
	MY(sizeincrease) = -10;
	MY(size_min) = 20;
	MY(size_max) = 30;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '10.0 10.0 10.0';
	MY(velocitymultiplier) = 15;
}
// smoke
SUB(torchflame) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 90;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 0.500000;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 7;
	MY(size_min) = 5;
	MY(size_max) = 15;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocitymultiplier) = 20;
	MY(velocityoffset) = '0.0 0.0 10.0';
}

#include "effectinfo_gentle_happy.inc"

DEF(electro_lightning);
SUB(electro_lightning) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.1 4.4 10.0';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 50;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
SUB(electro_lightning) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 206;
	MY(alpha_fade) = 1724;
	MY(color_min) = "0x2030FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 300;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = 10;
	MY(size_min) = 6;
	MY(size_max) = 6;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "spark";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 2000;
}
SUB(electro_lightning) {
	MY(airfriction) = 2;
	MY(alpha_min) = 110;
	MY(alpha_max) = 170;
	MY(alpha_fade) = 1500;
	MY(color_min) = "0xDDFDFF";
	MY(color_max) = "0xFDFDFF";
	MY(count) = 30;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 2;
	MY(size_max) = 5;
	MY(stretchfactor) = 1.500000;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.500000;
}
SUB(electro_lightning) {
	MY(airfriction) = 8;
	MY(alpha_min) = 110;
	MY(alpha_max) = 170;
	MY(alpha_fade) = 1500;
	MY(color_min) = "0xFDFDFF";
	MY(color_max) = "0xF9FDFF";
	MY(count) = 50;
	MY(gravity) = 1.300000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(stretchfactor) = 0.100000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '350.0 350.0 350.0';
	MY(velocitymultiplier) = 2.500000;
}

DEF(gauntlet_lightning);
SUB(gauntlet_lightning) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x280000";
	MY(color_max) = "0x280000";
	MY(count) = 300;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = 15;
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "spark";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 2000;
}
SUB(gauntlet_lightning) {
	MY(airfriction) = 2;
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xDD0000";
	MY(color_max) = "0xFD0000";
	MY(count) = 30;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 2;
	MY(size_max) = 5;
	MY(stretchfactor) = 1.500000;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.500000;
}
SUB(gauntlet_lightning) {
	MY(airfriction) = 8;
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 600;
	MY(color_min) = "0xFD0000";
	MY(color_max) = "0xF90000";
	MY(count) = 50;
	MY(gravity) = 1.300000;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(stretchfactor) = 0.100000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '350.0 350.0 350.0';
	MY(velocitymultiplier) = 2.500000;
}

DEF(crylink_joinexplode);
// decal
SUB(crylink_joinexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(originjitter) = '12.0 12.0 12.0';
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// purple flare effect
SUB(crylink_joinexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x504060";
	MY(color_max) = "0x504060";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 39;
	MY(tex_max) = 39;
	MY(type) = "static";
}
// purple sparks
SUB(crylink_joinexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(bounce) = 2;
	MY(color_min) = "0xA040C0";
	MY(color_max) = "0xA040C0";
	MY(count) = 40;
	MY(size_min) = 6;
	MY(size_max) = 6;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// purple splash
SUB(crylink_joinexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 1.500000;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
}
// purple splash
SUB(crylink_joinexplode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0xE070FF";
	MY(color_max) = "0xE070FF";
	MY(count) = 3;
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(type) = "static";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

// sparks for keepaway ball touch
DEF(kaball_sparks);
SUB(kaball_sparks) {
	MY(airfriction) = 3;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 556;
	MY(bounce) = 1.500000;
	MY(color_min) = "0xa9cacf";
	MY(color_max) = "0x0054ff";
	MY(count) = 35;
	MY(gravity) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '300.0 300.0 300.0';
	MY(velocitymultiplier) = 0.500000;
}

// weak rifle bullet trail (somewhat like a tracer)
DEF(tr_rifle_weak);
SUB(tr_rifle_weak) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 2560;
	MY(color_min) = "0x800000";
	MY(color_max) = "0xFF8020";
	MY(size_min) = 1.500000;
	MY(size_max) = 1.500000;
	MY(stretchfactor) = 1;
	MY(trailspacing) = 128;
	MY(type) = "spark";
	MY(velocitymultiplier) = 0.700000;
}
SUB(tr_rifle_weak) {
	MY(airfriction) = -4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(notunderwater) = true;
	MY(sizeincrease) = 0.400000;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(trailspacing) = 48;
	MY(type) = "smoke";
	MY(velocityjitter) = '4.0 4.0 4.0';
}
SUB(tr_rifle_weak) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 128;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 192;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// red smoke emiter
DEF(red_smoke);
SUB(red_smoke) {
	MY(airfriction) = -1;
	MY(alpha_min) = 32;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 32;
	MY(color_min) = "0xff8866";
	MY(color_max) = "0x331100";
	MY(count) = 2;
	MY(gravity) = -0.007000;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(size_min) = 60;
	MY(size_max) = 120;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 5;
}

// pipe smoke emiter
DEF(pipe_smoke);
SUB(pipe_smoke) {
	MY(airfriction) = -1;
	MY(alpha_min) = 32;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 48;
	MY(color_min) = "0x999999";
	MY(color_max) = "0x555555";
	MY(count) = 2;
	MY(gravity) = -0.015000;
	MY(startangle_max) = 360;
	MY(spin_min) = -180;
	MY(spin_max) = 180;
	MY(sizeincrease) = 35;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.0 0.0 5.0';
	MY(velocitymultiplier) = 15;
}

// seeker missile trail
DEF(TR_SEEKER);
SUB(TR_SEEKER) {
	MY(alpha_min) = 200;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 200;
	MY(bounce) = 1;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x666666";
	MY(lightcolor) = '6.0 3.0 1.0';
	MY(lightradius) = 100;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 11;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(tex_max) = 8;
	MY(trailspacing) = 10;
	MY(type) = "smoke";
	MY(velocityjitter) = '3.0 3.0 3.0';
	MY(velocitymultiplier) = -0.020000;
}
// fire
SUB(TR_SEEKER) {
	MY(airfriction) = 8;
	MY(alpha_min) = 100;
	MY(alpha_max) = 144;
	MY(alpha_fade) = 588;
	MY(color_min) = "0xffdf72";
	MY(color_max) = "0x811200";
	MY(sizeincrease) = -30;
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = -1.500000;
}
// bubbles
SUB(TR_SEEKER) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 16;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
	MY(velocitymultiplier) = -0.310000;
}
// sparks
SUB(TR_SEEKER) {
	MY(airfriction) = 5;
	MY(alpha_min) = 444;
	MY(alpha_max) = 512;
	MY(alpha_fade) = 1866;
	MY(bounce) = 1;
	MY(color_min) = "0xFFFDD9";
	MY(color_max) = "0xFFFDD9";
	MY(notunderwater) = true;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 0.500000;
	MY(size_max) = 0.500000;
	MY(stretchfactor) = 0.300000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(trailspacing) = 20;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = -0.310000;
}

#include "effectinfo_vehicles.inc"

// generic explosion size:big (biggest explosion ever)
DEF(explosion_big);
// decal
SUB(explosion_big) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 0.0';
	MY(lightradiusfade) = 1750;
	MY(lightradius) = 600;
	MY(originjitter) = '23.0 23.0 23.0';
	MY(size_min) = 172;
	MY(size_max) = 172;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// shockwave
SUB(explosion_big) {
	MY(alpha_min) = 56;
	MY(alpha_max) = 56;
	MY(alpha_fade) = 330;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 4400;
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "static";
}
// fire effect
SUB(explosion_big) {
	MY(airfriction) = 8;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 712;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 64;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '80.0 80.0 80.0';
	MY(sizeincrease) = 45;
	MY(size_min) = 133;
	MY(size_max) = 144;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '2512.0 2512.0 2512.0';
}
// fire rays
SUB(explosion_big) {
	MY(airfriction) = -5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 800;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 64;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(sizeincrease) = 45;
	MY(size_min) = 133;
	MY(size_max) = 144;
	MY(stretchfactor) = 10;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// smoke
SUB(explosion_big) {
	MY(airfriction) = 8;
	MY(alpha_min) = 300;
	MY(alpha_max) = 650;
	MY(alpha_fade) = 456;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 32;
	MY(notunderwater) = true;
	MY(sizeincrease) = 244;
	MY(size_min) = 50;
	MY(size_max) = 100;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '3444.0 3444.0 3444.0';
}
// bouncing sparks
SUB(explosion_big) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 1284;
	MY(color_min) = "0xffa35b";
	MY(color_max) = "0xfff2be";
	MY(count) = 34;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '160.0 160.0 160.0';
	MY(size_min) = 3;
	MY(size_max) = 4;
	MY(stretchfactor) = 0.700000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '924.0 924.0 924.0';
	MY(velocityoffset) = '0.0 0.0 370.0';
}
// debris
SUB(explosion_big) {
	MY(airfriction) = 0.500000;
	MY(alpha_min) = 444;
	MY(alpha_max) = 1356;
	MY(alpha_fade) = 1184;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xcac5b4";
	MY(count) = 16;
	MY(gravity) = 2.300000;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -1000;
	MY(spin_max) = 1000;
	MY(sizeincrease) = -5;
	MY(size_min) = 10;
	MY(size_max) = 16;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '1800.0 1800.0 1800.0';
	MY(velocityoffset) = '0.0 0.0 970.0';
}
// underwater bubbles
SUB(explosion_big) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '160.0 160.0 160.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '444.0 444.0 444.0';
}
// underwatershockwave
SUB(explosion_big) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 300;
	MY(countabsolute) = 1;
	MY(sizeincrease) = 2900;
	MY(size_min) = 30;
	MY(size_max) = 30;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(underwater) = true;
	MY(velocitymultiplier) = 0.300000;
}

// generic explosion size:medium (it leaves rising smoke for a longer time)
DEF(explosion_medium);
// shockwave
SUB(explosion_medium) {
	MY(alpha_min) = 56;
	MY(alpha_max) = 56;
	MY(alpha_fade) = 330;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 2400;
	MY(size_min) = 72;
	MY(size_max) = 72;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "static";
}
// fire effect
SUB(explosion_medium) {
	MY(airfriction) = 8;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 712;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 32;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '30.0 30.0 30.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -500;
	MY(spin_max) = 500;
	MY(sizeincrease) = 45;
	MY(size_min) = 133;
	MY(size_max) = 144;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '1512.0 1512.0 1512.0';
}
// fire effect 2
SUB(explosion_medium) {
	MY(airfriction) = 8;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 612;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 32;
	MY(gravity) = -2;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '30.0 30.0 30.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -150;
	MY(spin_max) = 150;
	MY(sizeincrease) = 40;
	MY(size_min) = 73;
	MY(size_max) = 94;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '1512.0 1512.0 1512.0';
}
// fire rays
SUB(explosion_medium) {
	MY(airfriction) = -3;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 800;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 14;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(sizeincrease) = 40;
	MY(size_min) = 43;
	MY(size_max) = 74;
	MY(stretchfactor) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// smoke
SUB(explosion_medium) {
	MY(airfriction) = 3;
	MY(alpha_min) = 300;
	MY(alpha_max) = 650;
	MY(alpha_fade) = 756;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 5;
	MY(notunderwater) = true;
	MY(originjitter) = '100.0 100.0 100.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -20;
	MY(spin_max) = 20;
	MY(sizeincrease) = -30;
	MY(size_min) = 250;
	MY(size_max) = 300;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '200.0 200.0 200.0';
}
// smoke 2
SUB(explosion_medium) {
	MY(airfriction) = 3;
	MY(alpha_min) = 300;
	MY(alpha_max) = 650;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 10;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '100.0 100.0 100.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -20;
	MY(spin_max) = 20;
	MY(sizeincrease) = 50;
	MY(size_min) = 50;
	MY(size_max) = 100;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '500.0 500.0 500.0';
	MY(velocityoffset) = '0.0 0.0 200.0';
}
// smoke rays
SUB(explosion_medium) {
	MY(alpha_min) = 140;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 13;
	MY(notunderwater) = true;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(sizeincrease) = 100;
	MY(size_min) = 150;
	MY(size_max) = 200;
	MY(stretchfactor) = 50;
	MY(tex_max) = 8;
	MY(type) = "spark";
	MY(velocityjitter) = '250.0 250.0 250.0';
}
// bouncing sparks
SUB(explosion_medium) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 984;
	MY(color_min) = "0xffa35b";
	MY(color_max) = "0xfff2be";
	MY(count) = 14;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '100.0 100.0 100.0';
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(stretchfactor) = 0.700000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '624.0 624.0 624.0';
	MY(velocityoffset) = '0.0 0.0 370.0';
}
// underwater bubbles
SUB(explosion_medium) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '160.0 160.0 160.0';
	MY(size_min) = 3;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '444.0 444.0 444.0';
}
// underwatershockwave
SUB(explosion_medium) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 300;
	MY(countabsolute) = 1;
	MY(sizeincrease) = 2900;
	MY(size_min) = 30;
	MY(size_max) = 30;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(underwater) = true;
	MY(velocitymultiplier) = 0.300000;
}

// generic explosion size:small (its fire only, made to support other explosions)
DEF(explosion_small);
// shockwave
SUB(explosion_small) {
	MY(alpha_min) = 56;
	MY(alpha_max) = 56;
	MY(alpha_fade) = 330;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 2400;
	MY(size_min) = 22;
	MY(size_max) = 22;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "static";
}
// fire effect
SUB(explosion_small) {
	MY(airfriction) = 5;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1212;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 16;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -500;
	MY(spin_max) = 500;
	MY(sizeincrease) = 45;
	MY(size_min) = 1;
	MY(size_max) = 44;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// fire effect 2
SUB(explosion_small) {
	MY(airfriction) = 8;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 812;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 16;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -150;
	MY(spin_max) = 150;
	MY(sizeincrease) = 40;
	MY(size_min) = 73;
	MY(size_max) = 94;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '912.0 912.0 912.0';
}
// fire rays
SUB(explosion_small) {
	MY(airfriction) = -3;
	MY(alpha_min) = 200;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1300;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 14;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '40.0 40.0 40.0';
	MY(sizeincrease) = 30;
	MY(size_min) = 13;
	MY(size_max) = 54;
	MY(stretchfactor) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '512.0 512.0 512.0';
}
// underwater bubbles
SUB(explosion_small) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 32;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '160.0 160.0 160.0';
	MY(size_min) = 1;
	MY(size_max) = 3;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '144.0 144.0 144.0';
}
// underwatershockwave
SUB(explosion_small) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 300;
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1200;
	MY(size_min) = 30;
	MY(size_max) = 30;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(underwater) = true;
}

// big smoke ( for spamming on damaged stuff )
DEF(smoke_big);
SUB(smoke_big) {
	MY(airfriction) = 4;
	MY(alpha_min) = 200;
	MY(alpha_max) = 750;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 3;
	MY(gravity) = -0.500000;
	MY(notunderwater) = true;
	MY(originjitter) = '55.0 55.0 55.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -20;
	MY(spin_max) = 20;
	MY(sizeincrease) = 15;
	MY(size_min) = 30;
	MY(size_max) = 60;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '140.0 140.0 200.0';
	MY(velocityoffset) = '0.0 0.0 200.0';
}

// small smoke ( more precise than big one, for spamming on damaged parts like raptors spinner )
DEF(smoke_small);
SUB(smoke_small) {
	MY(airfriction) = 4;
	MY(alpha_min) = 200;
	MY(alpha_max) = 750;
	MY(alpha_fade) = 200;
	MY(color_min) = "0x4F4B46";
	MY(color_max) = "0x000000";
	MY(count) = 3;
	MY(gravity) = -0.500000;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -20;
	MY(spin_max) = 20;
	MY(sizeincrease) = -10;
	MY(size_min) = 60;
	MY(size_max) = 100;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '40.0 40.0 400.0';
	MY(velocityoffset) = '0.0 0.0 200.0';
}

// metal impact effect
DEF(impact_metal);
SUB(impact_metal) {
	MY(alpha_min) = 25;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 50;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x886666";
	MY(count) = 1;
	MY(gravity) = -0.010000;
	MY(originjitter) = '20.0 20.0 5.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 3;
	MY(size_max) = 6;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}
// sparks
SUB(impact_metal) {
	MY(airfriction) = 2;
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 112;
	MY(bounce) = 1.800000;
	MY(color_min) = "0xFFCC22";
	MY(color_max) = "0xFF4422";
	MY(count) = 2;
	MY(gravity) = 1;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(stretchfactor) = 0.500000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 300.0';
	MY(velocitymultiplier) = 2;
}

// stone impact effect
DEF(impact_stone);
SUB(impact_stone) {
	MY(alpha_min) = 50;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 75;
	MY(color_min) = "0x000000";
	MY(color_max) = "0xcc9966";
	MY(count) = 1;
	MY(gravity) = -0.010000;
	MY(originjitter) = '20.0 20.0 5.0';
	MY(sizeincrease) = 15;
	MY(size_min) = 3;
	MY(size_max) = 6;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}
// debris
SUB(impact_stone) {
	MY(airfriction) = 0.500000;
	MY(alpha_min) = 450;
	MY(alpha_max) = 750;
	MY(alpha_fade) = 300;
	MY(bounce) = 1.200000;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x886644";
	MY(count) = 1;
	MY(gravity) = 1.300000;
	MY(notunderwater) = true;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -1000;
	MY(spin_max) = 1000;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '124.0 124.0 324.0';
}

// wood impact effect
DEF(impact_wood);
SUB(impact_wood) {
	MY(alpha_min) = 50;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 75;
	MY(color_min) = "0x000000";
	MY(color_max) = "0xcc9966";
	MY(count) = 1;
	MY(gravity) = -0.010000;
	MY(originjitter) = '20.0 20.0 5.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 3;
	MY(size_max) = 6;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}
// sparks
SUB(impact_wood) {
	MY(airfriction) = 2;
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 75;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x221100";
	MY(color_max) = "0x221100";
	MY(count) = 2;
	MY(gravity) = 1;
	MY(size_min) = 1;
	MY(size_max) = 8;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '180.0 180.0 260.0';
	MY(velocitymultiplier) = 2;
}

// flesh impact effect
DEF(impact_flesh);
SUB(impact_flesh) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x420000";
	MY(count) = 0.500000;
	MY(originjitter) = '11.0 11.0 11.0';
	MY(size_min) = 8;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}
// blood splash
SUB(impact_flesh) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 6;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '96.0 96.0 96.0';
	MY(velocitymultiplier) = 5;
}

// hagar trail
DEF(tr_hagar);
// smoke
SUB(tr_hagar) {
	MY(alpha_min) = 300;
	MY(alpha_max) = 400;
	MY(alpha_fade) = 780;
	MY(bounce) = 1;
	MY(color_min) = "0x101010";
	MY(color_max) = "0x000000";
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 3;
	MY(size_max) = 2;
	MY(tex_max) = 8;
	MY(trailspacing) = 4;
	MY(type) = "smoke";
	MY(velocityjitter) = '1.0 1.0 1.0';
	MY(velocitymultiplier) = -0.020000;
}
// fire
SUB(tr_hagar) {
	MY(airfriction) = 8;
	MY(alpha_min) = 100;
	MY(alpha_max) = 144;
	MY(alpha_fade) = 988;
	MY(color_min) = "0xffdf72";
	MY(color_max) = "0x811200";
	MY(notunderwater) = true;
	MY(sizeincrease) = -15;
	MY(size_min) = 5;
	MY(size_max) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(trailspacing) = 4;
	MY(type) = "static";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = -1;
}
// bubbles
SUB(tr_hagar) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 16;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// laser damage effect
DEF(damage_blaster);
SUB(damage_blaster) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 128;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x880000";
	MY(color_max) = "0xff4400";
	MY(count) = 3;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 8;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.4 0.4 0.6';
}

// shotgun damage effect, normal blood
DEF(damage_shotgun);
SUB(damage_shotgun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 0.600000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(damage_shotgun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x420000";
	MY(count) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 8;
	MY(size_max) = 16;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// shotgun damage effect, alien blood
DEF(alien_damage_shotgun);
SUB(alien_damage_shotgun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xDC9BCD";
	MY(color_max) = "0xDC9BCD";
	MY(count) = 0.600000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(alien_damage_shotgun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x204010";
	MY(count) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 8;
	MY(size_max) = 16;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// shotgun damage effect, robot blood
DEF(robot_damage_shotgun);
SUB(robot_damage_shotgun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(count) = 0.600000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(robot_damage_shotgun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x301860";
	MY(count) = 1;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 8;
	MY(size_max) = 16;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// machinegun damage effect, normal blood
DEF(damage_machinegun);
SUB(damage_machinegun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(damage_machinegun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x420000";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// machinegun damage effect, alien blood
DEF(alien_damage_machinegun);
SUB(alien_damage_machinegun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xDC9BCD";
	MY(color_max) = "0xDC9BCD";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(alien_damage_machinegun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x204010";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// machinegun damage effect, robot blood
DEF(robot_damage_machinegun);
SUB(robot_damage_machinegun) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(robot_damage_machinegun) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x301860";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// minelayer damage effect
DEF(damage_minelayer);
SUB(damage_minelayer) {
	MY(alpha_min) = 512;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 3;
	MY(gravity) = -0.500000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -15;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(damage_minelayer) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 2;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// mortar damage effect
DEF(damage_mortar);
SUB(damage_mortar) {
	MY(alpha_min) = 512;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 3;
	MY(gravity) = -0.500000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -15;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(damage_mortar) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 2;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// arc damage effect
DEF(damage_arc);
SUB(damage_arc) {
	MY(airfriction) = -0.650000;
	MY(alpha_min) = 48;
	MY(alpha_max) = 8;
	MY(alpha_fade) = 48;
	MY(color_min) = "0x66ffff";
	MY(color_max) = "0x2288ff";
	MY(count) = 2;
	MY(gravity) = -0.000100;
	MY(liquidfriction) = 0.600000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = 180;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = -14;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "static";
	MY(velocityjitter) = '6.0 6.0 12.0';
}
// plasma smoke
SUB(damage_arc) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x2244ff";
	MY(color_max) = "0x002266";
	MY(count) = 4;
	MY(notunderwater) = true;
	MY(originjitter) = '3.0 3.0 3.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 10;
	MY(size_min) = 3;
	MY(size_max) = 6;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.3 0.3 0.5';
}
// bouncing sparks
SUB(damage_arc) {
	MY(airfriction) = 1;
	MY(alpha_min) = 768;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x003090";
	MY(color_max) = "0x00CCFF";
	MY(count) = 0.500000;
	MY(gravity) = 0.150000;
	MY(liquidfriction) = 0.600000;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "spark";
	MY(velocityjitter) = '24.0 24.0 24.0';
}

// electro damage effect
DEF(damage_electro);
SUB(damage_electro) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 48;
	MY(alpha_max) = 8;
	MY(alpha_fade) = 48;
	MY(color_min) = "0x66ffff";
	MY(color_max) = "0x2288ff";
	MY(count) = 2;
	MY(gravity) = -0.000100;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '3.0 3.0 3.0';
	MY(startangle_min) = 180;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = -14;
	MY(size_min) = 6;
	MY(size_max) = 10;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "static";
	MY(velocityjitter) = '8.0 8.0 16.0';
}
// plasma smoke
SUB(damage_electro) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x2244ff";
	MY(color_max) = "0x002266";
	MY(count) = 4;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 10;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.4 0.4 0.6';
}
// bouncing sparks
SUB(damage_electro) {
	MY(airfriction) = 1;
	MY(alpha_min) = 768;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 256;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x003090";
	MY(color_max) = "0x00CCFF";
	MY(count) = 0.500000;
	MY(gravity) = 0.200000;
	MY(liquidfriction) = 0.800000;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(tex_min) = 66;
	MY(tex_max) = 68;
	MY(type) = "spark";
	MY(velocityjitter) = '32.0 32.0 32.0';
}

// crylink damage effect
DEF(damage_crylink);
SUB(damage_crylink) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 48;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 48;
	MY(color_min) = "0xff44ff";
	MY(color_max) = "0x9966ff";
	MY(count) = 2;
	MY(gravity) = -0.000100;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '3.0 3.0 3.0';
	MY(startangle_min) = 180;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = -8;
	MY(size_min) = 0.500000;
	MY(size_max) = 1;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "static";
	MY(velocityjitter) = '10.0 10.0 20.0';
}
// plasma smoke
SUB(damage_crylink) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x8844ff";
	MY(color_max) = "0x662244";
	MY(count) = 4;
	MY(gravity) = 0.001000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 6;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.4 0.4 0.6';
}
// floating sparks
SUB(damage_crylink) {
	MY(airfriction) = 0.200000;
	MY(alpha_min) = 192;
	MY(alpha_max) = 192;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x903090";
	MY(color_max) = "0xFFD0FF";
	MY(count) = 0.300000;
	MY(liquidfriction) = 0.800000;
	MY(sizeincrease) = -5;
	MY(size_min) = 0.500000;
	MY(size_max) = 0.500000;
	MY(type) = "spark";
	MY(velocityjitter) = '12.0 12.0 12.0';
}

// hlac damage effect
DEF(damage_hlac);
SUB(damage_hlac) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 128;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x008800";
	MY(color_max) = "0x44ff00";
	MY(count) = 3;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 10;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.4 0.4 0.6';
}

// vortex damage effect
DEF(damage_vortex);
SUB(damage_vortex) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 8;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xffffff";
	MY(color_max) = "0x88ffff";
	MY(count) = 1;
	MY(gravity) = -0.000100;
	MY(liquidfriction) = 0.600000;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(startangle_min) = 180;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = -14;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "static";
	MY(velocityjitter) = '8.0 8.0 16.0';
}
// plasma smoke
SUB(damage_vortex) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x6688ff";
	MY(color_max) = "0x226688";
	MY(count) = 2;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 8;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.5 0.5 0.8';
}
// bouncing sparks
SUB(damage_vortex) {
	MY(airfriction) = 2;
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 112;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 0.200000;
	MY(gravity) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(stretchfactor) = 0.700000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 300.0';
	MY(velocitymultiplier) = 3;
}

// vaporizer damage effect
DEF(damage_vaporizer);
SUB(damage_vaporizer) {
	MY(airfriction) = -0.500000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 8;
	MY(alpha_fade) = 64;
	MY(color_min) = "0xffffff";
	MY(color_max) = "0x88ffff";
	MY(count) = 2;
	MY(gravity) = -0.000100;
	MY(liquidfriction) = 0.600000;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(startangle_min) = 180;
	MY(startangle_max) = 360;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = -14;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "static";
	MY(velocityjitter) = '8.0 8.0 16.0';
}
// plasma smoke
SUB(damage_vaporizer) {
	MY(airfriction) = -0.350000;
	MY(alpha_min) = 64;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 64;
	MY(color_min) = "0x6688ff";
	MY(color_max) = "0x226688";
	MY(count) = 4;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_max) = 180;
	MY(spin_min) = -30;
	MY(spin_max) = 30;
	MY(sizeincrease) = 8;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.5 0.5 0.8';
}
// bouncing sparks
SUB(damage_vaporizer) {
	MY(airfriction) = 2;
	MY(alpha_min) = 255;
	MY(alpha_max) = 255;
	MY(alpha_fade) = 112;
	MY(bounce) = 1.600000;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0xD9FDFF";
	MY(count) = 0.200000;
	MY(gravity) = 1;
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(stretchfactor) = 0.700000;
	MY(tex_min) = 41;
	MY(tex_max) = 41;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 300.0';
	MY(velocitymultiplier) = 3;
}

// rifle damage effect, normal blood
DEF(damage_rifle);
SUB(damage_rifle) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xA8FFFF";
	MY(color_max) = "0xA8FFFFF";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(damage_rifle) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x420000";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// rifle damage effect, alien blood
DEF(damage_rifle_alien);
SUB(damage_rifle_alien) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xDC9BCD";
	MY(color_max) = "0xDC9BCD";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(damage_rifle_alien) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x204010";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// rifle damage effect, robot blood
DEF(damage_rifle_robot);
SUB(damage_rifle_robot) {
	MY(airfriction) = 1;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = -1;
	MY(color_min) = "0xC0D890";
	MY(color_max) = "0xC0D890";
	MY(count) = 0.300000;
	MY(liquidfriction) = 4;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(staincolor_min) = "0x808080";
	MY(staincolor_max) = "0x808080";
	MY(staintex_min) = 16;
	MY(staintex_max) = 24;
	MY(tex_min) = 24;
	MY(tex_max) = 32;
	MY(type) = "blood";
	MY(velocityjitter) = '32.0 32.0 32.0';
	MY(velocitymultiplier) = 5;
}
// blood mist
SUB(damage_rifle_robot) {
	MY(alpha_min) = 100;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 400;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x301860";
	MY(count) = 1;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
}

// seeker damage effect
DEF(damage_seeker);
SUB(damage_seeker) {
	MY(alpha_min) = 512;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x8f0c00";
	MY(color_max) = "0xff2200";
	MY(count) = 3;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -10;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(damage_seeker) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 2;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// hagar damage effect
DEF(damage_hagar);
SUB(damage_hagar) {
	MY(alpha_min) = 512;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x8f0c00";
	MY(color_max) = "0xff3a00";
	MY(count) = 3;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = -10;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(damage_hagar) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 2;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 2;
	MY(size_max) = 4;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// fireball damage effect
DEF(damage_fireball);
SUB(damage_fireball) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 16;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x8f0d00";
	MY(color_max) = "0xff5a00";
	MY(count) = 4;
	MY(gravity) = -0.500000;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = -10;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 50.0';
}
// smoke
SUB(damage_fireball) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 4;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// rocketlauncher damage effect
DEF(damage_devastator);
SUB(damage_devastator) {
	MY(alpha_min) = 512;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x8f0c00";
	MY(color_max) = "0xff2a00";
	MY(count) = 3;
	MY(gravity) = -0.700000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = -10;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '22.0 22.0 30.0';
}
// smoke
SUB(damage_devastator) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 32;
	MY(alpha_fade) = 128;
	MY(color_min) = "0x000000";
	MY(color_max) = "0x111111";
	MY(count) = 3;
	MY(gravity) = -0.300000;
	MY(notunderwater) = true;
	MY(originjitter) = '4.0 4.0 4.0';
	MY(sizeincrease) = 10;
	MY(size_min) = 4;
	MY(size_max) = 8;
	MY(tex_max) = 8;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '11.0 11.0 50.0';
}

// fireflies
DEF(fireflies);
SUB(fireflies) {
	MY(airfriction) = 5;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 70;
	MY(bounce) = -1;
	MY(color_min) = "0xff9600";
	MY(color_max) = "0xffefb8";
	MY(count) = 1;
	MY(originjitter) = '32.0 32.0 32.0';
	MY(originoffset) = '8.0 8.0 8.0';
	MY(sizeincrease) = -0.300000;
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(time_min) = 1;
	MY(time_max) = 2;
	MY(type) = "static";
	MY(velocityjitter) = '64.0 64.0 64.0';
	MY(velocityoffset) = '2.0 2.0 2.0';
}

DEF(healray_muzzleflash);
SUB(healray_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x283880";
	MY(color_max) = "0x283880";
	MY(countabsolute) = 1;
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = -10;
	MY(size_min) = 20;
	MY(size_max) = 20;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(healray_muzzleflash) {
	MY(airfriction) = 5;
	MY(alpha_min) = 50;
	MY(alpha_max) = 150;
	MY(alpha_fade) = 1924;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0x00f0ff";
	MY(count) = 22;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 3;
	MY(size_min) = 1;
	MY(size_max) = 15;
	MY(stretchfactor) = 3.900000;
	MY(tex_min) = 71;
	MY(tex_max) = 73;
	MY(type) = "spark";
	MY(velocityjitter) = '150.0 150.0 150.0';
	MY(velocitymultiplier) = 0.400000;
}
SUB(healray_muzzleflash) {
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 4024;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0x00f0ff";
	MY(count) = 4;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 1;
	MY(stretchfactor) = 0.200000;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "spark";
	MY(velocityjitter) = '650.0 650.0 650.0';
	MY(velocitymultiplier) = 1.100000;
}

DEF(healray_impact);
SUB(healray_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(color_min) = "0xd800ff";
	MY(color_max) = "0xd800ff";
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.0 4.4 0.0';
	MY(lightradiusfade) = 450;
	MY(lightradius) = 125;
	MY(originjitter) = '17.0 17.0 17.0';
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// shockwave
SUB(healray_impact) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x84c52f";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1400;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 44;
}
// cloud of bouncing sparks
SUB(healray_impact) {
	MY(airfriction) = 6;
	MY(alpha_min) = 156;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x84c52f";
	MY(count) = 30;
	MY(gravity) = 2;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "spark";
	MY(velocityjitter) = '1112.0 1112.0 1112.0';
}
// inner cloud of smoke
SUB(healray_impact) {
	MY(airfriction) = 3;
	MY(alpha_min) = 200;
	MY(alpha_max) = 456;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x84c52f";
	MY(count) = 15;
	MY(gravity) = -2;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -90;
	MY(spin_max) = 90;
	MY(size_min) = 2;
	MY(size_max) = 3;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "smoke";
	MY(velocityjitter) = '120.0 120.0 420.0';
}

DEF(bigplasma_muzzleflash);
SUB(bigplasma_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 812;
	MY(color_min) = "0x283880";
	MY(color_max) = "0x283880";
	MY(countabsolute) = 1;
	MY(lightcolor) = '1.5 3.0 6.0';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(sizeincrease) = -10;
	MY(size_min) = 50;
	MY(size_max) = 50;
	MY(tex_min) = 65;
	MY(tex_max) = 65;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(bigplasma_muzzleflash) {
	MY(alpha_min) = 56;
	MY(alpha_max) = 56;
	MY(alpha_fade) = 1112;
	MY(color_min) = "0x00f0ff";
	MY(color_max) = "0x00f0ff";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 300;
	MY(size_min) = 20;
	MY(size_max) = 20;
	MY(tex_min) = 74;
	MY(tex_max) = 74;
	MY(type) = "smoke";
}
SUB(bigplasma_muzzleflash) {
	MY(airfriction) = 5;
	MY(alpha_min) = 50;
	MY(alpha_max) = 150;
	MY(alpha_fade) = 1924;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0x00f0ff";
	MY(count) = 14;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 135;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(stretchfactor) = 1.900000;
	MY(tex_min) = 51;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '350.0 350.0 350.0';
	MY(velocitymultiplier) = 0.400000;
}
SUB(bigplasma_muzzleflash) {
	MY(alpha_min) = 110;
	MY(alpha_max) = 228;
	MY(alpha_fade) = 4024;
	MY(color_min) = "0xD9FDFF";
	MY(color_max) = "0x00f0ff";
	MY(count) = 4;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 20;
	MY(size_max) = 20;
	MY(stretchfactor) = 0.200000;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "spark";
	MY(velocityjitter) = '650.0 650.0 650.0';
	MY(velocitymultiplier) = 1.100000;
}

DEF(bigplasma_impact);
SUB(bigplasma_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.1 4.4 10.0';
	MY(lightradiusfade) = 450;
	MY(lightradius) = 125;
	MY(originjitter) = '17.0 17.0 17.0';
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 59;
	MY(tex_max) = 59;
	MY(type) = "decal";
}
// shockwave
SUB(bigplasma_impact) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 1400;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 44;
}
// cloud of bouncing sparks
SUB(bigplasma_impact) {
	MY(airfriction) = 6;
	MY(alpha_min) = 156;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x629dff";
	MY(color_max) = "0x0018ff";
	MY(count) = 30;
	MY(gravity) = 2;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "spark";
	MY(velocityjitter) = '1512.0 1512.0 1512.0';
}
// inner cloud of smoke
SUB(bigplasma_impact) {
	MY(airfriction) = 30;
	MY(alpha_min) = 200;
	MY(alpha_max) = 456;
	MY(alpha_fade) = 1512;
	MY(color_min) = "0x629dff";
	MY(color_max) = "0x0018ff";
	MY(count) = 15;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -9;
	MY(spin_max) = 9;
	MY(sizeincrease) = 555;
	MY(size_min) = 20;
	MY(size_max) = 24;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '320.0 320.0 320.0';
}
// smoke
SUB(bigplasma_impact) {
	MY(airfriction) = 0.040000;
	MY(alpha_min) = 128;
	MY(alpha_max) = 328;
	MY(alpha_fade) = 390;
	MY(blend) = "alpha";
	MY(color_min) = "0x222222";
	MY(color_max) = "0x000000";
	MY(count) = 16;
	MY(gravity) = 0.400000;
	MY(originjitter) = '80.0 80.0 10.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 2;
	MY(spin_max) = -2;
	MY(sizeincrease) = 30;
	MY(size_min) = 60;
	MY(size_max) = 30;
	MY(tex_max) = 7;
	MY(type) = "smoke";
	MY(velocityjitter) = '100.0 100.0 200.0';
	MY(velocityoffset) = '0.0 0.0 180.0';
}
// smoke in the middle
SUB(bigplasma_impact) {
	MY(airfriction) = 0.040000;
	MY(alpha_min) = 128;
	MY(alpha_max) = 328;
	MY(alpha_fade) = 310;
	MY(color_min) = "0x222222";
	MY(color_max) = "0x000000";
	MY(count) = 10;
	MY(gravity) = -0.200000;
	MY(originjitter) = '80.0 80.0 80.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 20;
	MY(spin_max) = -20;
	MY(sizeincrease) = -10;
	MY(size_min) = 60;
	MY(size_max) = 70;
	MY(tex_max) = 7;
	MY(type) = "alphastatic";
	MY(velocityjitter) = '10.0 10.0 10.0';
}

#include "effectinfo_ctf.inc"

// spawn_point -- team idle spawn point effect
#define spawn_point(name, color) \
	DEF(spawn_point_##name); \
	SUB(spawn_point_##name) { \
		MY(airfriction) = 0.200000; \
		MY(alpha_min) = 64; \
		MY(alpha_max) = 128; \
		MY(alpha_fade) = 128; \
		MY(color_min) = color; \
		MY(color_max) = color; \
		MY(count) = 37.500000; \
		MY(gravity) = -0.100000; \
		MY(liquidfriction) = 0.800000; \
		MY(originjitter) = '16.0 16.0 64.0'; \
		MY(size_min) = 1; \
		MY(size_max) = 2; \
		MY(type) = "static"; \
		MY(velocityjitter) = '32.0 32.0 0.0'; \
	}

spawn_point(red, 		"0xFF0F0F")
spawn_point(blue, 		"0x0F0FFF")
spawn_point(yellow, 	"0xFFFF0F")
spawn_point(pink, 		"0xFF0FFF")
spawn_point(neutral, 	"0xFFFFFF")
#undef spawn_point

// spawn_event -- team spawning effect
#define spawn_event(name, color) \
	DEF(spawn_event_##name); \
	SUB(spawn_event_##name) { \
		MY(airfriction) = 2; \
		MY(alpha_max) = 256; \
		MY(alpha_fade) = 256; \
		MY(bounce) = 1; \
		MY(color_min) = color; \
		MY(color_max) = color; \
		MY(count) = 100; \
		MY(originjitter) = '1.0 1.0 1.0'; \
		MY(size_min) = 1; \
		MY(size_max) = 1; \
		MY(stretchfactor) = 0.600000; \
		MY(tex_min) = 64; \
		MY(tex_max) = 64; \
		MY(type) = "spark"; \
		MY(velocityjitter) = '500.0 500.0 500.0'; \
		MY(velocitymultiplier) = 0.100000; \
	} \
	SUB(spawn_event_##name) { \
		MY(alpha_min) = 190; \
		MY(alpha_max) = 190; \
		MY(alpha_fade) = 180; \
		MY(color_min) = color; \
		MY(color_max) = color; \
		MY(countabsolute) = 1; \
		MY(sizeincrease) = -80; \
		MY(size_min) = 100; \
		MY(size_max) = 100; \
		MY(tex_min) = 65; \
		MY(tex_max) = 65; \
		MY(type) = "smoke"; \
	} \
	/**/

spawn_event(red, 		"0xFF0F0F")
spawn_event(blue, 		"0x0F0FFF")
spawn_event(yellow, 	"0xFFFF0F")
spawn_event(pink, 		"0xFF0FFF")
spawn_event(neutral, 	"0xFFFFFF")
#undef spawn_event

#include "effectinfo_nades.inc"

DEF(shockwave_attack);
// electricity
SUB(shockwave_attack) {
	MY(airfriction) = 1;
	MY(alpha_min) = 4096;
	MY(alpha_max) = 4096;
	MY(alpha_fade) = 20000;
	MY(color_min) = "0xb44215";
	MY(color_max) = "0xff0000";
	MY(count) = 1;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = 4000;
	MY(spin_max) = -4000;
	MY(sizeincrease) = 1.500000;
	MY(size_min) = 5;
	MY(size_max) = 7;
	MY(stretchfactor) = 2.300000;
	MY(tex_min) = 43;
	MY(tex_max) = 43;
	MY(type) = "spark";
	MY(velocityjitter) = '10.0 10.0 10.0';
	MY(velocitymultiplier) = 10;
}
// fire
SUB(shockwave_attack) {
	MY(airfriction) = 1;
	MY(alpha_min) = 4096;
	MY(alpha_max) = 4096;
	MY(alpha_fade) = 20000;
	MY(color_min) = "0xff4200";
	MY(color_max) = "0xff0000";
	MY(count) = 1;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(sizeincrease) = 1.500000;
	MY(size_min) = 7;
	MY(size_max) = 9;
	MY(stretchfactor) = 2;
	MY(tex_min) = 8;
	MY(tex_max) = 15;
	MY(type) = "spark";
	MY(velocityjitter) = '10.0 10.0 10.0';
	MY(velocitymultiplier) = 10;
}

DEF(arc_lightning);
// impact decal
SUB(arc_lightning) {
	MY(alpha_min) = 32;
	MY(alpha_max) = 32;
	MY(countabsolute) = 1;
	MY(lightcolor) = '3.1 4.4 10.0';
	MY(lightradiusfade) = 200;
	MY(lightradius) = 50;
	MY(originjitter) = '2.0 2.0 2.0';
	MY(size_min) = 16;
	MY(size_max) = 16;
	MY(tex_min) = 16;
	MY(tex_max) = 32;
	MY(type) = "decal";
}
// impact sparks
SUB(arc_lightning) {
	MY(airfriction) = 110;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xDDFDFF";
	MY(color_max) = "0xFDFDFF";
	MY(count) = 100;
	MY(originjitter) = '20.0 20.0 20.0';
	MY(startangle_max) = 360;
	MY(spin_min) = -36000;
	MY(spin_max) = 36000;
	MY(sizeincrease) = -5;
	MY(size_max) = 5;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(type) = "static";
	MY(velocityjitter) = '250.0 250.0 250.0';
	MY(velocitymultiplier) = 100;
}
// impact sparks (underwater)
SUB(arc_lightning) {
	MY(airfriction) = 5;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xDDFDFF";
	MY(color_max) = "0xFDFDFF";
	MY(count) = 100;
	MY(liquidfriction) = 5;
	MY(orientation) = "spark";
	MY(originjitter) = '20.0 20.0 20.0';
	MY(startangle_max) = 360;
	MY(spin_min) = -36000;
	MY(spin_max) = 36000;
	MY(sizeincrease) = -5;
	MY(size_max) = 5;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(type) = "static";
	MY(underwater) = true;
	MY(velocityjitter) = '250.0 250.0 250.0';
	MY(velocitymultiplier) = 20;
}
// impact smoke
SUB(arc_lightning) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(countabsolute) = 1;
	MY(sizeincrease) = 400;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 100;
}

DEF(arc_beam);
// sparks on beam
SUB(arc_beam) {
	MY(airfriction) = -10;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 16384;
	MY(color_min) = "0xfafad2";
	MY(color_max) = "0xffffff";
	MY(originjitter) = '3.0 3.0 3.0';
	MY(relativeoriginoffset) = '10.0 0.0 0.0';
	MY(startangle_max) = 360;
	MY(spin_min) = 360;
	MY(spin_max) = 1000;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(time_min) = 0.050000;
	MY(time_max) = 0.050000;
	MY(trailspacing) = 10;
	MY(type) = "spark";
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 200;
}
// sparks on beam (underwater)
SUB(arc_beam) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 16384;
	MY(color_min) = "0xfafad2";
	MY(color_max) = "0xffffff";
	MY(liquidfriction) = -10;
	MY(originjitter) = '30.0 30.0 30.0';
	MY(relativeoriginoffset) = '10.0 0.0 0.0';
	MY(startangle_max) = 360;
	MY(spin_min) = 360;
	MY(spin_max) = 1000;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(time_min) = 0.001000;
	MY(time_max) = 0.001000;
	MY(trailspacing) = 10;
	MY(type) = "spark";
	MY(underwater) = true;
	MY(velocityjitter) = '100.0 100.0 100.0';
	MY(velocitymultiplier) = 200;
}

DEF(arc_beam_heal);
// bubble this...
SUB(arc_beam_heal) {
	MY(airfriction) = -20;
	MY(alpha_min) = 2048;
	MY(alpha_max) = 2048;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x20FF20";
	MY(color_max) = "0x40FF40";
	MY(relativeoriginoffset) = '5.0 0.0 0.0';
	MY(relativevelocityoffset) = '100.0 0.0 0.0';
	MY(sizeincrease) = 20;
	MY(size_min) = 0.100000;
	MY(size_max) = 0.100000;
	MY(tex_min) = 74;
	MY(tex_max) = 74;
	MY(trailspacing) = 1500;
	MY(type) = "smoke";
	MY(velocityjitter) = '3.0 3.0 3.0';
	MY(velocitymultiplier) = 200;
}

DEF(arc_beam_healimpact);
// healing "aura"
SUB(arc_beam_healimpact) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 40;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x84c52f";
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.0 4.4 0.0';
	MY(lightradiusfade) = 150;
	MY(lightradius) = 20;
	MY(sizeincrease) = -1000;
	MY(size_min) = 32;
	MY(size_max) = 32;
	MY(tex_min) = 33;
	MY(tex_max) = 33;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 44;
}
// rising "smoke"
SUB(arc_beam_healimpact) {
	MY(airfriction) = 3;
	MY(alpha_min) = 200;
	MY(alpha_max) = 456;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x84c52f";
	MY(count) = 15;
	MY(gravity) = -2;
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -90;
	MY(spin_max) = 90;
	MY(size_min) = 0.500000;
	MY(size_max) = 1;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "smoke";
	MY(velocityjitter) = '120.0 120.0 420.0';
}

DEF(arc_smoke);
// arc heat smoke  (notunderwater)
SUB(arc_smoke) {
	MY(airfriction) = 1;
	MY(alpha_min) = 32;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 48;
	MY(color_min) = "0x4c453f";
	MY(color_max) = "0x2a241f";
	MY(count) = 2;
	MY(gravity) = -0.125000;
	MY(notunderwater) = true;
	MY(startangle_max) = 360;
	MY(spin_min) = -180;
	MY(spin_max) = 180;
	MY(sizeincrease) = 10;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '0.0 0.0 16.0';
}
// arc heat bubbles  (underwater)
SUB(arc_smoke) {
	MY(alpha_min) = 170;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 64;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(count) = 2;
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 0.250000;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 0.100000;
	MY(size_max) = 1;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

DEF(arc_overheat);
// arc overheat electric bolts
SUB(arc_overheat) {
	MY(airfriction) = 5;
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 292;
	MY(color_min) = "0xffffff";
	MY(color_max) = "0x9271fb";
	MY(count) = 24;
	MY(gravity) = -0.400000;
	MY(liquidfriction) = 10;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = -24;
	MY(size_min) = 6;
	MY(size_max) = 12;
	MY(tex_min) = 43;
	MY(tex_max) = 43;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}

DEF(arc_overheat_fire);
// arc overheat bouncing sparks
SUB(arc_overheat_fire) {
	MY(alpha_max) = 256;
	MY(alpha_fade) = 640;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x4444ff";
	MY(color_max) = "0xeeeeff";
	MY(count) = 1;
	MY(gravity) = 1;
	MY(liquidfriction) = 5;
	MY(originjitter) = '6.0 6.0 6.0';
	MY(size_min) = 0.400000;
	MY(size_max) = 1;
	MY(type) = "spark";
	MY(velocityjitter) = '92.0 92.0 92.0';
	MY(velocitymultiplier) = 80;
	MY(velocityoffset) = '0.0 0.0 80.0';
}

#include "effectinfo_buffs.inc"

#include "effectinfo_instagib.inc"

DEF(arc_muzzleflash);
SUB(arc_muzzleflash) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x8f4333";
	MY(count) = 2;
	MY(lightcolor) = '0.3 2.0 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 200;
	MY(originjitter) = '1.5 1.5 1.5';
	MY(size_min) = 5;
	MY(size_max) = 5;
	MY(tex_max) = 8;
	MY(type) = "smoke";
	MY(velocityjitter) = '6.0 6.0 6.0';
	MY(velocitymultiplier) = 0.010000;
}
SUB(arc_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x8f4333";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -400;
	MY(spin_max) = 400;
	MY(size_min) = 5;
	MY(size_max) = 10;
	MY(stretchfactor) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 200.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(arc_bolt_explode);
// decal
SUB(arc_bolt_explode) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(countabsolute) = 1;
	MY(lightcolor) = '8.0 4.0 1.0';
	MY(lightradiusfade) = 400;
	MY(lightradius) = 120;
	MY(originjitter) = '14.0 14.0 14.0';
	MY(size_min) = 28;
	MY(size_max) = 38;
	MY(tex_min) = 8;
	MY(tex_max) = 16;
	MY(type) = "decal";
}
// fire effect which make bright dot inside
SUB(arc_bolt_explode) {
	MY(airfriction) = 8;
	MY(alpha_min) = 80;
	MY(alpha_max) = 200;
	MY(alpha_fade) = 356;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x00ffff";
	MY(color_max) = "0x00ffff";
	MY(count) = 3.500000;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 5;
	MY(size_min) = 16;
	MY(size_max) = 26;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "smoke";
	MY(velocityjitter) = '156.0 156.0 156.0';
}
// fire effect which expands then slows
SUB(arc_bolt_explode) {
	MY(airfriction) = 12;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 456;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x8f4333";
	MY(count) = 12;
	MY(liquidfriction) = 8;
	MY(notunderwater) = true;
	MY(originjitter) = '8.0 8.0 8.0';
	MY(sizeincrease) = 15;
	MY(size_min) = 20;
	MY(size_max) = 26;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "static";
	MY(velocityjitter) = '286.0 286.0 286.0';
}
// underwater bubbles
SUB(arc_bolt_explode) {
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
// bouncing sparks
SUB(arc_bolt_explode) {
	MY(airfriction) = 1;
	MY(alpha_min) = 644;
	MY(alpha_max) = 956;
	MY(alpha_fade) = 684;
	MY(bounce) = 1.600000;
	MY(color_min) = "0x00ff00";
	MY(color_max) = "0x8f4333";
	MY(count) = 16;
	MY(gravity) = 1;
	MY(liquidfriction) = 0.800000;
	MY(notunderwater) = true;
	MY(originjitter) = '16.0 16.0 16.0';
	MY(size_min) = 1;
	MY(size_max) = 0.100000;
	MY(tex_min) = 40;
	MY(tex_max) = 40;
	MY(type) = "spark";
	MY(velocityjitter) = '224.0 224.0 224.0';
	MY(velocityoffset) = '0.0 0.0 80.0';
}

// weak bullet trail (somewhat like a tracer)
DEF(tr_bullet_weak);
SUB(tr_bullet_weak) {
	MY(alpha) = '75 100 3000';
	MY(color_min) = "0xf03000";
	MY(color_max) = "0xff6010";
	MY(countabsolute) = 1;
	MY(sizeincrease) = -3;
	MY(size_min) = 0.6;
	MY(size_max) = 0.8;
	my(tex_min) = 200;
	my(tex_max) = 200;
	MY(type) = "beam";
}
SUB(tr_bullet_weak) {
	MY(airfriction) = -4;
	MY(alpha) = '256 256 350';
	MY(color_min) = "0x202020";
	MY(color_max) = "0x404040";
	MY(notunderwater) = true;
	MY(sizeincrease) = 0.4;
	MY(size_min) = 1;
	MY(size_max) = 2;
	MY(tex_min) = 0;
	MY(tex_max) = 8;
	MY(trailspacing) = 16;
	MY(type) = "smoke";
	MY(velocityjitter) = '4 4 4';
}
SUB(tr_bullet_weak) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 128;
	MY(bounce) = 1.500000;
	MY(color_min) = "0x404040";
	MY(color_max) = "0x808080";
	MY(gravity) = -0.125000;
	MY(liquidfriction) = 4;
	MY(size_min) = 0.5;
	MY(size_max) = 0.6;
	MY(tex_min) = 62;
	MY(tex_max) = 62;
	MY(trailspacing) = 32;
	MY(type) = "bubble";
	MY(underwater) = true;
	MY(velocityjitter) = '16.0 16.0 16.0';
}

// Vaporizer hit effect
DEF(TE_TEI_G3_HIT);
SUB(TE_TEI_G3_HIT) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 256;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xFFFFFF";
	MY(countabsolute) = 1;
	MY(size_min) = 8;
	MY(size_max) = 8;
	MY(tex_min) = 200;
	MY(tex_max) = 200;
	MY(type) = "beam";
}
SUB(TE_TEI_G3_HIT) /* rings */ {
	MY(airfriction) = -4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xFFFFFF";
	MY(sizeincrease) = -2;
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(trailspacing) = 20;
	MY(type) = "smoke";
	MY(velocityjitter) = '2.0 2.0 2.0';
}
SUB(TE_TEI_G3_HIT) {
	MY(airfriction) = -4;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xFFFFFF";
	MY(color_max) = "0xFFFFFF";
	MY(sizeincrease) = -6;
	MY(size_min) = 10;
	MY(size_max) = 10;
	MY(trailspacing) = 40;
	MY(type) = "smoke";
}

// respawn ghosts effect
DEF(respawn_ghost);
SUB(respawn_ghost) {
	MY(count) = 75;
	MY(type) = "static";
	MY(color_min) = "0xA0A0A0";
	MY(color_max) = "0xFFFFFF";
	MY(size_min) = 2;
	MY(size_max) = 2;
	MY(alpha_min) = 32;
	MY(alpha_max) = 64;
	MY(alpha_fade) = 128;
	MY(airfriction) = 1;
	MY(liquidfriction) = 4;
	MY(originoffset) = '0 0 -8';
	MY(originjitter) = '28 28 16';
	MY(velocityjitter) = '0 0 256';
}

// originally based on goldendust
DEF(item_despawn);
SUB(item_despawn) {
	MY(type) = "snow";
//	MY(type) = "smoke";
	MY(blend) = "add";
	MY(alpha_min) = 192;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0xff9600";
	MY(color_max) = "0xffefb8";
	MY(count) = 32;
	MY(originjitter) = '8 8 8';
	MY(sizeincrease) = 1;
	MY(size_min) = 0.5;
	MY(size_max) = 1;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(velocityjitter) = '16 16 32';
	MY(lightradius) = 48;
	MY(lightradiusfade) 64;
	MY(lightcolor) '1 0.75 0.36';
	MY(lightshadow) 1;
}

DEF(hlac_muzzleflash);
// glow and light
SUB(hlac_muzzleflash) {
	MY(airfriction) = 10;
	MY(alpha_min) = 128;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 6280;
	MY(color_min) = "0x00cc00";
	MY(color_max) = "0x00ff00";
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.4 0.8 0.2';
	MY(lightradiusfade) = 2000;
	MY(lightradius) = 100;
	MY(sizeincrease) = -100;
	MY(size_min) = 2;
	MY(size_max) = 5;
	MY(stretchfactor) = 2;
	MY(tex_min) = 70;
	MY(tex_max) = 70;
	MY(type) = "smoke";
}
// electricity
SUB(hlac_muzzleflash) {
	MY(airfriction) = 12;
	MY(alpha_min) = 0;
	MY(alpha_max) = 128;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x92e045";
	MY(color_max) = "0x64f42a";
	MY(count) = 15;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(startangle_min) = -180;
	MY(startangle_max) = 180;
	MY(spin_min) = -400;
	MY(spin_max) = 400;
	MY(size_min) = 2;
	MY(size_max) = 5;
	MY(stretchfactor) = 2;
	MY(tex_min) = 48;
	MY(tex_max) = 55;
	MY(type) = "spark";
	MY(velocityjitter) = '200.0 200.0 200.0';
	MY(velocitymultiplier) = 0.500000;
}

DEF(hlac_impact);
// decal
SUB(hlac_impact) {
	MY(alpha_min) = 128;
	MY(alpha_max) = 128;
	MY(countabsolute) = 1;
	MY(lightcolor) = '0.4 0.8 0.2';
	MY(lightradiusfade) = 500;
	MY(lightradius) = 150;
	MY(originjitter) = '14.0 14.0 14.0';
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_min) = 47;
	MY(tex_max) = 47;
	MY(type) = "decal";
}
// flare effect
SUB(hlac_impact) {
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x1be508";
	MY(color_max) = "0xd5f0a1";
	MY(countabsolute) = 1;
	MY(size_min) = 24;
	MY(size_max) = 24;
	MY(tex_min) = 46;
	MY(tex_max) = 46;
	MY(type) = "static";
}
// sparks that rapidly expand and rapidly slow down to form an interesting spherical effect
SUB(hlac_impact) {
	MY(airfriction) = 8;
	MY(alpha_min) = 256;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 1024;
	MY(color_min) = "0x92e045";
	MY(color_max) = "0x54e51a";
	MY(count) = 128;
	MY(liquidfriction) = 2;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_min) = 45;
	MY(tex_max) = 45;
	MY(type) = "spark";
	MY(velocityjitter) = '256.0 256.0 256.0';
}
SUB(hlac_impact) {
	MY(alpha_min) = 64;
	MY(alpha_max) = 256;
	MY(alpha_fade) = 256;
	MY(color_min) = "0x92e045";
	MY(color_max) = "0xc7eda1";
	MY(count) = 4;
	MY(originjitter) = '1.0 1.0 1.0';
	MY(sizeincrease) = 6;
	MY(size_min) = 12;
	MY(size_max) = 12;
	MY(tex_min) = 4;
	MY(tex_max) = 6;
	MY(type) = "smoke";
	MY(velocityjitter) = '16.0 16.0 16.0';
	MY(velocitymultiplier) = 0.010000;
}

DEF(shotgun_woosh);
// puff
SUB(shotgun_woosh) {
	MY(airfriction) = 2;
	MY(alpha_min) = 32;
	MY(alpha_max) = 192;
	MY(alpha_fade) = 512;
	MY(bounce) = 0.100000;
	MY(color_min) = "0x111111";
	MY(color_max) = "0x979797";
	MY(count) = 24;
	MY(notunderwater) = true;
	MY(originjitter) = '10.0 10.0 10.0';
	MY(sizeincrease) = 14;
	MY(size_min) = 1;
	MY(size_max) = 12;
	MY(tex_min) = 0;
	MY(tex_max) = 8;
	MY(velocityjitter) = '128 128 64';
	MY(velocitymultiplier) = 1;
	MY(type) = "smoke";
}

DEF(EF_SHOCK);
// impact sparks
SUB(EF_SHOCK) {
	MY(airfriction) = 110;
	MY(alpha_min) = 256;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xDDFDFF";
	MY(color_max) = "0xFDFDFF";
	MY(count) = 50;
	MY(originjitter) = '6.0 6.0 10.0';
	MY(startangle_max) = 360;
	MY(spin_min) = 0;
	MY(spin_max) = 0;
	MY(sizeincrease) = -1;
	MY(size_min) = 4;
	MY(size_max) = 7;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(type) = "static";
	MY(velocityjitter) = '250.0 250.0 250.0';
	MY(velocitymultiplier) = 100;
}
// impact sparks (underwater)
SUB(EF_SHOCK) {
	MY(airfriction) = 5;
	MY(alpha_min) = 256;
	MY(alpha_max) = 300;
	MY(alpha_fade) = 512;
	MY(color_min) = "0xDDFDFF";
	MY(color_max) = "0xFDFDFF";
	MY(count) = 30;
	MY(liquidfriction) = 5;
	MY(orientation) = "spark";
	MY(originjitter) = '12.0 12.0 12.0';
	MY(startangle_max) = 360;
	MY(spin_min) = -36000;
	MY(spin_max) = 36000;
	MY(sizeincrease) = -5;
	MY(size_min) = 4;
	MY(size_max) = 7;
	MY(stretchfactor) = 1;
	MY(tex_min) = 71;
	MY(tex_max) = 74;
	MY(type) = "static";
	MY(underwater) = true;
	MY(velocityjitter) = '250.0 250.0 250.0';
	MY(velocitymultiplier) = 20;
}
// impact smoke
SUB(EF_SHOCK) {
	MY(alpha_min) = 40;
	MY(alpha_max) = 60;
	MY(alpha_fade) = 350;
	MY(color_min) = "0x80C0FF";
	MY(color_max) = "0x80C0FF";
	MY(count) = 10;
	MY(sizeincrease) = 400;
	MY(size_min) = 4;
	MY(size_max) = 4;
	MY(tex_min) = 38;
	MY(tex_max) = 38;
	MY(type) = "smoke";
	MY(velocitymultiplier) = 100;
}

// always add new effects to the bottom of the list. And keep this comment in the bottom line of this file!
