#include "outline.qh"

// checkpoint outline entity
// TODO: the outline drawing code can be merged into the trigger_race_checkpoint entity once it gets handled client-side

// the descriptions in this file depend on the way coordinates are mapped
//   +X = back
//   -X = front
//   +Y = left
//   -Y = right
//   +Z = top
//   -Z = bottom

// closest single precision IEEE 754 floating point value to 1 which is less than 1
// FIXME: the polygon draw functions misbehave when an alpha value which is greater or equal to 1 is used
//        subsequent polygons should not be affected by previous drawing operations
#define ONE_MINUS_EPSILON 0.999999940395355224609375

#ifdef GAMEQC
REGISTER_NET_LINKED(ENT_CLIENT_RACE_OUTLINE)
#endif

#ifdef SVQC
bool outline_send(entity this, entity to, float sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_RACE_OUTLINE);
	WriteVector(MSG_ENTITY, this.origin);
	WriteVector(MSG_ENTITY, this.mins);
	WriteVector(MSG_ENTITY, this.maxs);

	return true;
}

// spawn an outline, origin must be the center of the target
void Outline_Spawn(entity tgt, vector org)
{
	entity this = new(outline);

	setorigin(this, org);
	vector size_halved = (tgt.absmax - tgt.absmin) / 2;
	setsize(this, -size_halved, size_halved);

	Net_LinkEntity(this, false, 0, outline_send);
}
#elif defined(CSQC)
// the caller must ensure that start_ofs contains the lower coordinates and end_ofs the higher coordinates
void outline_drawline(entity this, vector start_ofs, vector end_ofs, int cap_mask)
{
	// the origin is in the center, expand halfway in both directions
	float width_halved = bound(0, autocvar_cl_race_checkpoint_outline_width, 10) / 2;

	// determine the direction, the offsets must describe a line orthogonal to the world axes
	vector axis_1; // first axis to extend
	vector axis_2; // second axis to extend
	vector start_ofs_caps = start_ofs;
	vector end_ofs_caps = end_ofs;
	if(start_ofs.x != end_ofs.x)
	{
		axis_1 = width_halved * eY;
		axis_2 = width_halved * eZ;

		// this assumes that start_ofs contains the lower coordinates
		start_ofs.x += width_halved;
		end_ofs.x -= width_halved;
		start_ofs_caps.x -= width_halved;
		end_ofs_caps.x += width_halved;
	}
	else if(start_ofs.y != end_ofs.y)
	{
		axis_1 = width_halved * eX;
		axis_2 = width_halved * eZ;

		// this assumes that start_ofs contains the lower coordinates
		start_ofs.y += width_halved;
		end_ofs.y -= width_halved;
		start_ofs_caps.y -= width_halved;
		end_ofs_caps.y += width_halved;
	}
	else if(start_ofs.z != end_ofs.z)
	{
		axis_1 = width_halved * eX;
		axis_2 = width_halved * eY;

		// this assumes that start_ofs contains the lower coordinates
		start_ofs.z += width_halved;
		end_ofs.z -= width_halved;
		start_ofs_caps.z -= width_halved;
		end_ofs_caps.z += width_halved;
	}
	else
	{
		return; // start and end offsets are equal
	}

	// draw the 4 sides of a box shape, this gives the line a shape in the 3D space
	vector color = autocvar_cl_race_checkpoint_outline_color;
	float alpha = bound(0, autocvar_cl_race_checkpoint_outline, ONE_MINUS_EPSILON);

	// first face: draw along axis_1 facing axis_2, offset by the negative width on axis_2
	// x axis: bottom face, y axis: bottom face, z axis: right face
	R_BeginPolygon("", DRAWFLAG_NORMAL, false);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_0 ? start_ofs_caps : start_ofs) - axis_1 - axis_2, '0 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_0 ? start_ofs_caps : start_ofs) + axis_1 - axis_2, '1 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_0 ? end_ofs_caps : end_ofs) + axis_1 - axis_2, '1 1 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_0 ? end_ofs_caps : end_ofs) - axis_1 - axis_2, '0 1 0', color, alpha);
	R_EndPolygon();

	// second face: draw along axis_1 facing axis_2, offset by the positive width on axis_2
	// x axis: top face, y axis: top face, z axis: left face
	R_BeginPolygon("", DRAWFLAG_NORMAL, false);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_1 ? start_ofs_caps : start_ofs) - axis_1 + axis_2, '0 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_1 ? start_ofs_caps : start_ofs) + axis_1 + axis_2, '1 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_1 ? end_ofs_caps : end_ofs) + axis_1 + axis_2, '1 1 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_1 ? end_ofs_caps : end_ofs) - axis_1 + axis_2, '0 1 0', color, alpha);
	R_EndPolygon();

	// third face: draw along axis_2 facing axis_1, offset by the negative width on axis_1
	// x axis: right face, y axis: front face, z axis: front face
	R_BeginPolygon("", DRAWFLAG_NORMAL, false);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_2 ? start_ofs_caps : start_ofs) - axis_2 - axis_1, '0 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_2 ? start_ofs_caps : start_ofs) + axis_2 - axis_1, '1 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_2 ? end_ofs_caps : end_ofs) + axis_2 - axis_1, '1 1 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_2 ? end_ofs_caps : end_ofs) - axis_2 - axis_1, '0 1 0', color, alpha);
	R_EndPolygon();

	// fourth face: draw along axis_2 facing axis_1, offset by the positive width on axis_1
	// x axis: left face, y axis: back face, z axis: back face
	R_BeginPolygon("", DRAWFLAG_NORMAL, false);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_3 ? start_ofs_caps : start_ofs) - axis_2 + axis_1, '0 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_3 ? start_ofs_caps : start_ofs) + axis_2 + axis_1, '1 0 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_3 ? end_ofs_caps : end_ofs) + axis_2 + axis_1, '1 1 0', color, alpha);
	R_PolygonVertex(this.origin + (cap_mask & CORNER_MASK_3 ? end_ofs_caps : end_ofs) - axis_2 + axis_1, '0 1 0', color, alpha);
	R_EndPolygon();
}

