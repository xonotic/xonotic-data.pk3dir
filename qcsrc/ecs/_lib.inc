#define COMPONENT(com) \
	void com_##com##_interpolate(entity it, float a); \
	.bool com_##com

#define FOREACH_COMPONENT(com, body) FOREACH_ENTITY_FLOAT(com_##com, true, body)


#define EVENT(T, args) .bool evt_##T##_listener; .void args evt_##T

#define emit(T, ...) \
	MACRO_BEGIN \
	FOREACH_ENTITY_FLOAT_ORDERED(evt_##T##_listener, true, it.evt_##T(__VA_ARGS__)); \
	MACRO_END

#define subscribe(listener, T) \
	MACRO_BEGIN \
	listener.evt_##T##_listener = true; \
	MACRO_END


#define SYSTEM(sys, fps) \
	void sys_##sys##_update(entity this, float dt); \
	float autocvar_xon_sys_##sys##_dt = 1 / (fps)

#define SYSTEM_UPDATE(sys, minfps) \
	MACRO_BEGIN \
	static float t = 0; \
	float dt = autocvar_xon_sys_##sys##_dt; \
	static float accumulator = 0; \
	accumulator += min(frametime, 1 / (minfps)); \
	while (accumulator >= dt) \
	{ \
		time = t; \
		FOREACH_COMPONENT(sys, sys_##sys##_update(it, dt)); \
		t += dt; \
		accumulator -= dt; \
	} \
	float a = accumulator / dt; \
	FOREACH_COMPONENT(sys, com_##sys##_interpolate(it, a)); \
	MACRO_END


#include "_mod.inc"
#include "components/_mod.inc"
#include "events/_mod.inc"
#include "systems/_mod.inc"
