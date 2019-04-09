DEF(spiderbot_minigun_trail);
SUB(spiderbot_minigun_trail) {
    MY(airfriction) = 1;
    MY(alpha_min) = 20;
    MY(alpha_max) = 50;
    MY(alpha_fade) = 100;
    MY(color_min) = "0xd0d0a0";
    MY(color_max) = "0xffffff";
    MY(gravity) = -0.030000;
    MY(notunderwater) = true;
    MY(sizeincrease) = 2;
    MY(size_min) = 1;
    MY(size_max) = 2;
    MY(tex_max) = 8;
    MY(trailspacing) = 10;
    MY(type) = "smoke";
    MY(velocityjitter) = '5 5 5';
}

DEF(spiderbot_minigun_muzzleflash);
SUB(spiderbot_minigun_muzzleflash) {
    MY(airfriction) = 10;
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 6280;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff8400";
    MY(count) = 3;
    MY(originjitter) = '2 2 2';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 4000;
    MY(spin_max) = -4000;
    MY(sizeincrease) = -100;
    MY(size_min) = 10;
    MY(size_max) = 15;
    MY(stretchfactor) = 1.300000;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '150 150 150';
    MY(velocitymultiplier) = 0.350000;
}
// fire
SUB(spiderbot_minigun_muzzleflash) {
    MY(airfriction) = 12;
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 6280;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff8400";
    MY(count) = 6;
    MY(originjitter) = '2 2 2';
    MY(sizeincrease) = -10;
    MY(size_min) = 5;
    MY(size_max) = 7;
    MY(stretchfactor) = 0.800000;
    MY(tex_min) = 8;
    MY(tex_max) = 15;
    MY(type) = "spark";
    MY(velocityjitter) = '200 200 200';
    MY(velocitymultiplier) = 0.200000;
}
SUB(spiderbot_minigun_muzzleflash) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 6680;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff8400";
    MY(countabsolute) = 2;
    MY(lightcolor) = '3 3 0';
    MY(lightradiusfade) = 8000;
    MY(lightradius) = 120;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 4000;
    MY(spin_max) = -4000;
    MY(sizeincrease) = -100;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(stretchfactor) = 0.100000;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
}

DEF(spiderbot_minigun_impact);
SUB(spiderbot_minigun_impact) {
    MY(alpha_min) = 50;
    MY(alpha_max) = 100;
    MY(alpha_fade) = 1680;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xf6ff00";
    MY(countabsolute) = 1;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 4000;
    MY(spin_max) = -4000;
    MY(sizeincrease) = -100;
    MY(size_min) = 52;
    MY(size_max) = 52;
    MY(stretchfactor) = 0.100000;
    MY(tex_min) = 65;
    MY(tex_max) = 65;
    MY(type) = "static";
}
// fire
SUB(spiderbot_minigun_impact) {
    MY(airfriction) = 6;
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 6280;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff8400";
    MY(count) = 7;
    MY(originjitter) = '2 2 2';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 4000;
    MY(spin_max) = -4000;
    MY(sizeincrease) = 100;
    MY(size_min) = 9;
    MY(size_max) = 15;
    MY(stretchfactor) = 3;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '250 250 150';
    MY(velocitymultiplier) = 0.200000;
}
// smoke
SUB(spiderbot_minigun_impact) {
    MY(airfriction) = 10;
    MY(alpha_min) = 50;
    MY(alpha_max) = 50;
    MY(alpha_fade) = 190;
    MY(color_min) = "0xd0d0a0";
    MY(color_max) = "0xffffff";
    MY(count) = 6;
    MY(gravity) = 1.300000;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(sizeincrease) = 80;
    MY(size_min) = 10;
    MY(size_max) = 20;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '100 100 250';
    MY(velocitymultiplier) = 0.490000;
}
// smoke 2
SUB(spiderbot_minigun_impact) {
    MY(airfriction) = 6;
    MY(alpha_min) = 25;
    MY(alpha_max) = 51;
    MY(alpha_fade) = 128;
    MY(color_min) = "0xd0d0a0";
    MY(color_max) = "0xffffff";
    MY(count) = 7;
    MY(originjitter) = '2 2 2';
    MY(sizeincrease) = 100;
    MY(size_min) = 15;
    MY(size_max) = 19;
    MY(stretchfactor) = 7.600000;
    MY(tex_max) = 8;
    MY(type) = "spark";
    MY(velocityjitter) = '250 250 150';
    MY(velocitymultiplier) = 0.200000;
}
// debris
SUB(spiderbot_minigun_impact) {
    MY(airfriction) = 0.400000;
    MY(alpha_min) = 644;
    MY(alpha_max) = 756;
    MY(alpha_fade) = 1484;
    MY(color_min) = "0x99977D";
    MY(color_max) = "0xFFFFFF";
    MY(count) = 3;
    MY(gravity) = 1.100000;
    MY(notunderwater) = true;
    MY(originjitter) = '16 16 16';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -1000;
    MY(spin_max) = 1000;
    MY(sizeincrease) = -10;
    MY(size_min) = 6;
    MY(size_max) = 8;
    MY(tex_min) = 66;
    MY(tex_max) = 68;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '124 124 224';
    MY(velocitymultiplier) = 0.150000;
}
// decal
SUB(spiderbot_minigun_impact) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(originjitter) = '16 16 16';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 20;
    MY(size_max) = 25;
    MY(tex_min) = 56;
    MY(tex_max) = 59;
    MY(type) = "decal";
}

