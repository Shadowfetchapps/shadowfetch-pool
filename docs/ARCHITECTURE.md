# Shadowfetch Pool architecture

`EightBallEngine` settles 8-ball and 9-ball from `ShotEvents` reported by the 3D table. The AI aims with the same impulse path as the player.

Pockets, scratches, first contact, and rail flags are recorded while bodies are awake, then passed to `resolve()` once. A second resolve on the same shot index is rejected.
