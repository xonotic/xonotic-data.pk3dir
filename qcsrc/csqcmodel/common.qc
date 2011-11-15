.vector glowmod;
.vector view_ofs;
.float frame;
.float frame1time;
.float frame2;
.float frame2time;
.float lerpfrac;

#define PROPERTY_FRAME 32768
#define PROPERTY_FRAME2 16384
#define PROPERTY_LERPFRAC 8192
#define PROPERTY_TELEPORTED 4096 // the "teleport bit" cancelling interpolation
#define PROPERTY_MODELINDEX 2048
#define PROPERTY_ORIGIN 1024
#define PROPERTY_YAW 512
#define PROPERTY_PITCHROLL 256

#define ALLPROPERTIES_COMMON \
	PROPERTY(PROPERTY_FRAME, ReadByte, WriteByte, frame) \
	PROPERTY(PROPERTY_MODELINDEX, ReadShort, WriteShort, modelindex) \
	PROPERTY(PROPERTY_ORIGIN, ReadCoord, WriteCoord, origin_x) \
	PROPERTY(PROPERTY_ORIGIN, ReadCoord, WriteCoord, origin_y) \
	PROPERTY(PROPERTY_ORIGIN, ReadCoord, WriteCoord, origin_z) \
	PROPERTY(PROPERTY_PITCHROLL, ReadAngle, WriteAngle, angles_x) \
	PROPERTY(PROPERTY_YAW, ReadAngle, WriteAngle, angles_y) \
	PROPERTY(PROPERTY_PITCHROLL, ReadAngle, WriteAngle, angles_z) \
	CSQCMODELS_EXTRAPROPERTIES

#ifdef CSQCMODELS_HAVE_TWO_FRAMES
.float frame3;
.float frame3time;
.float lerpfrac3;
.float frame4;
.float frame4time;
.float lerpfrac4;
#define ALLPROPERTIES ALLPROPERTIES_COMMON \
	PROPERTY(PROPERTY_FRAME2, ReadByte, WriteByte, frame2) \
	PROPERTY_SCALED(PROPERTY_LERPFRAC, ReadByte, WriteByte, lerpfrac, 255, 0, 255)
#else
#define ALLPROPERTIES ALLPROPERTIES_COMMON
#endif