DEF(spiderbot_rocket_explode);
SUB(spiderbot_rocket_explode) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(lightcolor) = '8 4 0';
    MY(lightradiusfade) = 1750;
    MY(lightradius) = 300;
    MY(originjitter) = '23 23 23';
    MY(size_min) = 72;
    MY(size_max) = 72;
    MY(tex_min) = 8;
    MY(tex_max) = 16;
    MY(type) = "decal";
}
// shockwave
SUB(spiderbot_rocket_explode) {
    MY(alpha_min) = 56;
    MY(alpha_max) = 56;
    MY(alpha_fade) = 230;
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
// glow
SUB(spiderbot_rocket_explode) {
    MY(alpha_min) = 156;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 830;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(countabsolute) = 1;
    MY(sizeincrease) = 240;
    MY(size_min) = 120;
    MY(size_max) = 120;
    MY(tex_min) = 64;
    MY(tex_max) = 64;
    MY(type) = "static";
}
// fire effect
SUB(spiderbot_rocket_explode) {
    MY(airfriction) = 8;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 812;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 32;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '100 100 100';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -50;
    MY(spin_max) = 50;
    MY(sizeincrease) = 495;
    MY(size_min) = 12;
    MY(size_max) = 21;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '512 512 512';
}
// fire effect 2
SUB(spiderbot_rocket_explode) {
    MY(airfriction) = -2;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 912;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 16;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -150;
    MY(spin_max) = 150;
    MY(sizeincrease) = 120;
    MY(size_min) = 3;
    MY(size_max) = 3;
    MY(stretchfactor) = 10;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '412 412 412';
}
// fire rays
SUB(spiderbot_rocket_explode) {
    MY(airfriction) = -3;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1600;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 10;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '40 40 40';
    MY(sizeincrease) = 120;
    MY(size_min) = 13;
    MY(size_max) = 54;
    MY(stretchfactor) = 10;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '712 712 712';
}
// smoke
SUB(spiderbot_rocket_explode) {
    MY(airfriction) = 3;
    MY(alpha_min) = 300;
    MY(alpha_max) = 650;
    MY(alpha_fade) = 756;
    MY(color_min) = "0x4F4B46";
    MY(color_max) = "0x000000";
    MY(count) = 10;
    MY(notunderwater) = true;
    MY(originjitter) = '100 100 100';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -20;
    MY(spin_max) = 20;
    MY(sizeincrease) = 280;
    MY(size_min) = 10;
    MY(size_max) = 15;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '200 200 200';
}
// smoke2
SUB(spiderbot_rocket_explode) {
    MY(airfriction) = 2;
    MY(alpha_min) = 300;
    MY(alpha_max) = 650;
    MY(alpha_fade) = 556;
    MY(color_min) = "0x4F4B46";
    MY(color_max) = "0x000000";
    MY(count) = 3;
    MY(gravity) = -0.500000;
    MY(notunderwater) = true;
    MY(originjitter) = '10 10 10';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -20;
    MY(spin_max) = 20;
    MY(sizeincrease) = 30;
    MY(size_min) = 100;
    MY(size_max) = 150;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '200 200 200';
}
// underwater bubbles
SUB(spiderbot_rocket_explode) {
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 64;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x404040";
    MY(color_max) = "0x808080";
    MY(count) = 32;
    MY(gravity) = -0.125000;
    MY(liquidfriction) = 0.250000;
    MY(originjitter) = '160 160 160';
    MY(size_min) = 1;
    MY(size_max) = 3;
    MY(tex_min) = 62;
    MY(tex_max) = 62;
    MY(type) = "bubble";
    MY(underwater) = true;
    MY(velocityjitter) = '144 144 144';
}
// underwatershockwave
SUB(spiderbot_rocket_explode) {
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

DEF(spiderbot_rocket_thrust);
SUB(spiderbot_rocket_thrust) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1600;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 3;
    MY(notunderwater) = true;
    MY(sizeincrease) = -40;
    MY(size_min) = 5;
    MY(size_max) = 10;
    MY(stretchfactor) = 0.900000;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '20 20 20';
    MY(velocitymultiplier) = -1.400000;
}
SUB(spiderbot_rocket_thrust) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 200;
    MY(alpha_fade) = 9000;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 4;
    MY(notunderwater) = true;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -500;
    MY(spin_max) = 500;
    MY(sizeincrease) = -3000;
    MY(size_min) = 25;
    MY(size_max) = 25;
    MY(stretchfactor) = 1;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = -1.400000;
}

