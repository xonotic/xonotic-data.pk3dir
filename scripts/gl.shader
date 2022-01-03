grenadelauncher
{
	dpreflectcube cubemaps/default/sky
	{
		map textures/grenadelauncher.tga
		rgbgen lightingDiffuse
	}
}
grenadelauncher_sight
{
	{
	animMap 1 textures/glsight01.tga textures/glsight02.tga textures/glsight03.tga
	blendFunc GL_ONE GL_ONE
	rgbGen wave sawtooth 0 1 0 10
	}
}