// the caller must ensure to maintain the following relationship between corners depending on the orientation
// the list shows transitions from 1st to 2nd corner, 2nd to 3rd corner, 3rd to 4th corner and 4th back to 1st corner
// the entries denote whether the axis coordinates increase or decrease between the corners
// this is used by the trimming code which prevents overlap to the outline
//   FACE_X_AXIS:
//     +Y -> +Z -> -Y -> -Z
//   FACE_Y_AXIS:
//     +X -> +Z -> -X -> -Z
//   FACE_Z_AXIS:
//     +X -> +Y -> -X -> -Y
void outline_drawfill(entity this, vector corner_1, vector corner_2, vector corner_3, vector corner_4, int orientation)
{
	// depends on same parameters as outline_drawline()
	float width_halved = bound(0, autocvar_cl_race_checkpoint_outline_width, 10) / 2;
	vector color = autocvar_cl_race_checkpoint_outline_color;
	float alpha = bound(0, autocvar_cl_race_checkpoint_outline_fill, ONE_MINUS_EPSILON) * bound(0, autocvar_cl_race_checkpoint_outline, 1);

	// reduze size, don't overlap with the outline
	// assumes that the corners relate to each other as described above
	switch(orientation)
	{
		case FACE_X_AXIS:
			corner_1.y += width_halved;
			corner_2.y -= width_halved;
			corner_3.y -= width_halved;
			corner_4.y += width_halved;
			corner_1.z += width_halved;
			corner_2.z += width_halved;
			corner_3.z -= width_halved;
			corner_4.z -= width_halved;
			break;
		case FACE_Y_AXIS:
			corner_1.x += width_halved;
			corner_2.x -= width_halved;
			corner_3.x -= width_halved;
			corner_4.x += width_halved;
			corner_1.z += width_halved;
			corner_2.z += width_halved;
			corner_3.z -= width_halved;
			corner_4.z -= width_halved;
			break;
		case FACE_Z_AXIS:
			corner_1.x += width_halved;
			corner_2.x -= width_halved;
			corner_3.x -= width_halved;
			corner_4.x += width_halved;
			corner_1.y += width_halved;
			corner_2.y += width_halved;
			corner_3.y -= width_halved;
			corner_4.y -= width_halved;
			break;
	}

	// draw rectangle
	R_BeginPolygon("", DRAWFLAG_NORMAL, false);
	R_PolygonVertex(this.origin + corner_1, '0 0 0', color, alpha);
	R_PolygonVertex(this.origin + corner_2, '1 0 0', color, alpha);
	R_PolygonVertex(this.origin + corner_3, '1 1 0', color, alpha);
	R_PolygonVertex(this.origin + corner_4, '0 1 0', color, alpha);
	R_EndPolygon();
}