DEF(spiderbot_rocket_launch);
// long lasting smoke
SUB(spiderbot_rocket_launch) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 100;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 60;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 8;
    MY(gravity) = -0.010000;
    MY(notunderwater) = true;
    MY(sizeincrease) = 20;
    MY(size_min) = 30;
    MY(size_max) = 30;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = -0.100000;
}
// fast smoke
SUB(spiderbot_rocket_launch) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 100;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 260;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 14;
    MY(gravity) = -0.300000;
    MY(notunderwater) = true;
    MY(sizeincrease) = 20;
    MY(size_min) = 30;
    MY(size_max) = 30;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '160 160 60';
}
// fire
SUB(spiderbot_rocket_launch) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1960;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(count) = 14;
    MY(notunderwater) = true;
    MY(sizeincrease) = 40;
    MY(size_min) = 30;
    MY(size_max) = 30;
    MY(stretchfactor) = 3;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = 0.500000;
}
// sparks
SUB(spiderbot_rocket_launch) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1000;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 10;
    MY(notunderwater) = true;
    MY(size_min) = 1;
    MY(size_max) = 4;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '160 160 160';
    MY(velocitymultiplier) = -0.500000;
}

DEF(wakizashi_gun_impact);
SUB(wakizashi_gun_impact) {
    MY(airfriction) = 4;
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 1180;
    MY(color_min) = "0xff0000";
    MY(color_max) = "0xc03535";
    MY(count) = 15;
    MY(gravity) = 3;
    MY(originjitter) = '40 40 10';
    MY(size_min) = 4;
    MY(size_max) = 7;
    MY(stretchfactor) = 0.900000;
    MY(tex_min) = 41;
    MY(tex_max) = 41;
    MY(type) = "spark";
    MY(velocityjitter) = '350 350 550';
    MY(velocityoffset) = '0 0 700';
}
SUB(wakizashi_gun_impact) {
    MY(airfriction) = 4;
    MY(alpha_min) = 50;
    MY(alpha_max) = 90;
    MY(alpha_fade) = 150;
    MY(color_min) = "0xd0d0a0";
    MY(color_max) = "0xc03535";
    MY(count) = 24;
    MY(originjitter) = '40 40 10';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(sizeincrease) = 80;
    MY(size_min) = 10;
    MY(size_max) = 20;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '250 250 450';
    MY(velocityoffset) = '0 0 600';
}
SUB(wakizashi_gun_impact) {
    MY(alpha_min) = 250;
    MY(alpha_max) = 300;
    MY(alpha_fade) = 680;
    MY(color_min) = "0xff0000";
    MY(color_max) = "0xc03535";
    MY(countabsolute) = 1;
    MY(sizeincrease) = -180;
    MY(size_min) = 82;
    MY(size_max) = 82;
    MY(tex_min) = 65;
    MY(tex_max) = 65;
    MY(type) = "smoke";
}
SUB(wakizashi_gun_impact) {
    MY(alpha_min) = 50;
    MY(alpha_max) = 100;
    MY(alpha_fade) = 620;
    MY(color_min) = "0xff0000";
    MY(color_max) = "0xc03535";
    MY(countabsolute) = 1;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 400;
    MY(spin_max) = -400;
    MY(sizeincrease) = 900;
    MY(size_min) = 40;
    MY(size_max) = 40;
    MY(tex_min) = 33;
    MY(tex_max) = 33;
    MY(type) = "smoke";
}
SUB(wakizashi_gun_impact) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(originjitter) = '16 16 16';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 14;
    MY(size_max) = 14;
    MY(tex_min) = 59;
    MY(tex_max) = 59;
    MY(type) = "decal";
}

