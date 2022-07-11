electro_plasma
{
 {
	map textures/electro_plasma.tga
	tcMod scroll 0.03 0.001
 }
}

electro_plasma_hull
{
	{
	map textures/electro_plasma_hull.tga
	alphaFunc GE128
	rgbGen Vertex
	}
}

electro
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/electronew.tga
		rgbgen lightingDiffuse
	}
}
