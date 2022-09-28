pyria
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/pyria.tga
		rgbgen lightingDiffuse
	}
}
pyriafullbright
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/pyriafullbright.tga
		rgbgen lightingDiffuse
	}
}

pyriahair
{
	surfaceparm trans
	cull none

	{
		map textures/pyriahair
		alphaFunc GE128
		blendFunc blend
		rgbGen identity
	}
}