DEF(wakizashi_gun_muzzleflash);
SUB(wakizashi_gun_muzzleflash) {
    MY(airfriction) = 12;
    MY(alpha_min) = 256;
    MY(alpha_max) = 512;
    MY(alpha_fade) = 6280;
    MY(color_min) = "0xff0000";
    MY(color_max) = "0xc03535";
    MY(count) = 16;
    MY(originjitter) = '2 2 2';
    MY(sizeincrease) = -10;
    MY(size_min) = 5;
    MY(size_max) = 7;
    MY(stretchfactor) = 0.700000;
    MY(tex_min) = 8;
    MY(tex_max) = 15;
    MY(type) = "spark";
    MY(velocityjitter) = '200 200 200';
    MY(velocitymultiplier) = 0.200000;
}

DEF(wakizashi_rocket_explode);
SUB(wakizashi_rocket_explode) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(lightcolor) = '8 4 0';
    MY(lightradiusfade) = 1750;
    MY(lightradius) = 300;
    MY(originjitter) = '23 23 23';
    MY(size_min) = 72;
    MY(size_max) = 72;
    MY(tex_min) = 8;
    MY(tex_max) = 16;
    MY(type) = "decal";
}
// shockwave
SUB(wakizashi_rocket_explode) {
    MY(alpha_min) = 56;
    MY(alpha_max) = 56;
    MY(alpha_fade) = 230;
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
// glow
SUB(wakizashi_rocket_explode) {
    MY(alpha_min) = 156;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 830;
    MY(color_min) = "0x8f0d00";
    MY(color_max) = "0xff5a00";
    MY(countabsolute) = 1;
    MY(sizeincrease) = 240;
    MY(size_min) = 120;
    MY(size_max) = 120;
    MY(tex_min) = 64;
    MY(tex_max) = 64;
    MY(type) = "static";
}
// fire effect
SUB(wakizashi_rocket_explode) {
    MY(airfriction) = 2;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 512;
    MY(color_min) = "0xFFAE00";
    MY(color_max) = "0xff5a00";
    MY(count) = 64;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '10 10 10';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -50;
    MY(spin_max) = 50;
    MY(sizeincrease) = 195;
    MY(size_min) = 12;
    MY(size_max) = 21;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '512 512 512';
}
// fire rays
SUB(wakizashi_rocket_explode) {
    MY(airfriction) = -3;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1600;
    MY(color_min) = "0xFFEA00";
    MY(color_max) = "0xff5a00";
    MY(count) = 10;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '40 40 40';
    MY(sizeincrease) = 120;
    MY(size_min) = 43;
    MY(size_max) = 54;
    MY(stretchfactor) = 10;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '512 512 512';
}
// smoke
SUB(wakizashi_rocket_explode) {
    MY(airfriction) = 3;
    MY(alpha_min) = 300;
    MY(alpha_max) = 450;
    MY(alpha_fade) = 556;
    MY(color_min) = "0x4F4B46";
    MY(color_max) = "0x000000";
    MY(count) = 32;
    MY(notunderwater) = true;
    MY(originjitter) = '100 100 100';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -20;
    MY(spin_max) = 20;
    MY(sizeincrease) = 230;
    MY(size_min) = 10;
    MY(size_max) = 15;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '200 200 200';
}
// bouncing sparks
SUB(wakizashi_rocket_explode) {
    MY(airfriction) = 1;
    MY(alpha_min) = 644;
    MY(alpha_max) = 956;
    MY(alpha_fade) = 884;
    MY(color_min) = "0xffa35b";
    MY(color_max) = "0xfff2be";
    MY(count) = 14;
    MY(gravity) = 1;
    MY(liquidfriction) = 0.800000;
    MY(notunderwater) = true;
    MY(originjitter) = '60 60 60';
    MY(size_min) = 1;
    MY(size_max) = 2;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '524 524 524';
    MY(velocityoffset) = '0 0 170';
}
// underwater bubbles
SUB(wakizashi_rocket_explode) {
    MY(alpha_min) = 128;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 64;
    MY(bounce) = 1.500000;
    MY(color_min) = "0x404040";
    MY(color_max) = "0x808080";
    MY(count) = 32;
    MY(gravity) = -0.125000;
    MY(liquidfriction) = 0.250000;
    MY(originjitter) = '160 160 160';
    MY(size_min) = 1;
    MY(size_max) = 3;
    MY(tex_min) = 62;
    MY(tex_max) = 62;
    MY(type) = "bubble";
    MY(underwater) = true;
    MY(velocityjitter) = '144 144 144';
}
// underwatershockwave
SUB(wakizashi_rocket_explode) {
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

DEF(wakizashi_rocket_thrust);
SUB(wakizashi_rocket_thrust) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1600;
    MY(color_min) = "0x00FFDD";
    MY(color_max) = "0x6200FF";
    MY(countabsolute) = 3;
    MY(notunderwater) = true;
    MY(sizeincrease) = -2;
    MY(size_min) = 14;
    MY(size_max) = 19;
    MY(stretchfactor) = 1;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = -1.100000;
}
SUB(wakizashi_rocket_thrust) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1900;
    MY(color_min) = "0xFFFF33";
    MY(color_max) = "0xFFEE00";
    MY(countabsolute) = 2;
    MY(notunderwater) = true;
    MY(sizeincrease) = -2;
    MY(size_min) = 5;
    MY(size_max) = 10;
    MY(stretchfactor) = 3;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = -0.300000;
}

