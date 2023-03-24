# MOO
The game of MOO.

While glancing through the [First Edition UNIX Programmer's Manual](https://web.archive.org/web/20060302222731/http://www.cs.bell-labs.com:80/who/dmr/1stEdman.html) (1971) I was struck by the following page in [Section VI](https://web.archive.org/web/20060314024422/http://cm.bell-labs.com/cm/cs/who/dmr/man61.pdf) (‘User-maintained programs’): 
```
11/3/71                                                     MOO (VI)

NAME               moo -- a game
SYNOPSIS           /usr/games/moo
DESCRIPTION        moo is a guessing game imported from England.
FILES
SEE ALSO
DIAGNOSTICS
BUGS
OWNER              ken
```
The programmer of this game, Ken Thompson, is also the author of the UNIX Operating System. He wrote several other games for UNIX version 1.0 (Blackjack, Chess, a 3D self-learning version of Tic-tac-toe), and they all have more extensive descriptions in the Manual. So I was intrigued by this game ‘moo’, which I had never heard of.

I appeared that Moo is also known as ‘[Bulls and Cows](https://en.wikipedia.org/wiki/Bulls_and_Cows)’, and is the forerunner of [Master Mind](https://en.wikipedia.org/wiki/Mastermind_(board_game)), which I *did* know. In a pencil-and-paper version the game has been played by schoolchildren in Britain for decades. The rules are simple:
* Guess the 4-digit code, of which all digits must be distinct.
* Bulls: the number of correct digits in the right place.
* Cows:  the number of correct digits in the wrong place.

E.g. if 5046 is the secret code, then a guess of 3456 is one bull (the 6) and two cows (the 4 and 5). The purpose of the game is to get ‘four bulls’ (code correctly guessed) in as few tries as possible. 

A simpler version with a 3-digit code is known as [Pico Fermi Bagels](https://everything2.com/title/Pico+Fermi+Bagels).

The first computer implementation of Bulls and Cows was the MOO program written in 1968 in machine-code by Dr. Frank King for [TITAN](https://en.wikipedia.org/wiki/Titan_(1963_computer)), the Cambridge University Atlas&nbsp;2 computer; this program kept a league table showing the performance of its human opponents, which made it very popular in the Computer Laboratory.

Around 1970 it was ‘imported from England’ into the USA when J.S. Felton wrote a version for the TSS/8 time sharing system of DEC's PDP-8, Jerrold Grochow did so [in PL/1](https://web.archive.org/web/20161114010351/http://ftp.stratus.com/vos/multics/pg/pg.html) for the Multics system at MIT, and Guy L. Steele wrote a [BASIC program](https://archive.org/details/h42_DECUS_8-394/page/n3/mode/2up) in DEC's DECUS Program Library for the PDP-10 and -11. 

The game was introduced to a wider audience by <b><large>ℵ</large><sub>0</sub></b> (‘Aleph Null’) in the [Computer Recreations column](https://onlinelibrary.wiley.com/doi/10.1002/spe.4380010210) of the April-June 1971 issue of Software – Practice and Experience.

Moo / Bulls and Cows has attracted quite some attention from mathematicians and computer scientists. It has been shown that using an optimal strategy any Moo secret code can be found in at most seven guesses, and that the best average number of guesses is 5.21. The optimal playing strategy is discussed in several papers, e.g, [here](https://web.archive.org/web/20120425120039/http://www.jfwaf.com/Bulls%20and%20Cows.pdf) and [here](http://slovesnov.users.sf.net/bullscows/bullscows.pdf).

