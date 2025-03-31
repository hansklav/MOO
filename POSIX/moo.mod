MODULE moo;  (* hk  27-4-2023 *)
(*
   `'                                                                  
	 M  O  O --  The game of Moo (Bulls & Cows).
	 /\  /'`\    Oberon-07 command-line version.
   
   For any POSIX compatible operating system (UNIX, Linux, macOS, Windows).
   Compiled with OBNC (http://miasap.se/obnc/).
	 
	 Mimics the user interface of UNIX 1st Ed. MOO (1971), 
	 but adds a ladder ('League table').
*)

	IMPORT In, Out, Files, Random, Strings, Args := extArgs;
	
	CONST
		SIZE = 4;  TEN = 10;  nameLen = 10;  movesLen = 16;  tabLen = 32;
		fileMark = 040506F00H;
		fileName = "MooLeague.Table";
		version  = "MOO 1.0.5";

	TYPE
		Name = ARRAY nameLen OF CHAR;
		
		Line = RECORD                        (* line of data for the League Table *)
			name: Name;
			wAverage, average: REAL;           (* weighted average, simple average *)
			movesToDate, 
			gamesToDate: INTEGER;
			moves: ARRAY movesLen OF INTEGER;  (* frequency of each number of moves (guesses) *)
			pq: INTEGER                        (* premature quits *)
		END;
		
	VAR
	  nBulls, nCows, nGuesses: INTEGER;
	  code: ARRAY SIZE OF CHAR;
	  guess: ARRAY TEN OF CHAR;

	  classic, delete: BOOLEAN;            (* program options *)

		(* League Table *)
		nUsers: INTEGER;                     (* number of users in the League Table *)
		tab: ARRAY tabLen OF Line;           (* array for the League Table *)
		userName: Name;
		f: Files.File;
		r: Files.Rider;
		
		
  (* Utilities *)

  PROCEDURE HALT; 
  BEGIN ASSERT(FALSE)                    (* exit the program *)
  END HALT;
	  
	PROCEDURE WriteLn (s: ARRAY OF CHAR);
	BEGIN Out.String(s); Out.Ln
	END WriteLn;
	
	PROCEDURE WriteRealFix2 (x: REAL);
	(* Write REAL x in fixed point notation with 2 decimals, last decimal rounded *)
		VAR ix: INTEGER;
	BEGIN ASSERT((1.0 <= x) & (x < 99.4));
		ix := FLOOR(x * 100.0 + 0.501);
		IF x < 10.0 THEN Out.Char(" ") END;
		Out.Int(ix DIV 100, 0); Out.Char(".");
		IF ix MOD 100 < 10 THEN Out.Char("0") END;
		Out.Int(ix MOD 100, 0)
	END WriteRealFix2;
	

	(* Options *)  
	
	PROCEDURE Usage;
	BEGIN
		WriteLn("moo - the game of MOO (or Bulls & Cows)");
		WriteLn("usage: moo [-? | -h] [-i] [-c] [-n Name] [-l | -L] [-v]");
		WriteLn("  -? | -h  display this message and exit.");
		WriteLn("  -i       display game instructions and exit.");
		WriteLn("  -c       classic 1st Edition UNIX output.");
		WriteLn("  -n Name  enter your Name for the League Table and start a new game.");
		WriteLn("  -l | -L  display the League Table and exit.");
		WriteLn("  -v       display version number and exit.")
	END Usage;
	
	PROCEDURE Instruct;
	BEGIN
		IF ~ classic THEN
			Out.Ln;
			Out.String(version);
			WriteLn(         "                    `'         ");
			WriteLn("BY                           M  O  O –– ");
			WriteLn("HANS KLAVER, 2023           / \  /'`\   ");
    END;
		Out.Ln;
		WriteLn("The rules of MOO, or 'Bulls & Cows':");
		WriteLn("Dealer picks a code of four different decimal digits, e.g. 6182,");
		WriteLn("player guesses the code, e.g. 0123.");
		WriteLn("Dealer tells player the number of Bulls and Cows: 1 bull, 1 cow");
		WriteLn("  Bulls: number of correct digits in the right place (viz. 1)");
		WriteLn("  Cows:  number of correct digits in the wrong place (viz. 2)");
		WriteLn("4 bulls indicates that player correctly guessed the code.");
		WriteLn("The number of guesses is given at the end of each game.");
		Out.Ln;
		WriteLn("When a game is finished, another one begins immediately; if you then");
		WriteLn("do not wish to continue playing, type q and press the enter/return key.");
		WriteLn("To join the League start the game with ./moo -n YourName (max. 9 chars),");
		WriteLn("then your personal performance data will be shown in the League Table.");
		WriteLn("Entering ? instead of a guess will reveal the code and stop the game");
		WriteLn("(this is only possible if you play anonymously).");
		WriteLn("To review these Instructions start with ./moo -i ");
		Out.Ln;
		WriteLn("Have fun!");
		Out.Ln
	END Instruct;
	
	PROCEDURE ShowLeagueTable;
		VAR i, j, m: INTEGER;
	BEGIN
		f := Files.Old(fileName);
		IF f # NIL THEN  (* League Table file exists *)
			Out.Ln;
			WriteLn("L e a g u e  T a b l e");
			Out.Ln;
			WriteLn("Name       wAvg   Avg mov gam  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15+");
			WriteLn("---------------------------------------------------------------------------");
			Files.Set(r, f, 0);
			Files.ReadInt(r, m);	
			IF m = fileMark THEN
				Files.ReadInt(r, nUsers); 
				i := 0; 
				WHILE i < nUsers DO
					Files.ReadString(r, tab[i].name);
						Out.String(tab[i].name); 
						FOR j := 1 TO nameLen - Strings.Length(tab[i].name) DO Out.Char(" ") END;
						Files.ReadReal(r, tab[i].wAverage); WriteRealFix2(tab[i].wAverage); Out.Char(" ");
						Files.ReadReal(r, tab[i].average);  WriteRealFix2(tab[i].average);
						Files.ReadInt (r, tab[i].movesToDate); Out.Int(tab[i].movesToDate, 4);
						Files.ReadInt (r, tab[i].gamesToDate); Out.Int(tab[i].gamesToDate, 4);
						FOR j := 0 TO movesLen - 1 DO Files.ReadInt(r, tab[i].moves[j]) END;
						FOR j := 1 TO movesLen - 1 DO          Out.Int(tab[i].moves[j], 3) END;
						Files.ReadInt (r, tab[i].pq); Out.String("  ("); Out.Int(tab[i].pq, 0); Out.Char(")");
						Out.Ln;
					INC(i)
				END; Out.Ln
			ELSE
				Out.String("League Table corrupted."); Out.Ln
			END
		ELSE
			Out.String("League Table file does not exist."); Out.Ln
  	END
	END ShowLeagueTable;

	PROCEDURE HandleOptions;
		VAR i, k, res: INTEGER;
			arg, arg1: ARRAY nameLen OF CHAR;
	BEGIN
		FOR i := 0 TO Args.count - 1 DO
			Args.Get(i, arg, res);
			IF arg[0] = "-" THEN
				k := 1;
				WHILE arg[k] # 0X DO
					IF (arg[k] = "n") OR (arg[k] = "d") THEN
						IF arg[1] = "d" THEN delete := TRUE END;
						IF i < Args.count - 1 THEN
							Args.Get(i+1, arg1, res);
							IF (arg1[0] # "-") & (arg1[1] # "-") THEN
								userName := "";  Strings.Insert(arg1, 0, userName)
							END
						END
					ELSIF (arg[k] = "?") OR (arg[k] = "h") THEN Usage; HALT
					ELSIF  arg[k] = "c"                    THEN classic := TRUE
					ELSIF  arg[k] = "i"                    THEN Instruct; HALT
					ELSIF (arg[k] = "l") OR (arg[k] = "L") THEN ShowLeagueTable; HALT
					ELSIF  arg[k] = "v"                    THEN WriteLn(version); HALT
					ELSE Out.String("illegal option: -"); Out.Char(arg[k]); Out.Ln; Usage; HALT
					END;
					INC(k)
				END (* WHILE *)
			END (* IF arg[0] = "-" *)
		END (* FOR *)
	END HandleOptions;

	
  (* Generate number consisting of SIZE random digits *)
  
	PROCEDURE NumGen;
	(* Initializes the global variable 'code' *) 
		VAR i, n: INTEGER;  numSet: SET;
	BEGIN
		i := 0;  numSet := {};
		REPEAT
			n := Random.Int(0, 9);  (* generate a random integer in the closed interval [0..9] *)
			IF ~(n IN numSet) THEN  (* unique digit found *)
				code[i] := CHR(n + ORD("0"));
				INCL(numSet, n);
				INC(i)
			END
		UNTIL i = SIZE
	END NumGen;
	
	
  (* Take input: guess or quit *)
	
	PROCEDURE TakeGuess(): BOOLEAN;
	(* Initializes the global variable 'guess'. 
	   The Boolean result reports the player's wish to continue the game or not. *)
		VAR continue: BOOLEAN;  askGuess: BOOLEAN;  i: INTEGER;
		
		PROCEDURE AllDigits (s: ARRAY OF CHAR): BOOLEAN;
			VAR i: INTEGER; res: BOOLEAN;
		BEGIN res := TRUE;
			FOR i := 0 TO Strings.Length(s) - 1 DO
				IF (s[i] < "0") OR (s[i] > "9") THEN res := FALSE END
			END
		RETURN res
		END AllDigits;	
		
	BEGIN
		continue := TRUE;  askGuess := TRUE;
		WHILE askGuess DO
			FOR i := 0 TO TEN - 1 DO guess[i] := 0X END;
			Out.String("? ");  In.Line(guess);  
			IF In.Done THEN 
				IF (Strings.Length(guess) = 4) & AllDigits(guess) THEN 
					askGuess := FALSE
				ELSIF ((guess[0] = "q") OR (guess[0] = "Q")) & (guess[1] = 0X) THEN
					askGuess := FALSE;  continue := FALSE
				ELSIF (guess[0] = "?") & (guess[1] = 0X) & (userName = "") THEN
					IF ~ classic THEN
						Out.String("The code was ");
						FOR i := 0 TO SIZE - 1 DO Out.Char(code[i]) END; Out.Ln;
						HALT
					END
				ELSE
					WriteLn("bad guess")
				END
			ELSE  (* ~ In.Done *)
				Out.Ln; HALT  (* i.a. prevents infinite loop on ^D *)
			END
		END
	RETURN continue 
	END TakeGuess;
	
	
  (* Matching of player's guess and actual code *)  
	  
	PROCEDURE Match;
		VAR i: INTEGER;
			numSet: SET;
	BEGIN
		numSet := {};
		FOR i := 0 TO SIZE - 1 DO INCL(numSet, ORD(code[i]) - ORD("0")) END;
		FOR i := 0 TO SIZE - 1 DO
			IF guess[i] = code[i] THEN 
				INC(nBulls)
			ELSIF ORD(guess[i]) - ORD("0") IN numSet THEN 
				INC(nCows)
			END
		END
	END Match;
	
	
	(* League Table *)
	
	PROCEDURE InitTabLine (n: INTEGER);
		VAR i: INTEGER;
	BEGIN
		tab[n].name := "";
		tab[n].wAverage := 100.0;
		tab[n].average := 100.0;
		tab[n].movesToDate := 0;
		tab[n].gamesToDate := 0;
		FOR i := 0 TO movesLen - 1 DO tab[n].moves[i] := 0 END;
		tab[n].pq := 0;
	END InitTabLine;			
	

	PROCEDURE SaveTable (register: BOOLEAN);
	(* Save the League Table from main store into a file; if needed, register the file.
		 Only newly created files need registration in the directory. *)
		VAR i, j: INTEGER;
	BEGIN
		Files.Set(r, f, 0);
		Files.WriteInt(r, fileMark);  (* write a magic number used as a file type signature *)
		Files.WriteInt(r, nUsers );   (* number of players in the League Table *)
		FOR i := 0 TO tabLen - 1 DO
			Files.WriteString(r, tab[i].name);
			Files.WriteReal  (r, tab[i].wAverage);
			Files.WriteReal  (r, tab[i].average);
			Files.WriteInt   (r, tab[i].movesToDate);
			Files.WriteInt   (r, tab[i].gamesToDate);
			FOR j := 0 TO movesLen - 1 DO Files.WriteInt(r, tab[i].moves[j]) END;
			Files.WriteInt   (r, tab[i].pq);
		END;
		IF register THEN
			Files.Register(f);  
			Files.Close(f)  (* should have been done by Files.Register, but *is* necessary for OBNC *) 
		ELSE
			Files.Close(f)
		END
	END SaveTable;
	

	PROCEDURE LoadTable;
	(* Load the League Table from a file into main store;
		 create a new empty file if necessary and register it in the directory. *)
		VAR i, j, m: INTEGER;

		PROCEDURE ClearTable;
			VAR i: INTEGER;
		BEGIN
			nUsers := 0;
			FOR i := 0 TO tabLen - 1 DO InitTabLine(i) END
		END ClearTable;			

	BEGIN
		f := Files.Old(fileName);
		IF f = NIL THEN
			IF ~ classic THEN Instruct END;
			f := Files.New(fileName);
			ClearTable;
			SaveTable(TRUE)     (* save and register a new empty file *)
		ELSE
			Files.Set(r, f, 0);
			Files.ReadInt(r, m);
			IF m = fileMark THEN
				Files.ReadInt(r, nUsers );
				FOR i := 0 TO tabLen - 1 DO
					Files.ReadString(r, tab[i].name);
					Files.ReadReal  (r, tab[i].wAverage);
					Files.ReadReal  (r, tab[i].average);
					Files.ReadInt   (r, tab[i].movesToDate);
					Files.ReadInt   (r, tab[i].gamesToDate);
					FOR j := 0 TO movesLen - 1 DO Files.ReadInt(r, tab[i].moves[j]) END;
					Files.ReadInt   (r, tab[i].pq)
				END
			ELSE  (* no FileMark found, so file corrupted (?) *)
				Out.String("League Table corrupted; saving a new empty file."); Out.Ln;
				ClearTable;
				SaveTable(FALSE)  (* save data in existing file; registering unnecessary *)
			END
		END
	END LoadTable;


	PROCEDURE SortTable;
	(* Sort the League Table array with field wAverage as key *)
		VAR i, j, k: INTEGER;  min: Line;
	BEGIN
		FOR i := 0 TO tabLen - 2 DO 
			min := tab[i];  k := i;
			FOR j := i TO tabLen - 1 DO
				IF tab[j].wAverage < min.wAverage THEN k := j; min := tab[k] END 
			END;
			tab[k] := tab[i];  tab[i] := min 
		END
	END SortTable;
	
			
	PROCEDURE DeletePlayer;
		VAR i: INTEGER;
	BEGIN
		(* Search userName *)
		i := 0;  WHILE (i < tabLen) & (tab[i].name # userName) DO INC(i) END;
		IF (i # tabLen) & (tab[i].name = userName) THEN  (* name found *)
			InitTabLine(i);
			SortTable;
			DEC(nUsers );
			Out.String(userName); Out.String(" deleted from the League."); Out.Ln
		END
	END DeletePlayer;


	PROCEDURE UpdateLeagueTable;		

		PROCEDURE RegisterScore;	
			VAR i: INTEGER;
			
			PROCEDURE UpdateLine (n: INTEGER);
			BEGIN
				tab[n].movesToDate := tab[n].movesToDate + nGuesses;
				INC(tab[n].gamesToDate);
				tab[n].wAverage := FLT(20 + 2 * tab[n].movesToDate) / FLT(1 + 2 * tab[n].gamesToDate);
				tab[n].average := FLT(tab[n].movesToDate) / FLT(tab[n].gamesToDate);
				IF nGuesses >= movesLen - 1 THEN 
					INC(tab[n].moves[movesLen - 1]) 
				ELSE 
					INC(tab[n].moves[nGuesses]) 
				END;
			END UpdateLine;
			
		BEGIN
			(* Search userName *)
  		i := 0;  WHILE (i < tabLen) & (tab[i].name # userName) DO INC(i) END;
			IF (i # tabLen) & (tab[i].name = userName) THEN  (* name found *)
			  UpdateLine(i)
			ELSE                                             (* name not found *)
				IF nUsers < tabLen THEN  (* enough room in the table array *)
					(* Add current player in line nUsers *)
					InitTabLine(nUsers);
					tab[nUsers].name := userName;
					UpdateLine(nUsers);  
					INC(nUsers)             
				ELSE
					WriteLn("League table full")  (* Todo: make tabLen larger & recompile *)
				END
			END;
			SortTable 
		END RegisterScore;
			
	BEGIN
		RegisterScore;
		SaveTable(FALSE)  (* FALSE: no registration into the directory necessary *)
	END UpdateLeagueTable;

	
	PROCEDURE PrintOut;
	BEGIN
		IF classic THEN
			Out.Int(nBulls, 4 - SIZE); Out.String(" bulls; ");
			Out.Int(nCows, 0);         Out.String(" cows") 
		ELSE
			Out.Int(nBulls, 4 - SIZE);
			IF nBulls = 1 THEN Out.String(" bull;  ") ELSE Out.String(" bulls; ") END;
			Out.Int(nCows, 0);
			IF nCows = 1 THEN Out.String(" cow") ELSE Out.String(" cows") END
		END; Out.Ln
	END PrintOut;

  
	PROCEDURE Main;
		VAR continue, ended, found: BOOLEAN;
			n: INTEGER;
	BEGIN
		nUsers := 0;  userName := "";  ended := FALSE;
		classic := FALSE;  delete := FALSE;
		HandleOptions;
		LoadTable;
		IF delete THEN 
			DeletePlayer;
			SaveTable(FALSE);
			ShowLeagueTable
		ELSE
			WriteLn("MOO");
			REPEAT
				IF userName = "" THEN 
					Out.String("new game")
				ELSE
					Out.String("new game for "); Out.String(userName);
				END; Out.Ln;
				nBulls := 0;  nCows := 0;  nGuesses := 0;
				NumGen;
				n := 0;  WHILE (n < tabLen) & (tab[n].name # userName) DO INC(n) END;
				IF (n # tabLen) & (tab[n].name = userName) THEN
					found := TRUE;  INC(tab[n].pq);
					SaveTable(FALSE)
				ELSE 
					found := FALSE
				END;
				
				WHILE nBulls < 4 DO
					nBulls := 0;  nCows := 0;
					continue := TakeGuess();
					IF continue THEN
						ended := FALSE;
						INC(nGuesses);
						Match;
						PrintOut
					ELSE
						IF ~ ended THEN  (* attempted premature quit *)
							IF classic THEN
								WriteLn("bad guess")
							ELSE
								WriteLn("It is antisocial to try and quit in the middle of a game.");
    						WriteLn("Please continue.")
    					END
						ELSE
							IF found THEN DEC(tab[n].pq); SaveTable(FALSE) END;
							ShowLeagueTable; 
							HALT
           	END
					END
				END; (* WHILE *)
				ended := TRUE;
				IF found THEN 
					DEC(tab[n].pq); SaveTable(FALSE);
				END;
				IF ~ classic THEN
					WriteLn("`'        ");                                                                 
					WriteLn("M  O  O --");
					WriteLn("/\  /'`\  ")
				END;
				Out.Int(nGuesses, 0); 
				IF nGuesses = 1 THEN WriteLn(" guess") ELSE WriteLn(" guesses") END; Out.Ln;
				IF userName # "" THEN UpdateLeagueTable END
			UNTIL FALSE
		END (* IF delete *)
	END Main;
	
BEGIN
	Main
END moo.