DEF(wakizashi_rocket_launch);
// long lasting smoke
SUB(wakizashi_rocket_launch) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 100;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 60;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 8;
    MY(notunderwater) = true;
    MY(sizeincrease) = 20;
    MY(size_min) = 3;
    MY(size_max) = 30;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '160 160 60';
    MY(velocitymultiplier) = -0.100000;
}
// fast smoke
SUB(wakizashi_rocket_launch) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 100;
    MY(alpha_max) = 156;
    MY(alpha_fade) = 260;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 14;
    MY(notunderwater) = true;
    MY(sizeincrease) = 20;
    MY(size_min) = 30;
    MY(size_max) = 30;
    MY(tex_max) = 8;
    MY(type) = "smoke";
    MY(velocityjitter) = '160 160 60';
    MY(velocitymultiplier) = 0.400000;
}
//sparks
SUB(wakizashi_rocket_launch) {
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 1000;
    MY(color_min) = "0xFFFFFF";
    MY(color_max) = "0xD9C4B0";
    MY(count) = 10;
    MY(notunderwater) = true;
    MY(size_min) = 1;
    MY(size_max) = 4;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '60 60 60';
    MY(velocitymultiplier) = -1.500000;
}

DEF(wakizashi_booster_smoke);
SUB(wakizashi_booster_smoke) {
    MY(airfriction) = 2;
    MY(alpha_min) = 200;
    MY(alpha_max) = 750;
    MY(alpha_fade) = 200;
    MY(color_min) = "0xA69A80";
    MY(color_max) = "0xB3B39F";
    MY(count) = 3;
    MY(gravity) = -0.100000;
    MY(notunderwater) = true;
    MY(originjitter) = '60 60 60';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = -20;
    MY(spin_max) = 20;
    MY(sizeincrease) = 10;
    MY(size_min) = 60;
    MY(size_max) = 100;
    MY(tex_max) = 8;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '40 40 40';
}