void outline_draw(entity this)
{
	if(autocvar_cl_race_checkpoint_outline == 0) return; // early return

	// lower right front corner
	vector bottom_1 = eX * this.mins.x + eY * this.mins.y + eZ * this.mins.z;
	// lower right rear corner
	vector bottom_2 = eX * this.maxs.x + eY * this.mins.y + eZ * this.mins.z;
	// lower left rear corner
	vector bottom_3 = eX * this.maxs.x + eY * this.maxs.y + eZ * this.mins.z;
	// lower left front corner
	vector bottom_4 = eX * this.mins.x + eY * this.maxs.y + eZ * this.mins.z;

	// upper right front corner
	vector top_1 = eX * this.mins.x + eY * this.mins.y + eZ * this.maxs.z;
	// upper right back corner
	vector top_2 = eX * this.maxs.x + eY * this.mins.y + eZ * this.maxs.z;
	// upper left back corner
	vector top_3 = eX * this.maxs.x + eY * this.maxs.y + eZ * this.maxs.z;
	// upper left front corner
	vector top_4 = eX * this.mins.x + eY * this.maxs.y + eZ * this.maxs.z;

	// lower right line (aligned to X axis)
	outline_drawline(this, bottom_1, bottom_2, CORNER_MASK_X_BOTTOM);
	// lower back line (aligned to Y axis)
	outline_drawline(this, bottom_2, bottom_3, CORNER_MASK_NONE);
	// lower left line (aligned to X axis)
	outline_drawline(this, bottom_4, bottom_3, CORNER_MASK_X_BOTTOM);
	// lower front line (aligned to Y axis)
	outline_drawline(this, bottom_1, bottom_4, CORNER_MASK_NONE);

	// upper right horizontal line (aligned to X axis)
	outline_drawline(this, top_1, top_2, CORNER_MASK_X_TOP);
	// upper back horizontal line (aligned to Y axis)
	outline_drawline(this, top_2, top_3, CORNER_MASK_NONE);
	// upper left horizontal line (aligned to X axis)
	outline_drawline(this, top_4, top_3, CORNER_MASK_X_TOP);
	// upper front horizontal line (aligned to Y axis)
	outline_drawline(this, top_1, top_4, CORNER_MASK_NONE);

	// front right vertical line (aligned to Z axis)
	outline_drawline(this, bottom_1, top_1, CORNER_MASK_Z_FRONT | CORNER_MASK_Z_RIGHT);
	// back right vertical line (aligned to Z axis)
	outline_drawline(this, bottom_2, top_2, CORNER_MASK_Z_BACK  | CORNER_MASK_Z_RIGHT);
	// back left vertical line (aligned to Z axis)
	outline_drawline(this, bottom_3, top_3, CORNER_MASK_Z_BACK  | CORNER_MASK_Z_LEFT);
	// front left vertical line (aligned to Z axis)
	outline_drawline(this, bottom_4, top_4, CORNER_MASK_Z_FRONT | CORNER_MASK_Z_LEFT);

	// optionally fill the box
	if(autocvar_cl_race_checkpoint_outline_fill == 0) return; // early return

	// back face (facing X axis)
	outline_drawfill(this, bottom_2, bottom_3, top_3,    top_2,    FACE_X_AXIS);
	// front face (facing X axis)
	outline_drawfill(this, bottom_1, bottom_4, top_4,    top_1,    FACE_X_AXIS);
	// right face (facing Y axis)
	outline_drawfill(this, bottom_1, bottom_2, top_2,    top_1,    FACE_Y_AXIS);
	// left face (facing Y axis)
	outline_drawfill(this, bottom_4, bottom_3, top_3,    top_4,    FACE_Y_AXIS);
	// bottom face (facing Z axis)
	outline_drawfill(this, bottom_1, bottom_2, bottom_3, bottom_4, FACE_Z_AXIS);
	// top face (facing Z axis)
	outline_drawfill(this, top_1,    top_2,    top_3,    top_4,    FACE_Z_AXIS);
}

NET_HANDLE(ENT_CLIENT_RACE_OUTLINE, bool isnew)
{
	this.origin = ReadVector();
	this.mins = ReadVector();
	this.maxs = ReadVector();

	setorigin(this, this.origin);
	setsize(this, this.mins, this.maxs);

	this.draw = outline_draw;
	if(isnew) IL_PUSH(g_drawables, this);

	return true;
}
#endif
