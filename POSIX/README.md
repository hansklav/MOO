# MOO, Master Mind, Pico Fermi Bagels

As a programming exercise for a simple command-line game I made a few Oberon versions of the game of Moo.

I started with mooMmPfB.mod which not only plays [Moo (Bulls & Cows)](https://en.wikipedia.org/wiki/Bulls_and_Cows), but also has options to play [Master Mind](https://en.wikipedia.org/wiki/Mastermind_(board_game)) and [Pico Fermi Bagels](https://everything2.com/title/Pico+Fermi+Bagels).</br>
Later I wanted to add a League Table and for this I made moo.mod, a simplified version that only plays classic UNIX MOO.

If you like to study the code it’s best to start with moo0.mod, which has the simplest source text.</br>
I wrote mooC.mod after I had found an original Bell Labs UNIX C&nbsp;source code (moo.c) to figure out what an Oberon version of that would look like; moo.c can be found here: https://www.tuhs.org/cgi-bin/utree.pl?file=SysIII/usr/src/games/moo.c

For me moo0.mod is more readable and understandable than the C&nbsp;source code, also because Oberon can make use of the SET datatype.
