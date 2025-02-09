#!/bin/bash

baseline=20

sprite()
{
	name=$1
	text=$(echo $2) # Handle newlines
	color=$3

	echo $name

	# Text
	exec {FD}< <(convert \
	-auto-orient \
	-size 185x120 \
	-background transparent \
	-fill "#$color" \
	-font BigNoodleTitling \
	-interline-spacing -15 \
	-gravity south \
	label:"$text" \
	-trim \
	png:-)
	itext=$FD

	# Rectangles

	# Thick
	xa1=34
	xa2=$((xa1+185-1))
	ya1=174
	ya2=$((ya1+37-1))

	# Thin
	xb1=34
	xb2=$((xb1+185-1))
	yb1=224
	yb2=$((yb1+15-1))

	exec {FD}< <(convert \
	-auto-orient \
	-size 256x256 \
	-background transparent \
	-fill "#$color" \
	xc:none \
	-draw "rectangle $xa1,$ya1 $xa2,$ya2" \
	-draw "rectangle $xb1,$yb1 $xb2,$yb2" \
	png:-)
	irects=$FD

	# Join

	composite \
	-gravity south \
	-geometry -2+$((82+$baseline)) \
	-compress RLE \
	png:fd:$itext png:fd:$irects g_${name}_simple.tga
}

# grep '* color' ../../qcsrc/common/weapons/w_*.qc | awk '{ print $1 "  \t" $4 " " $5 " " $6 }'
# def h(r,g,b): return '#{:02x}{:02x}{:02x}'.format(int(round(r*255)),int(round(g*255)),int(round(b*255)))
sprite arc			"Arc"				ffffff # White
sprite laser		"Blaster"			ff8080 # Vivid Tangerine
sprite crylink		"Crylink"			ff80ff # Blush Pink
sprite rl			"Devastator"		ffff00 # Yellow
sprite electro		"Electro"			0080ff # Azure Radiance
sprite fireball		"Fireball"			ff8000 # Flush Orange
sprite hagar		"Hagar"				ffff80 # Dolly
sprite hlac			"HLAC"				00ff00 # Green
sprite hookgun		"Grappling\nHook"	008000 # Japanese Laurel
sprite uzi			"Machine\nGun"		ffff00 # Yellow
sprite minelayer	"Mine\nLayer"		bfff00 # Lime
sprite gl			"Mortar"			ff0000 # Red
sprite porto		"Port-O-Launch"		808080 # Gray
sprite campingrifle	"Rifle"				80ff00 # Chartreuse
sprite seeker		"T.A.G.\nSeeker"	80ff00 # Chartreuse
sprite shotgun		"Shotgun"			804000 # Cinnamon
sprite tuba			"Tuba" 				00ff00 # Green
sprite minstanex	"Vaporizer"			80ffff # Anakiwa
sprite nex			"Vortex"			80ffff # Anakiwa
