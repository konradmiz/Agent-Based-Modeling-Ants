globals
[
  col-1-nest-x col-1-nest-y
  col-1-seeds
  col-1-not-success

  min-turn-rate
  max-turn-rate

  ;max-pat-turn-rate
  ;min-pat-turn-rate

  ;patroller-met-threshold
  ;patroller-interact-max
]

breed [col-1s col-1]

col-1s-own
[
  turn-rate
  seeds-collected

  inside-nest-timer
  outside-nest-timer
  max-time-outside-nest
  foraging-timer

  carrying-food?
  looking-food?
  foraging?
  in-nest?
  patroller?

  last-trip-success?
  last-food-patch? ;;do I have a last food patch?
  last-food-patch ;;location of last food patch

  patroller-interact-timer
  patrollers-met
  pat-foraging?

]

patches-own
[
  nest1?
  chemical
]

to seed-draw ;; from NetLogo models library. Can be used to draw trails.
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;; note that they report the precise position of the mouse,
      ;; so you might get a decimal number like 12.3, but "patch"
      ;; automatically rounds to the nearest patch
      ask patch mouse-xcor mouse-ycor
        [ set pcolor green
          display ]
    ]
end

to trail-draw
  if mouse-down?     ;; reports true or false to indicate whether mouse button is down
    [
      ;; mouse-xcor and mouse-ycor report the position of the mouse --
      ;; note that they report the precise position of the mouse,
      ;; so you might get a decimal number like 12.3, but "patch"
      ;; automatically rounds to the nearest patch
      ask patch mouse-xcor mouse-ycor
        [ set pcolor cyan
          set chemical chemical + 1
          display ]
    ]
end


to setup
  clear-all
  reset-ticks

  ask patches
  [
    set pcolor brown - 2
    setup-colonies
  ]

  setup-ants
  setup-food

  set col-1-seeds 0
  set col-1-not-success 0

  set min-turn-rate 25
  set max-turn-rate 80

  ;set min-pat-turn-rate 60
  ;set max-pat-turn-rate 100

  ;set patroller-interact-max 120
  ;set patroller-met-threshold 20

end

to setup-colonies
  set col-1-nest-x -20
  set col-1-nest-y -20
  set nest1? (distancexy col-1-nest-x col-1-nest-y) < 10  ;;roughly adapated from UW Ants model ;;set some colonies up
  if nest1?
  [set pcolor violet] ;;and color those patches

end

to setup-ants
  create-col-1s (col-1s-number + num-patrollers)

  ask turtles
  [
    set shape "bug"
    set size 5
    set color red - 0.5

    set foraging? false
    set looking-food? false
    set carrying-food? false
    set patroller? false

    set inside-nest-timer 0
    set outside-nest-timer 0
    set foraging-timer 0

    set last-food-patch? false
    set max-time-outside-nest 1200

    set turn-rate min-turn-rate

    setxy col-1-nest-x col-1-nest-y
  ]

  ask turtles with [who < num-patrollers]
  [
    set color yellow
    set patroller? true

    set turn-rate min-pat-turn-rate
    set patroller-interact-timer patroller-interact-max
    set patrollers-met 0
    set pat-foraging? false

    set looking-food? false
    set foraging? false
  ]

end

to setup-food
  ask n-of food-number patches with [nest1? = false]
  [set pcolor green]
end

to patrollers-wiggle-angle-modify
  if any? other turtles with [patroller? = true] in-radius 3
  [
    set turn-rate turn-rate + 5
    set patroller-interact-timer patroller-interact-max
    set patrollers-met patrollers-met + 1
  ]

  if not any? other turtles with [patroller? = true] in-radius 3
  [
    set turn-rate turn-rate - 1
    set patroller-interact-timer patroller-interact-timer - 1
  ]

  if turn-rate > max-pat-turn-rate
  [set turn-rate max-pat-turn-rate]

  if turn-rate < min-pat-turn-rate
  [set turn-rate min-pat-turn-rate]

end


to go-patrollers
  if who >= ticks
  [stop]

  if nest1? = true and (patroller-interact-timer <= 0 or patrollers-met > patroller-met-threshold )
  [die]

  if nest1? = false
  [
    patrollers-wiggle-angle-modify

    if patroller-interact-timer < 0
    [
      set pat-foraging? false
      facexy col-1-nest-x col-1-nest-y
    ]

    if patrollers-met >= patroller-met-threshold and patroller-interact-timer > 0
    [
      set pat-foraging? true
      set turn-rate min-pat-turn-rate
      facexy col-1-nest-x col-1-nest-y
      patroller-leave-trail
    ]

  ]

  rt random turn-rate
  lt random turn-rate
  if not can-move? 1 [ rt 180 ]
  fd 0.8

end

to patroller-leave-trail
  if not any? neighbors4 with [nest1? = true]
  [
    ask neighbors4; patch-here
    [
      set chemical chemical + 1
      set pcolor cyan
    ]
  ]
end


to redraw-ants
  if carrying-food? = true
   [set color green]
  if carrying-food? = false
   [set color red - 0.5]
