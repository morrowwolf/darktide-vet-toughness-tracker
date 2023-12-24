# darktide-vet-toughness-tracker
 
A darktide scoreboard addition to help track certain veteran toughness regeneration amounts. Not currently supporting any abilities or non-veteran talents.

Requires: https://www.nexusmods.com/warhammer40kdarktide/mods/22

Installation:

Insure you have the scoreboard mod and all of its requirements installed correctly. Install instructions at nexusmods link above.  
Download this repo  
Put toughness_tracker folder in ..\steamapps\common\Warhammer 40,000 DARKTIDE\mods (should be made by darktide mod framework which is a dependency of scoreboard)  
Enable toughness_tracker by adding "toughness_tracker" to mod_load_order.txt (should be made by darktide mod framework which is a dependency of scoreboard)  

This mod is imperfect due to constraints on data sent from the server to the client. This mod does it's best to recreate what the server is likely to do. Sadly, a number of factors can make these estimations inaccurate from latency to client state inaccuracies to recordings happening before or after an actual event. As a note, these are issues with all of the current scoreboard implementations but something to be mindful of.

This mod currently tracks:  
Total toughness gained  
Melee toughness gained  
Out For Blood talent toughness gained  
Exhilarating Takedown talent toughness gained  
Confirmed Kill talent toughness gained  
Born Leader talent toughness given to allies  

This mod tracks both the total gained (as if you did not have a cap on toughness) and effective gained (which is what you actually gained due to having a maximum toughness).

This mod currently assumes you, and everyone else in the lobby, have all of these traits. This mod is not currently accurate for born leader or total if you do not have all of the talents listed. This mod was entirely to gauge the effectiveness of the various talents together.

Feel free to fork and improve. I may eventually get around to making it less of a blunt tool for my own understanding of talent usefulness and more of a general use mod with many options and considerations. No promises.

Any questions may be directed to Morrow on discord. Happy modding.
