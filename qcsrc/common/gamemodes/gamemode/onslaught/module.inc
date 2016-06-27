#ifndef ONS_CONSTANTS
	#define ONS_CONSTANTS
	REGISTER_NET_LINKED(ENT_CLIENT_GENERATOR)
	REGISTER_NET_LINKED(ENT_CLIENT_CONTROLPOINT_ICON)
#endif

#if defined(SVQC)
	#include "onslaught.qc"
	#ifndef IMPLEMENTATION
		#include "sv_controlpoint.qh"
		#include "sv_generator.qh"
	#else
		#include "sv_controlpoint.qc"
		#include "sv_generator.qc"
	#endif
#elif defined(CSQC)
	#ifndef IMPLEMENTATION
		#include "cl_controlpoint.qh"
		#include "cl_generator.qh"
	#else
		#include "cl_controlpoint.qc"
		#include "cl_generator.qc"
	#endif
#endif
