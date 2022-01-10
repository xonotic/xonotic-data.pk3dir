spiderbot
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/spiderbot.tga
		rgbgen lightingDiffuse
	}
}

wakazachi
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/wakazachi.tga
		rgbgen lightingDiffuse
	}
}

cockpit
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/cockpit.tga
		rgbgen lightingDiffuse
	}
}

vehicles/tracercore
{
	surfaceparm nonsolid
	surfaceparm nolightmap
	deformVertexes autosprite
	{
		map models/vehicles/tracercore.tga
		blendfunc add
		rgbGen lightingDiffuse
	}
}

vehicles/tracertrail
{
	surfaceparm nonsolid
	surfaceparm nolightmap
	cull none
	deformVertexes autosprite2
	{
		map models/vehicles/tracertrail.tga
		blendfunc GL_SRC_ALPHA GL_ONE
		rgbGen lightingDiffuse
	}
}