DEF(raptor_cannon_impact);
// decal
SUB(raptor_cannon_impact) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(originjitter) = '16 16 16';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 24;
    MY(size_max) = 24;
    MY(tex_min) = 47;
    MY(tex_max) = 47;
    MY(type) = "decal";
}
// spark
SUB(raptor_cannon_impact) {
    MY(airfriction) = 0.200000;
    MY(alpha_min) = 644;
    MY(alpha_max) = 956;
    MY(alpha_fade) = 784;
    MY(color_min) = "0xD400FF";
    MY(color_max) = "0x571863";
    MY(count) = 6;
    MY(gravity) = 1;
    MY(notunderwater) = true;
    MY(originjitter) = '16 16 16';
    MY(size_min) = 1;
    MY(size_max) = 1;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '124 124 524';
    MY(velocityoffset) = '0 0 150';
}
// smoke
SUB(raptor_cannon_impact) {
    MY(airfriction) = 2;
    MY(alpha_min) = 428;
    MY(alpha_max) = 428;
    MY(alpha_fade) = 600;
    MY(color_min) = "0x646364";
    MY(color_max) = "0x151515";
    MY(count) = 4;
    MY(gravity) = 0.700000;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 50;
    MY(size_max) = 50;
    MY(tex_max) = 7;
    MY(type) = "alphastatic";
    MY(velocityjitter) = '200 200 300';
    MY(velocityoffset) = '0 0 340';
}
// fire
SUB(raptor_cannon_impact) {
    MY(airfriction) = 8;
    MY(alpha_min) = 200;
    MY(alpha_max) = 256;
    MY(alpha_fade) = 812;
    MY(bounce) = 1.500000;
    MY(color_min) = "0xD400FF";
    MY(color_max) = "0x571863";
    MY(count) = 10;
    MY(liquidfriction) = 8;
    MY(notunderwater) = true;
    MY(originjitter) = '8 8 8';
    MY(sizeincrease) = 25;
    MY(size_min) = 33;
    MY(size_max) = 44;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '312 312 312';
}

DEF(raptor_cannon_muzzleflash);
SUB(raptor_cannon_muzzleflash) {
    MY(airfriction) = 12;
    MY(alpha_min) = 1256;
    MY(alpha_max) = 1512;
    MY(alpha_fade) = 56280;
    MY(color_min) = "0xD400FF";
    MY(color_max) = "0x571863";
    MY(count) = 16;
    MY(originjitter) = '2 2 2';
    MY(sizeincrease) = -10;
    MY(size_min) = 10;
    MY(size_max) = 17;
    MY(stretchfactor) = 0.600000;
    MY(tex_min) = 8;
    MY(tex_max) = 15;
    MY(type) = "spark";
    MY(velocityjitter) = '200 200 200';
    MY(velocitymultiplier) = 0.200000;
}
SUB(raptor_cannon_muzzleflash) {
    MY(alpha_min) = 6056;
    MY(alpha_max) = 20112;
    MY(alpha_fade) = 406280;
    MY(color_min) = "0xD400FF";
    MY(color_max) = "0x571863";
    MY(countabsolute) = 1;
    MY(lightcolor) = '3 0 6';
    MY(lightradiusfade) = 6000;
    MY(lightradius) = 150;
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(spin_min) = 4000;
    MY(spin_max) = -4000;
    MY(sizeincrease) = -100;
    MY(size_min) = 32;
    MY(size_max) = 32;
    MY(stretchfactor) = 0.100000;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
}

