# CSlide
fully predicted sliding for gmod<br>

all rights reserved for the sounds, which were taken from apex legends<br>

# cvars
* ``sv_cslide`` - (``0/1``)
  * Sets whether sliding is enabled on server or not.
* ``sv_cslide_max_speed`` - (``-1 <--> inf``)
  * Limits the max velocity players can reach. Set to 0 for infinite, -1 for auto-calculate.
* ``cl_slide_vmanip`` - (``0/1``)
  * Enables/disables the hand animation when sliding.
* ``cl_cslide_roll`` - (``0/1``)
  * Enables/disables view roll when sliding.
* ``cl_cslide_vm`` - (``0/1``)
  * If this is enabled, the players viewmodel will tilt when sliding if they are not aiming down sights.

# features
- fully predicted
- different sounds for stages of sliding (start, sliding, exit)
- movement reworked support, no hacky workarounds
- vmanip support
- viewmodel tilt, supports almost every weapon base
- speed gain like apex legends, capped to a safe value that can be server-defined
- no sequence changes whatsoever, woe