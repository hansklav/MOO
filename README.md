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

E.g. if 5046 is the secret code, then a guess of 3456 is one bull (the 6) and two cows (the 4 and 5). The purpose of the game is to get ‘four bulls’ (code correctly guessed) in as few tries as possible. 

The first computer implementations of Bulls and Cows were the MOO program written in 1968 by Dr. Frank King for [TITAN](https://en.wikipedia.org/wiki/Titan_(1963_computer)), the Cambridge University Atlas&nbsp;2 computer. Several years later it was ‘imported from England’ into the USA when J.S. Felton wrote a version for the TSS/8 time sharing system of DEC's PDP-8, and Jerrold Grochow did so for the Multics system at MIT in 1970.
The game was introduced to a wider audience in the Computer Recreations column of the April-June 1971 issue of Software–Practice and Experience.
