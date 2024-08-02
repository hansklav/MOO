MODULE mooC;  (* hk  20-2-2023 *)
(** 
 *  Oberon-07 implementation of the game of MOO (Bulls & Cows). Simple version without ladder.
 *  Tries to stay as close to the C-code of moo.c as possible.
 *  For the POSIX command-line. Compiled with OBNC (http://miasap.se/obnc/).
 *)
 
	IMPORT Input, In, Out, Random, Strings, Args := extArgs;
	
	CONST SIZE = 4;  TEN = 10;  

	VAR nBulls, nCows, nAttempts, a: INTEGER;
	  number: ARRAY SIZE OF CHAR;
	  guess: ARRAY TEN OF CHAR;
	  
	PROCEDURE HALT;  (* exit the program *)
	BEGIN ASSERT(FALSE) 
	END HALT;
	  
	PROCEDURE WriteLn (s: ARRAY OF CHAR); 
	BEGIN Out.String(s); Out.Ln 
	END WriteLn;
	  
	PROCEDURE Instruct;  (* set of instructions for the game *)
	BEGIN
		Out.Ln;
		WriteLn("How to play MOO:");
		WriteLn("The computer selects a random number which consists of four different digits.");
		WriteLn("The objective of the game is for the player to guess the correct digits and");
		WriteLn("their correct positions.");
		WriteLn("A correctly guessed digit and its position is called a bull.");
		WriteLn("A cow is when a number is correctly guessed but not its position.");
		WriteLn("A player correctly guesses the number when the number of bulls is equal to four.");
		WriteLn("The number of attempts that the player took to guess is given at the end of each");
		WriteLn("game. When a game is finished (bulls = 4), another one begins immediately.");
		WriteLn("If the player does not wish to continue playing, he or she should type");
		WriteLn("^Z (ctrl + Z) or Q followed by enter.");
		WriteLn("Have fun!");
		Out.Ln	
	END Instruct;

	PROCEDURE NumGen;  (* generate number consisting of four different random digits *)
		VAR i, j, mark: INTEGER;  break: BOOLEAN;
	BEGIN
		i := 0;
		WHILE i < SIZE DO
			mark := 0;
			number[i] := CHR(ORD("0") + Random.Int(0, 9));
			j := i - 1;  break := FALSE;
			WHILE (j >= 0) & ~break DO
				IF number[i] = number[j] THEN 
					mark := 1;
					break := TRUE
				END;
				DEC(j)
			END;
			IF mark = 0 THEN 
				INC(i) 
			END
		END
	END NumGen;

	PROCEDURE PrintOut;
	BEGIN
		Out.String("bulls = ");    Out.Int(nBulls, 0); 
		Out.String("    cows = "); Out.Int(nCows, 0);  Out.Ln 
	END PrintOut;
	
	PROCEDURE TakeGuess(): INTEGER;  (* take input guess *)
		VAR i, t, flag, res: INTEGER;  break: BOOLEAN;
	BEGIN
		flag := 1;  res := 0;
		WHILE flag = 1 DO  (* flag = 1: input not finished; flag = 0: input finished *)
			flag := 0;
			WriteLn("? ");  In.Line(guess);  t := Input.Time();
			IF guess # "" THEN
				IF ((guess[0] = "q") OR (guess[0] = "Q")) & (guess[1] = 0X) THEN
					res := 1
				ELSE
					i := 0;  break := FALSE;
					WHILE (i < SIZE) & ~break DO
						IF (Strings.Length(guess) # SIZE) OR (guess[i] < "0") OR (guess[i] > "9") THEN
							flag := 1;
							WriteLn("bad guess");
							break := TRUE
						END;
						INC(i)
					END
				END
			ELSE (* guess = "" *)
				flag := 1;
		 		IF Input.Time() - t < 100 THEN HALT END;  (* to prevent infinite loop on ^D *)
				WriteLn("bad guess");
			END
		END
	RETURN res  (* res  = 1: quit the program;  res  = 0: go on with the program *)
	END TakeGuess;
	
	PROCEDURE cMatch;  (* matching of player's guess and actual number *)
		VAR i, j: INTEGER;
			break: BOOLEAN;
	BEGIN
		i := 0;  j := 0;
		WHILE i < SIZE DO
			break := FALSE;
			WHILE (j < SIZE) & ~break DO
				IF guess[i] # number[j] THEN 
				  INC(j)
				ELSE
					IF i = j THEN
						INC(nBulls);
					ELSE
						INC(nCows);
					END;
					IF i < SIZE - 1 THEN
						INC(i);
						j := 0
					ELSIF i = SIZE - 1 THEN
						INC(i);
						break := TRUE
					END
		  	END
			END; (* WHILE j *)
		 	IF i < SIZE THEN
		 		INC(i);
		 		j := 0
		 	END
		END (* WHILE i *)
	END cMatch;
		
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
					ELSIF (arg[k] = "?") OR (arg[k] = "h") THEN Usage; HALT
					ELSE WriteLn("illegal option -- "); Out.Char(arg[k]); Out.Ln; Usage; HALT
					END;
					INC(k)
				END
			END 
		END
	END HandleOptions;
	
BEGIN	
	HandleOptions;
	WriteLn("MOO");
	REPEAT
		WriteLn("new game");
		nBulls := 0;  nCows := 0;  nAttempts := 0;
		NumGen;
		WHILE nBulls < SIZE DO
			nBulls := 0;  nCows := 0;
			a := TakeGuess();
			IF a = 1 THEN
				HALT 
			ELSE
				INC(nAttempts);
				cMatch;
				PrintOut
			END
		END;
		Out.String("Attempts = "); Out.Int(nAttempts, 0); Out.Ln;
	UNTIL FALSE
END mooC.