DEF(raptor_bomb_impact);
// decal
SUB(raptor_bomb_impact) {
    MY(alpha_min) = 256;
    MY(alpha_max) = 256;
    MY(countabsolute) = 1;
    MY(originjitter) = '16 16 16';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 84;
    MY(size_max) = 84;
    MY(tex_min) = 8;
    MY(tex_max) = 16;
    MY(type) = "decal";
}
// spark vertical
SUB(raptor_bomb_impact) {
    MY(alpha_min) = 300;
    MY(alpha_max) = 300;
    MY(alpha_fade) = 600;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff3c00";
    MY(count) = 3;
    MY(originjitter) = '10 10 10';
    MY(sizeincrease) = 50;
    MY(size_min) = 20;
    MY(size_max) = 40;
    MY(stretchfactor) = 210;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "spark";
    MY(velocityjitter) = '40 40 120';
}
// fire
SUB(raptor_bomb_impact) {
    MY(airfriction) = 2;
    MY(alpha_min) = 300;
    MY(alpha_max) = 300;
    MY(alpha_fade) = 500;
    MY(color_min) = "0xff9c00";
    MY(color_max) = "0xff3c00";
    MY(count) = 4;
    MY(originjitter) = '10 10 10';
    MY(sizeincrease) = 230;
    MY(size_min) = 30;
    MY(size_max) = 120;
    MY(tex_min) = 48;
    MY(tex_max) = 55;
    MY(type) = "static";
    MY(velocityjitter) = '950 950 0';
}
// smoke
SUB(raptor_bomb_impact) {
    MY(alpha_min) = 428;
    MY(alpha_max) = 428;
    MY(alpha_fade) = 600;
    MY(blend) = "alpha";
    MY(color_min) = "0x646364";
    MY(color_max) = "0x151515";
    MY(count) = 4;
    MY(originjitter) = '30 30 10';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(size_min) = 120;
    MY(size_max) = 180;
    MY(stretchfactor) = 10;
    MY(tex_max) = 7;
    MY(type) = "spark";
    MY(velocityjitter) = '200 200 280';
    MY(velocityoffset) = '0 0 280';
}
// smoke 2
SUB(raptor_bomb_impact) {
    MY(airfriction) = 0.600000;
    MY(alpha_min) = 328;
    MY(alpha_max) = 328;
    MY(alpha_fade) = 350;
    MY(blend) = "alpha";
    MY(color_min) = "0x646364";
    MY(color_max) = "0x151515";
    MY(count) = 4;
    MY(gravity) = 2;
    MY(originjitter) = '30 30 10';
    MY(startangle_min) = -180;
    MY(startangle_max) = 180;
    MY(sizeincrease) = 60;
    MY(size_min) = 40;
    MY(size_max) = 100;
    MY(tex_max) = 7;
    MY(type) = "spark";
    MY(velocityjitter) = '200 200 300';
    MY(velocityoffset) = '0 0 580';
}
// sparks
SUB(raptor_bomb_impact) {
    MY(airfriction) = 0.300000;
    MY(alpha_min) = 644;
    MY(alpha_max) = 956;
    MY(alpha_fade) = 984;
    MY(color_min) = "0xffa35b";
    MY(color_max) = "0xfff2be";
    MY(count) = 5;
    MY(gravity) = 1;
    MY(notunderwater) = true;
    MY(originjitter) = '16 16 16';
    MY(size_min) = 3;
    MY(size_max) = 5;
    MY(stretchfactor) = 2;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '174 174 924';
    MY(velocityoffset) = '0 0 350';
}

DEF(raptor_bomb_spread);
SUB(raptor_bomb_spread) {
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
    MY(originjitter) = '110 110 110';
    MY(size_min) = 1;
    MY(size_max) = 2;
    MY(tex_min) = 40;
    MY(tex_max) = 40;
    MY(type) = "spark";
    MY(velocityjitter) = '324 324 324';
}