end

to check-if-forage
  if nest1? = true
  [
    if any? other turtles in-radius 4 with [patroller? = true and pat-foraging? = true]
    [set foraging-timer foraging-timer + 4]

    if any? other turtles in-radius 4 with [patroller? = true and pat-foraging? = false]
    [set foraging-timer foraging-timer - 1]

    if any? other turtles in-radius 4 with [patroller? = false and carrying-food? = true]
    [set foraging-timer foraging-timer + 2]

    if any? other turtles in-radius 4 with [patroller? = false and carrying-food? = false and outside-nest-timer > max-time-outside-nest]
    [set foraging-timer foraging-timer - 0.5]

    if foraging-timer >= 15 or (last-trip-success? = true and foraging-timer >= 10)
    [
     set foraging-timer 30 ; gives ants time to leave the nest before their foraging timer decays
     set foraging? true
     set looking-food? true
    ]

    if foraging-timer < 15
    [
      set foraging? false
      set looking-food? false
    ]

    set foraging-timer foraging-timer - 0.1
    if foraging-timer < 0
    [set foraging-timer 0]
  ]

  if nest1? = false
  [set foraging-timer 0]
end


to move
 if who >= ticks
  [stop]
if foraging? = true
[
  if carrying-food? = false and outside-nest-timer > max-time-outside-nest
  [set last-trip-success? false]

  if carrying-food? = true or outside-nest-timer > max-time-outside-nest ;if carrying food or too long outside, return home
  [
    facexy col-1-nest-x col-1-nest-y
    set turn-rate 0
  ]

  if nest1? = true
  [
    let ant-on-trail on-trail

    ifelse ant-on-trail = true
    [ant-follow-trail]
    [ant-find-trail]
  ]

  if nest1? = false and carrying-food? = false and outside-nest-timer < max-time-outside-nest
  [
    let ant-on-trail on-trail

    ifelse ant-on-trail = true
    [ant-follow-trail]
    [search-food]
  ]

  fd 0.4
]
end

to ant-find-trail ; only run when ant is in the nest
  let ant-on-trail on-trail

  ifelse ant-on-trail = false
  [
    rt random turn-rate
    lt random turn-rate

    if [nest1?] of patch-ahead 1  = false
    [rt random 180]
  ]
  [ant-follow-trail]

end

to ant-follow-trail
  ;if not any? patches in-cone 3 120 with [chemical > 0]
  ;[stop]
  if any? patches in-cone 3 120 with [chemical > 0]
  [face max-one-of (patches in-cone 3 120 with [chemical > 0]) [distancexy col-1-nest-x col-1-nest-y] ]
end

to-report on-trail
  ifelse any? patches in-cone 3 120 with [chemical > 0 ]
  [report true]
  [report false]

end

to ant-wiggle-angle-modify
  ifelse any? other turtles in-radius 3
  [set turn-rate turn-rate + 2 ]
  [set turn-rate turn-rate - 1 ]

  if turn-rate < min-turn-rate
  [set turn-rate min-turn-rate]

  if turn-rate > max-turn-rate
  [set turn-rate max-turn-rate]
end

to search-food
  if last-food-patch? = true
  [
    face last-food-patch
    if patch-here = last-food-patch
    [
      set last-food-patch false
      set last-food-patch? false
    ]
  ]

  if pcolor = green and carrying-food? = false ;if I'm on top of food
  [
    set seeds-collected seeds-collected + 1
    set last-food-patch? true
    set last-food-patch patch-here
    set last-trip-success? true

    set pcolor brown - 2

    set carrying-food? true
    set looking-food? false

    let x [pxcor] of last-food-patch
    let y [pycor] of last-food-patch
   ]

  if any? patches in-cone 3 120 with [pcolor = green] ;if I'm by a patch
  [
    face min-one-of (patches in-cone 3 120 with [pcolor = green]) [distance myself]
    set turn-rate 0
  ]

  if not any? patches in-cone 3 120 with [pcolor = green]
  [ant-wiggle-angle-modify]

  rt random turn-rate
  lt random turn-rate
  if not can-move? 1 [ rt 180 ]

end


to check-nest
  ifelse nest1? = true
  [
    if carrying-food? = true
    [
      set col-1-seeds col-1-seeds + 1
      set carrying-food? false
      rt 180
    ]

    if carrying-food? = false and outside-nest-timer > max-time-outside-nest
    [set col-1-not-success col-1-not-success + 1]

    set outside-nest-timer 0
    set in-nest? true
    set inside-nest-timer inside-nest-timer + 1
  ]
  [
    set in-nest? false
    set outside-nest-timer outside-nest-timer + 1
  ]

end

to go
  ask turtles with [patroller? = true]
  [go-patrollers]

  ask turtles with [patroller? = false]
  [
    check-if-forage
    move
    redraw-ants
    check-nest
  ]

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
820
421
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-150
150
-100
100
1
1
1
ticks
30.0

SLIDER
12
12
184
45
col-1s-number
col-1s-number
0
2000
420.0
1
1
NIL
HORIZONTAL

