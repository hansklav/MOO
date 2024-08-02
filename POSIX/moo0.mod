MODULE moo0;  (* hk  23-2-2023 *)
(** 
 *  Oberon-07 implementation of the game of MOO (Bulls & Cows). Simple version without ladder.
 *  For the POSIX command-line. Compiled with OBNC (http://miasap.se/obnc/).
 *)

	IMPORT Input, In, Out, Random, Strings, Args := extArgs;
	
	CONST SIZE = 4;  TEN = 10; 

	VAR nBulls, nCows, nGuesses: INTEGER;
	  code: ARRAY SIZE OF CHAR;
	  guess: ARRAY TEN OF CHAR;
	  
	PROCEDURE WriteLn (s: ARRAY OF CHAR);
	BEGIN Out.String(s); Out.Ln
	END WriteLn;
	  
	PROCEDURE Instruct;  (* set of instructions for the game *)
	BEGIN
		Out.Ln;
		WriteLn("The rules of MOO, or 'Bulls & Cows':");
		WriteLn("Dealer picks a code of four different decimal digits, e.g. 6182,");
		WriteLn("player guesses the code, e.g. 0123.");
		WriteLn("Dealer tells player the number of Bulls and Cows: 1 bull, 1 cow");
		WriteLn("  Bulls: number of correct digits in the right place (viz. 1)");
		WriteLn("  Cows:  number of correct digits in the wrong place (viz. 2)");
		WriteLn("4 bulls indicates that player correctly guessed the code.");
		WriteLn("The number of guesses is given at the end of each game.");
		WriteLn("When a game is finished, another one begins immediately.");
		WriteLn("If a player does not wish to continue playing, he or she");
		WriteLn("should type q and enter.");
		Out.Ln;
		WriteLn("Have fun!");
		Out.Ln	
	END Instruct;
	
	PROCEDURE NumGen;  (* generate number consisting of SIZE unique random digits *)
		VAR i, n: INTEGER;  numSet: SET;
	BEGIN
		i := 0;  numSet := {};
		REPEAT
			n := Random.Int(0, 9);
			IF ~(n IN numSet) THEN  (* unique digit found *)
				code[i] := CHR(n + ORD("0"));
				INCL(numSet, n);
				INC(i)
			END
		UNTIL i = SIZE
	END NumGen;
	
	PROCEDURE PrintOut;
	BEGIN
		Out.Int(nBulls, 0);
		IF nBulls = 1 THEN Out.String(" bull,  ") ELSE Out.String(" bulls, ") END;
		Out.Int(nCows, 0);
		IF nCows = 1 THEN Out.String(" cow") ELSE Out.String(" cows") END; Out.Ln 
	END PrintOut;
	
	PROCEDURE TakeGuess(): INTEGER;  (* take input guess *)
		VAR t, res: INTEGER;  askGuess: BOOLEAN;
		
		PROCEDURE AllDigits (s: ARRAY OF CHAR): BOOLEAN;
			VAR i: INTEGER; res: BOOLEAN;
		BEGIN res := TRUE;
			FOR i := 0 TO Strings.Length(s) - 1 DO
				IF (s[i] < "0") OR (s[i] > "9") THEN res := FALSE END
			END
		RETURN res
		END AllDigits;
		
	BEGIN
		res := 0;  askGuess := TRUE;
		WHILE askGuess DO
			WriteLn("? ");
			t := Input.Time();  (* to prevent infinite loop on ^D *)
		  In.Line(guess);
			IF (Strings.Length(guess) = SIZE) & AllDigits(guess) THEN 
				askGuess := FALSE
			ELSIF (guess[0] = "q") & (guess[1] = 0X) OR (Input.Time() - t < 100) THEN
				askGuess := FALSE;  res := 1
			ELSE
				WriteLn("bad guess")
			END
		END
	RETURN res  (* res = 0: go on with the program;  res = 1: quit the program *)
	END TakeGuess;
	
	PROCEDURE Match;  (* matching of player's guess and actual code *)
		VAR i: INTEGER;
			numSet: SET;
	BEGIN numSet := {};
		FOR i := 0 TO SIZE - 1 DO INCL(numSet, ORD(code[i]) - ORD("0")) END;
		FOR i := 0 TO SIZE - 1 DO
			IF guess[i] = code[i] THEN 
				INC(nBulls)
			ELSIF ORD(guess[i]) - ORD("0") IN numSet THEN 
				INC(nCows)
			END
		END
	END Match;
		
	PROCEDURE Usage;
	BEGIN
		WriteLn("Usage: moo [-? | -h] [-i]");
		WriteLn("  -? | -h  display this message.");
		WriteLn("  -i       display game instructions.");
	END Usage;

	PROCEDURE HandleOptions;
		VAR i, k, res: INTEGER;
			arg: ARRAY 8 OF CHAR;
	BEGIN
		FOR i := 0 TO Args.count - 1 DO
			Args.Get(i, arg, res);
			IF arg[0] = "-" THEN
				k := 1;
				WHILE arg[k] # 0X DO
					IF    arg[k] = "i" THEN Instruct
					ELSIF (arg[k] = "?") OR (arg[k] = "h") THEN Usage; ASSERT(FALSE)
					ELSE WriteLn("illegal option -- "); Out.Char(arg[k]); Out.Ln; Usage; ASSERT(FALSE)
					END;
					INC(k)
				END
			END 
		END
	END HandleOptions;
  
	PROCEDURE Main;
		VAR a: INTEGER;
	BEGIN 
		HandleOptions;
		WriteLn("MOO");
		REPEAT
			WriteLn("new game");
			nBulls := 0;  nCows := 0;  nGuesses := 0;
			NumGen;
			WHILE nBulls < SIZE DO
				nBulls := 0;  nCows := 0;
				a := TakeGuess();
				IF a # 1 THEN
					INC(nGuesses);
					Match;
					PrintOut
				ELSE (* a = 1 *)
					ASSERT(FALSE)
				END
			END;
			Out.Int(nGuesses, 0); WriteLn(" guesses"); Out.Ln;
		UNTIL FALSE 
	END Main;
	
BEGIN	
	Main
END moo0.
