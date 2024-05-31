MODULE mooMmPfb;  (* hk  2019 *)

(* `´                                                                  
	 M  O  O --  The game of Moo (Bulls & Cows, Master Mind, Pico Fermi Bagels).
	 /\  /´`\    Command-line version.                                              

	The first computer implementations of Bulls and Cows were the MOO program
	written in 1968 by Dr. Frank King for TITAN, the Cambridge University ATLAS;
	a version for the TSS/8 time sharing system written by J.S. Felton; and a 1970
	version written for the Multics system at MIT by Jerrold Grochow. 
	It also appeared the 1st Ed. UNIX Programmer's Manual (1971).
	The game was introduced to a wider audience in the Computer Recreations
	column of the April-June 1971 issue of Software, Practice & Experience.

	Rules for the original game of Moo:
		Guess the N-digit code, all digits must be distinct and by default N = 4.
		Bulls: the number of correct digits in the right place.
		Cows:  the number of correct digits in the wrong place.

	For a discussion of the optimal playing stategy see:
	https://web.archive.org/web/20120425120039/http://www.jfwaf.com/Bulls%20and%20Cows.pdf


	* Options *
	
	Set N, the numbers of digits of the code:
		-3 -4 -5 -6

	Option for Classic output of UNIX 1st Ed. MOO (1971), which is a bit less
	readable and in which the final guess is not counted as a move:
		-C

	Option for Master Mind mode:
		-M
	In Master Mind mode the code has 4 digits (1-6) and repetitions are permitted.
	In this mode Bulls are called 'Blacks', and Cows are called 'Whites'.
	If there are duplicate digits in the guess, they cannot all be awarded a
	White or Black unless they correspond to the same number of duplicate digits
	in the hidden code.
	For example, if the hidden code is 1122 and the player guesses 1112, the
	codemaker will award two Blacks for the two correct digits 1, nothing for the
	third 1 as there is not a third 1 in the code, and a Black for the 2.
	No indication is given of the fact that the code also includes a second 2.
	See: Donald E. Knuth, The Computer as Master Mind, J. Recreational Math.
	9(1), 1976-77, 1-6.

	Option for Pico Fermi Bagels (PFB) mode:
		-P
	In PFB mode the code has 3 digits (0-9) and by default no repetitions are
	permitted. In this mode a Cow is 'Pico', a Bull is 'Fermi', and neither Bull
	nor Cow is 'Bagels'.
	Pico Fermi Bagels originates from the Lawrence Hall of Science in Berkeley in
	the early '70s. See: https://www.armoredpenguin.com/bagels/ and
  https://communicrossings.com/html/js/pfb.htm
*)

	IMPORT In, Out, Random, Args := extArgs;

	CONST
		version = "1.0.2";
		max = 6;           (* maximum number of digits in the code *)
		len = max + 1;     (* length of type InputString, including terminating 0X *)
		ESC = 1BX;  CR = 0DX;  LF = 0AX;
		EOF = 0FFX;        (* ctrl-D on the Posix command line *)


	TYPE
		Code = ARRAY max OF INTEGER;
		InputString = ARRAY len OF CHAR;


	VAR
		theCode,           (* initialized by MakeCode *)
		theGuess: Code;    (* initialized by WellFormed *)

		N: INTEGER;        (* number of digits of theCode & theGuess, by default N = 4 *)
		bulls, cows, turn: INTEGER;  (* game variables *)

		(* program options *)
		help, classic, verbose, debug, rep, masterMind, pfb: BOOLEAN;

		helpLevel: INTEGER;
		codeGiven: BOOLEAN;
		firstTime: BOOLEAN;
    mode:      INTEGER;

	PROCEDURE PrintName;
	BEGIN
		Out.String("moo -- The game of MOO (Bulls & Cows, ~ Master Mind, ~ Pico Fermi Bagels)");
		Out.Ln
	END PrintName;

	PROCEDURE PrintHelp;
	BEGIN
		Out.String("Usage: moo [-hvr] [-3 | -4 | -5 | -6] [-C | -M | -P ]"); Out.Ln;
		Out.String("  -h    display help and exit;  -hv | -vh: display more help."); Out.Ln;
		Out.String("  -v    verbose: display more text in help and during the game."); Out.Ln;
		Out.String("  -r    repetitions permitted; default is no repetitions."); Out.Ln;
		Out.String("  -N    N is the length of the code, e.g. -5  (2 < N < 7, by default N = 4)."); Out.Ln;
		Out.String("  -C    Classic UNIX MOO: original output, N = 4 and last guess is not counted."); Out.Ln;
		Out.String("  -M    Master Mind mode:"); Out.Ln;
		Out.String("        N = 4, possible digits 1-6 and repetitions permitted."); Out.Ln;
		Out.String("  -P    Pico Fermi Bagels (pfb) mode:"); Out.Ln;
		Out.String("        N = 3, possible digits 0-9."); Out.Ln;
	END PrintHelp;

	PROCEDURE PrintRules;
	BEGIN
		Out.String("The rules of MOO (= Bulls & Cows):"); Out.Ln;
		Out.String("Dealer picks a code of N different decimal digits 0-9 (by default N = 4), "); Out.Ln;
		Out.String("player guesses the code."); Out.Ln;
		Out.String("Dealer tells player the number of Bulls and Cows: "); Out.Ln;
		Out.String("  Bulls: number of correct digits in the right place."); Out.Ln;
		Out.String("  Cows:  number of correct digits in the wrong place."); Out.Ln;
		Out.String("This implementation has three special modes:"); Out.Ln;
		Out.String("-C *Classic* UNIX 1st Ed. MOO, 1971 (N = 4, last guess is not counted.)"); Out.Ln;
		Out.String("-M *Master Mind* mode: the code always has 4 digits,"); Out.Ln;
		Out.String("  possible digits are 1-6 and repetitions are permitted."); Out.Ln;
		Out.String("  In this mode Bulls are called 'Blacks' and Cows 'Whites'."); Out.Ln;
		Out.String("-P *Pico Fermi Bagels* mode: the code always has 3 digits,"); Out.Ln;
		Out.String("  possible digits are 0-9 and by default no repetitions"); Out.Ln;
		Out.String("  are allowed. In this mode a Cow is 'Pico', a Bull is 'Fermi',"); Out.Ln;
		Out.String("  and Bull nor Cow is 'Bagels'.");
		Out.Ln;
		Out.String("Input q aborts the game."); Out.Ln
	END PrintRules;
	
 
  PROCEDURE HALT; 
  BEGIN ASSERT(FALSE)  (* Exit the program *)
  END HALT;
  
  PROCEDURE Length (s: ARRAY OF CHAR): INTEGER;
		VAR i: INTEGER;
	BEGIN i := 0;
		WHILE s[i] # 0X DO INC(i) END
	RETURN i
  END Length;

	PROCEDURE AllDigits (s: ARRAY OF CHAR): BOOLEAN;
		VAR i: INTEGER; res: BOOLEAN;
	BEGIN
		res := TRUE;
		FOR i := 0 TO Length(s) - 1 DO
			IF (s[i] < "0") OR (s[i] > "9") THEN res := FALSE END
		END
	RETURN res
	END AllDigits;


	PROCEDURE HandleOptions;
		VAR i, j, k, res: INTEGER;
			arg: ARRAY 8 OF CHAR;
			
		PROCEDURE PrintInvalidArgument (arg: ARRAY OF CHAR);
		BEGIN
			Out.String("moo: invalid argument "); Out.String(arg); Out.Ln;
			PrintHelp;
			HALT
		END PrintInvalidArgument;

		PROCEDURE PrintInvalidOption (arg: ARRAY OF CHAR);
		BEGIN
			Out.String("moo: invalid option "); Out.String(arg); Out.Ln;
			PrintHelp;
			HALT
		END PrintInvalidOption;

		PROCEDURE PrintArgTooLong;
		BEGIN
			Out.String("moo: argument too long."); Out.Ln;
			PrintHelp;
			HALT
		END PrintArgTooLong;

	BEGIN
		classic := FALSE; verbose := FALSE; codeGiven := FALSE; debug := FALSE;
		masterMind := FALSE; pfb := FALSE; rep := FALSE; help := FALSE; helpLevel := 0;
		FOR i := 0 TO Args.count - 1 DO
			Args.Get(i, arg, res);
			IF res = 0 THEN
				IF arg[0] = "-" THEN
					(* OBNC cannot compare non-ASCII characters, but can compare strings with them *)
					IF arg = "-ç" THEN (* undocumented: give a code *) 
						IF i < Args.count - 1 THEN INC(i); Args.Get(i, arg, res) END;
						IF res = 0 THEN
							FOR j := 0 TO N - 1 DO
								IF ( ORD("0") <= ORD(arg[j]) ) & ( ORD(arg[j]) <= ORD("9") ) THEN
									theCode[j] := ORD(arg[j]) - ORD("0");
									codeGiven := TRUE
								ELSE
									codeGiven := FALSE
								END
							END;
							IF ~codeGiven THEN Out.String("bad code"); Out.Ln; HALT END
						END
					ELSE (* arg # "-ç" *)
						k := 1;
						WHILE arg[k] # 0X DO
							IF    arg[k] = "3" THEN N := 3; mode := 10;
							ELSIF arg[k] = "4" THEN N := 4; mode := 30;  (* default value *)
							ELSIF arg[k] = "5" THEN N := 5; mode := 50;
							ELSIF arg[k] = "6" THEN N := 6; mode := 70;
							ELSIF arg[k] = "h" THEN help := TRUE; INC(helpLevel)
							ELSIF arg[k] = "r" THEN rep := TRUE; mode := mode + 10;
							ELSIF arg[k] = "v" THEN verbose := TRUE; INC(helpLevel)
							ELSIF arg[k] = "C" THEN classic := TRUE; N := 4; rep := FALSE; mode := 0;
							ELSIF arg[k] = "M" THEN masterMind := TRUE; N := 4; rep := TRUE; mode := 90;
							ELSIF arg[k] = "P" THEN pfb := TRUE; N := 3; mode := 100;
							ELSIF arg[k] = "d" THEN debug := TRUE  (* undocumented: code revealed *)
							ELSE PrintInvalidOption(arg)
							END;
							INC(k)
						END; (* WHILE *)
						IF help THEN
							IF helpLevel = 1 THEN PrintName; PrintHelp; HALT
							ELSIF helpLevel > 1 THEN PrintName; PrintHelp; PrintRules; HALT
							END
						END;	
					END (* IF arg = "-ç" *)
				ELSIF AllDigits(arg) & codeGiven THEN (* do nothing *)
				ELSE (* (arg[0] # "-") & ~AllDigits(arg) *)
					PrintInvalidArgument(arg)
				END (* IF arg[0] = "-" *)
			ELSE (* res # 0, so command-line argument too long *)
				PrintArgTooLong
			END (* IF res = 0 *)
		END (* FOR *)
	END HandleOptions;


	(* The Game *)

	PROCEDURE OutputCode (code: Code);
		VAR i: INTEGER;
	BEGIN
		FOR i := 0 TO N - 1 DO Out.Int(code[i], 0) END
	END OutputCode;


	PROCEDURE Intro;
	BEGIN
		IF verbose & firstTime & ~classic THEN
			Out.Ln;
			Out.String("MOO v. "); Out.String(version); Out.Ln;
			Out.String("BY"); Out.Ln;
			Out.String("HANS KLAVER, 2019"); Out.Ln;
			Out.Ln;
			IF masterMind THEN
				Out.String("Master Mind mode:"); Out.Ln;
				Out.String("Guess the code of 4 digits 1-6, repetitions permitted."); Out.Ln;
				Out.String("Blacks (B): number of correct digits in the right place."); Out.Ln;
				Out.String("Whites (W): number of correct digits in the wrong place, "); Out.Ln;
				Out.String("but each B/W digit cannot be used in more than one hit."); Out.Ln;
				Out.String("E.g. if the code is 2532 and the guess 3523, the answer is BWW:"); Out.Ln;
				Out.String("a B for the 5, a W for one 3 and a W for the 2; so no indication that"); Out.Ln;
				Out.String("there is an additional 2 in the code and another 3 in the guess."); Out.Ln;
			ELSIF pfb THEN
				Out.String("Pico Fermi Bagels mode:"); Out.Ln;
				Out.String("Guess the code of 3 (by default different) digits 0-9."); Out.Ln;
				Out.String("You get a 'Pico' for each correct digit in the wrong place."); Out.Ln;
				Out.String("You get a 'Fermi' for each correct digit in the right place."); Out.Ln;
				Out.String("You get 'Bagels' if no digit is right."); Out.Ln;
			ELSIF ~classic THEN
				Out.String("The game of MOO (= Bulls & Cows)"); Out.Ln;
				Out.String("Guess the code of "); Out.Int(N, 0);
				Out.String(" different digits 0-9."); Out.Ln;
				Out.String("Bulls: number of correct digits in the right place."); Out.Ln;
				Out.String("Cows:  number of correct digits in the wrong place."); Out.Ln;
			END; Out.Ln;
			firstTime := FALSE
		END;
		IF debug THEN Out.String("theCode = "); OutputCode(theCode); Out.Ln END;
		IF masterMind THEN
			Out.String("Master Mind"); Out.Ln;
			Out.String("     Guess  B   W"); Out.Ln
		ELSIF pfb THEN
			Out.String("Pico Fermi Bagels"); Out.Ln
		(* MOO *)
		ELSIF verbose & ~classic THEN
			Out.String("     Guess  Bulls Cows"); Out.Ln
		ELSE  (* UNIX MOO *)
			verbose := FALSE;
			IF firstTime THEN Out.String("MOO"); Out.Ln;  firstTime := FALSE  END;
			Out.String("new game"); Out.Ln
		END
	END Intro;


	PROCEDURE MakeNewCode;
	(*
		Initializes global variable theCode with N possibly unique digits in the range 0..9
		or 1..6 in Master Mind mode.
		Called by Start.
	*)
		VAR i, n, max: INTEGER; theSet: SET;
	BEGIN
		i := 0;  theSet := {};
		IF masterMind THEN max := 5 ELSE max := 9 END;
		REPEAT
			n := Random.Int(max);
			IF masterMind THEN n := n + 1 END;  (* 0..5 -> 1..6 *)
			IF ~rep THEN  (* only unique numbers allowed *)
				IF ~(n IN theSet) THEN  (* found another unique number *)
					theCode[i] := n;
					INCL(theSet, n);
					INC(i)
				END
			ELSE  (* repetitions allowed *)
				theCode[i] := n;
				INC(i)
			END
		UNTIL i = N
	END MakeNewCode;


	PROCEDURE WellFormed (s: ARRAY OF CHAR): BOOLEAN;
	(*
		Called by NextTurn. 
		Assigns the global variable theGuess a new value and reports if it's well-formed.
		By default returns TRUE if s has N unique digits but when rep = TRUE (i.e. with 
		option -r or in masterMind mode) they need not be unique.
	*)
		VAR i, d: INTEGER;
			digits: SET;
			res: BOOLEAN;
	BEGIN
		res := TRUE;
		IF (Length(s) = N) & AllDigits(s) THEN
			digits := {};
			FOR i := 0 TO N - 1 DO
				d := ORD(s[i]) - ORD("0");
				IF rep THEN  (* repetitions permitted *)
					IF masterMind THEN
						IF (d < 1) OR (d > 6) THEN res := FALSE END
					END
				ELSE  (* check unicity of the digits *)
					IF d IN digits THEN res := FALSE
					ELSE INCL(digits, d)
					END;
				END;
				theGuess[i] := d
			END (* FOR *)
		ELSE
			res := FALSE
		END
	RETURN res
	END WellFormed;


	PROCEDURE CountBullsAndCows;
	(* Updates the global variables bulls and cows. Called by NextTurn.*)
		VAR i, j: INTEGER;
			theCodeSet: SET;
			cUsed, gUsed: ARRAY max OF BOOLEAN;
	BEGIN
		bulls := 0;  cows := 0;
		IF ~rep THEN  (* no repetitions allowed *)
			theCodeSet := {}; FOR i := 0 TO N - 1 DO INCL(theCodeSet, theCode[i]) END;
			FOR i := 0 TO N - 1 DO
				IF theGuess[i] = theCode[i] THEN INC(bulls)
				ELSIF theGuess[i] IN theCodeSet THEN INC(cows)
				END;
			END
		ELSE  (* repetitions are allowed; now the algorithm is more convoluted *)
			FOR i := 0 TO max - 1 DO cUsed[i] := FALSE; gUsed[i] := FALSE END;
			(* First count all bulls *)
			FOR i := 0 TO N - 1 DO
				IF theGuess[i] = theCode[i] THEN
					INC(bulls);
					cUsed[i] := TRUE;
					gUsed[i] := TRUE;
				END
			END;
			(* Now count the cows *)
			FOR i := 0 TO N - 1 DO
				FOR j := 0 TO N - 1 DO
					IF (theGuess[i] = theCode[j]) & ~gUsed[i] & ~cUsed[j] THEN
						INC(cows);  gUsed[i] := TRUE;  cUsed[j] := TRUE
					END
				END
			END
		END (* IF ~rep *)
	END CountBullsAndCows;


	PROCEDURE NextTurn;

		VAR i: INTEGER;  ch: CHAR;  s: InputString;

		PROCEDURE StopGame(ch: CHAR);
		(* undocumented *)
		BEGIN
			IF (ch = "Q") OR (ch = "?") THEN
				Out.String("The code was "); OutputCode(theCode); Out.Ln
			END;
			HALT
		END StopGame;

		PROCEDURE InputErrorMessage;
		BEGIN
			IF verbose OR masterMind OR pfb THEN
				Out.String("Enter a code of "); Out.Int(N, 0);
				IF ~rep & ~masterMind THEN  (* no repetitions permitted *)
					Out.String(" unique digits (0-9)")
				ELSIF masterMind THEN
					Out.String(" digits (1-6)")
				ELSE
					Out.String(" digits (0-9)")
				END
			ELSE  (* UNIX MOO *)
				Out.String("bad guess")
			END;
			Out.Ln
		END InputErrorMessage;

	BEGIN 
		INC(turn);
		IF verbose OR masterMind OR pfb THEN
			Out.Int(turn, 2); Out.String(".  ")
		ELSE  (* UNIX MOO *)
			Out.String("? ")
		END;
		FOR i := 0 TO len - 1 DO s[i] := 0X END;  (* initialize input string s *)
		i := 0;  In.Char(ch);
		IF ch = EOF THEN Out.Ln; HALT END;        (* ctrl-D *)
		WHILE (ch # LF) & (ch # CR) & (i < len - 1) DO
			s[i] := ch; In.Char(ch); INC(i) 
		END;
		IF (Length(s) = 1) & ((s[0] = "q") OR (s[0] = "Q") OR (s[0] = "?")) THEN
			StopGame(s[0])
		ELSIF WellFormed(s) THEN  (* theGuess is updated by WellFormed *)
			CountBullsAndCows;
			IF ~classic THEN
				(* ANSI escape code to move cursor up one line *)
			  Out.Char(ESC); Out.String("[A");
			END;
			IF verbose OR masterMind OR pfb THEN
				Out.Int(turn, 2); Out.String(".  ");
				OutputCode(theGuess);
			END;
			IF ~pfb THEN
				IF masterMind THEN
					Out.Int(bulls, 8 - N); Out.Int(cows, 4);
				ELSIF verbose THEN (* MOO *)
					Out.Int(bulls, 9 - N); Out.Int(cows, 6)
				ELSE (* UNIX MOO *)
					IF classic THEN  (* Classic UNIX MOO *)
						Out.Int(bulls, 4 - N);
					ELSE       (* more readable UNIX MOO *)
						Out.String("  "); OutputCode(theGuess);
						Out.Int(bulls, 8 - N);
					END;
					IF bulls = 1 THEN Out.String(" bull;  ") ELSE Out.String(" bulls; ") END;
					Out.Int(cows, 0);
					IF cows = 1 THEN Out.String(" cow") ELSE Out.String(" cows") END
				END
			ELSE  (* pfb *)
				Out.String("  ");
				IF (bulls = 0) & (cows = 0) THEN
					Out.String("Bagels")
				ELSE
					FOR i := 1 TO bulls DO Out.String("Fermi ") END;
					FOR i := 1 TO cows DO Out.String("Pico ") END;
					IF bulls = 3 THEN Out.String("!!!"); Out.Ln END
				END
			END;
			Out.Ln;
		ELSE
			DEC(turn); InputErrorMessage
		END
	END NextTurn;


	PROCEDURE Play*;
		VAR res: INTEGER;
		
		PROCEDURE ShowResult;
		BEGIN
			IF turn = 1 THEN
				Out.String("1 move!")
			ELSE
				Out.Int(turn, 0); Out.String(" moves.")
			END
		END ShowResult;

	BEGIN
		bulls := 0; cows := 0; turn := 0;
		Intro;
		REPEAT
			NextTurn
		UNTIL bulls = N;
		
		IF verbose THEN Out.String("You found the code in ") END;
		IF masterMind OR pfb THEN
			ShowResult
		ELSE  (* MOO *)
  		IF classic THEN res := turn - 1 ELSE res := turn END;    
		  Out.Int(res, 0); IF res = 1 THEN Out.String(" guess") ELSE Out.String(" guesses") END
		END;
		Out.Ln; Out.Ln;
		
		(* Start a new game *)
		MakeNewCode;
		Play
	END Play;


BEGIN
	N := 4;
	Random.Randomize;
	HandleOptions;  IF ~codeGiven THEN MakeNewCode END;
	firstTime := TRUE;
	Play
END mooMmPfb.