SLIDER
12
49
184
82
food-number
food-number
0
1000
471.0
1
1
NIL
HORIZONTAL

BUTTON
28
120
91
153
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
97
120
160
153
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
12
158
85
203
% Success
100 * col-1-seeds / (col-1-seeds + col-1-not-success)
2
1
11

MONITOR
2
208
114
253
Unsuccessful trips
col-1-not-success
17
1
11

MONITOR
114
208
212
253
Successful trips
col-1-seeds
17
1
11

SLIDER
11
82
183
115
num-patrollers
num-patrollers
0
200
60.0
1
1
NIL
HORIZONTAL

BUTTON
99
162
194
195
NIL
seed-draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
3
255
57
300
In-nest
count col-1s with [nest1? = true and patroller? = false]
17
1
11

MONITOR
61
256
124
301
Out-nest
count col-1s with [nest1? = false and patroller? = false]
17
1
11

MONITOR
127
256
209
301
Carrying food
count turtles with [carrying-food? = true]
17
1
11

MONITOR
947
285
1046
330
Outside Patrollers
count turtles with [patroller? = true and nest1? = false]
17
1
11

PLOT
831
10
1031
160
Patrollers
NIL
NIL
0.0
1000.0
0.0
60.0
false
false
"" ""
PENS
"default" 1.0 0 -4079321 true "" "plot count turtles with [patroller? = true and nest1? = false]"

SLIDER
832
162
1010
195
patroller-met-threshold
patroller-met-threshold
10
30
20.0
1
1
NIL
HORIZONTAL

MONITOR
835
286
937
331
Inside patrollers
count turtles with [patroller? = true and nest1? = true]
17
1
11

SLIDER
834
233
1006
266
patroller-interact-max
patroller-interact-max
0
180
120.0
1
1
NIL
HORIZONTAL

SLIDER
1014
199
1186
232
max-pat-turn-rate
max-pat-turn-rate
0
180
100.0
1
1
NIL
HORIZONTAL

SLIDER
1015
165
1187
198
min-pat-turn-rate
min-pat-turn-rate
0
180
60.0
1
1
NIL
HORIZONTAL

TEXTBOX
838
265
988
283
120-tick countdown timer
11
0.0
1

TEXTBOX
837
202
1023
230
Must meet other patrollers >= 20 times
11
0.0
1

BUTTON
40
337
125
370
NIL
trail-draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

A model of the foraging activity of red harvester ants, Pogonomyrmex barbatus.  

## HOW IT WORKS

This single-colony simulation has only one breed of ant, col-1s. Future extensions can add col-2s, col-3s,...,col-ns. These ants are divided into patrollers (yellow) and foragers (red). Patrollers are the first agents to leave the nest (purple) and interact outside of it. They need to interact with other patrollers within 120 ticks (or they head back to the nest), and they need to encounter other patrollers a certain number of times before they can return as 'successful', laying a trail back to the nest as they go. Patrollers alter their path shape based on the local density of ants encountered; a higher density leads to more convoluted paths while lower density leads to straighter paths. The determination of which foraging paths to use is stochastic in this model and does not depend on factors such as food availability or previous foraging directions.

Foragers wait inside the nest entrance. They have a simple foraging threshold timer which is updated each tick based on interactions with other ants nearby. When the threshold is met, ants find a trail leading from the colony and follow it. At the end of the trail, they start searching for food. Ants with food return straight to the nest. Foragers spend a max of 1200 ticks (the # of seconds in 20 minutes) searching for food before returning to the nest. Once in the nest, their foraging timer starts again, and local interactions again shape whether the ant will go out to forage. Ants that found food on the last foraging trip are more likely to go out than ants that were unsuccessful. Foragers turn 180 degrees when entering the nest, making them more likely to return to a similar spot to look for food. They also alter their path shape based on the local density of ants encountered; a higher density leads to more convoluted paths while lower density leads to straighter paths.    


## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

Patrollers emerge from the nest every time, but the foragers do not go out on each run. 

The colony responds to food availability: when food is coming in slowly, most of the colony is waiting inside the nest and not searching for food. This process is nonlinear in that sometimes a successful forager comes in and stimulates multiple ants to go out, while sometimes no ants will be stimulated to forage. 

## THINGS TO TRY

Altering the number of patrollers, their turn angles, their interaction timer, and the number of patrollers to meet before laying a trail and returning to the nest can alter the shape of the trails (and hopefully bring them closer to reality). 

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 101 187 98
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 135 105 105 60
Line -7500403 true 165 90 195 60

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count col-1s with [nest1? = false and patroller? = false]</metric>
    <enumeratedValueSet variable="col-1s-number">
      <value value="36"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-patrollers" first="20" step="1" last="75"/>
    <enumeratedValueSet variable="food-number">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles with [nest1? = false]</metric>
    <enumeratedValueSet variable="col-1s-number">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="patroller-met-threshold" first="12" step="1" last="25"/>
    <enumeratedValueSet variable="num-patrollers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
