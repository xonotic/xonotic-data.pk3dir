# Documentation For Player Soundfile Format

The soundfiles are structured in the following format:

```
whatsound path/to/sound total_count gentle_count
```

### `whatsound`

The first keyword is the in-game sound for which
the soundfiles are for.

A soundfile can be

- local
  - played for the players near your player
- teamradio
  - in team based modes these are only played for your team
  - in free for all based modes these are played for everyone
- last attacker
  - plays to the last player who has dealt damage to you

The currently implemented sounds are:

- affirmative
  - teamradio
  - respond yes
- attack
  - teamradio
  - communicate with other players to attack
- attacking
  - teamradio
  - communicate with other players that you are attacking
- attackinfive
  - teamradio
  - time a coordinated attack with other players
- coverme
  - teamradio
  - request cover from teammates
- defend
  - teamradio
  - order teammates to defend
- defending
  - teamradio
  - communicate that you are defending
- droppedflag
  - teamradio
  - 
- flagcarriertakingdamage
  - teamradio
  - 
- freelance
  - teamradio
  - 
- getflag
  - teamradio
  - tell teammates to get the flag
- incoming
  - teamradio
  - warn teammates that something is incoming
- meet
  - teamradio
  - tell teammates to meet you at the waypoint
- needhelp
  - teamradio
  - request help from teammates
- negative
  - teamradio
  - respond no
- onmyway
  - teamradio
  - communicate that you are on your way
- roaming
  - teamradio
  - 
- seenenemy
  - teamradio
  - communicate to your teammates that you saw an enemy
- seenflag
  - teamradio
  - communicate to teammates that you saw the flag
- taunt
  - local
  - taunt other players
- teamshoot
  - last attacker
  - played exclusively to your teammate when they shoot you
- death
  - 
  - deathsound
- drown
  - 
  - plurp plurp plurp
- fall
  - 
  - 
- falling
  - 
  - 
- gasp
  - 
  - 
- jump
  - local
  - jump sound if grunting is enabled
- pain25
  - local
  - painsound when you're hit and have less than 25 health
- pain50
  - local
  - painsound when you're hit and have less than 50 health
- pain75
  - local
  - painsound when you're hit and have less than 75 health
- pain100
  - local
  - painsound when it's not listed above

### `path/to/sound`

The virtual filesystem path to which sounds should be played.
For example: `sound/player/soldier/coms/taunt`

### `total_count`

How many soundfiles there are for use.
For example with the following sounds the count should be `3`.

```
sound/player/soldier/coms/
├── taunt1.ogg
├── taunt2.ogg
└── taunt3.ogg
```

### `gentle_count`

How many of the previously mentioned files do not contain words or phrases
which are under demonetization or censorship on current mainstream
platforms. All kinds of slurs should be avoided in these files to make
them suitable for all sorts of audiences and content creators.

Soundfiles which are not gentle should be listed last in the number order.

### Example:

```
taunt sound/player/soldier/coms/taunt 3 2
```

```
sound/player/soldier/coms/
├── taunt1.ogg
├── taunt2.ogg
└── taunt3.ogg   <- THIS IS NOT GENTLE
```

In this example `taunt` voice files are specified, their VFS path is
`sound/player/soldier/coms/taunt`, there are `3` soundfiles in total,
only `2` of the soundfiles are gentle as the last one contains
inappropriate language making it not suitable to be gentle.
