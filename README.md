# MOO
The game of MOO.

While glancing through the [First Edition UNIX Programmer's Manual](https://web.archive.org/web/20060302222731/http://www.cs.bell-labs.com:80/who/dmr/1stEdman.html) (1971) I was struck by the following page in [Section VI](https://web.archive.org/web/20060314024422/http://cm.bell-labs.com/cm/cs/who/dmr/man61.pdf) ('User-maintained programs'): 
```
11/3/71                                                      MOO (VI)

NAME               moo -- a game      
SYNOPSIS           /usr/games/moo
DESCRIPTION        moo is a guessing game imported from England.
FILES
SEE ALSO
DIAGNOSTICS
BUGS
OWNER              ken
```
The programmer of this game, Ken Thompson, is also the author of the UNIX Operating System. He wrote several games for UNIX version 1.0 (Blackjack, Chess, a 3D self-learning version of Tic-tac-toe), and they all have more extensive descriptions in the Manual. So I was intrigued by this game ‘moo’, which I had never heard of.

I appeared that Moo is also known as ‘Bulls and Cows’, and is the forerunner of MasterMind, which I did know. In a pencil-and-paper version it has been played by schoolchildren in Britain for decades. The rules are simple:
* Guess the 4-digit code, of which all digits must be distinct.
* Bulls: the number of correct digits in the right place.
* Cows:  the number of correct digits in the wrong place.

E.g. if 5046 is the secret code, then a guess of 3456 is one bull (the 6) and two cows (the 4 and 5). 

