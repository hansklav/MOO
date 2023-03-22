MODULE moo;  (* hk  22-3-2023 *)
(*
   `´                                                                  
	 M  O  O --  The game of Moo (Bulls & Cows).
	 /\  /´`\    Oberon-07 command-line version.
   
   For any POSIX compatible operating system (UNIX, Linux, macOS, Windows).
   Compiled with the OBNC compiler (http://miasap.se/obnc/).
	 
	 Mimics the user interface of UNIX 1st Ed. MOO (1971), 
	 but adds a ladder ('League table').
*)

	IMPORT Input, In, Out, Files, Random, Strings, Args := extArgs;
	
	CONST
		SIZE = 4;  TEN = 10;  nameLen = 10;  movesLen = 17;  tabLen = 32;
		fileMark = 040506F00H;
		fileName = "MooLeague.Table";

	TYPE
		Name = ARRAY nameLen OF CHAR;
		
		Line = RECORD                        (* line of data for the League Table *)
			name: Name;
			wAverage, average: REAL;           (* weighted average, simple average *)
			movesToDate, 
			gamesToDate: INTEGER;
			moves: ARRAY movesLen OF INTEGER   (* frequency of each number of moves (guesses) *)
		END;
		
	VAR
	  nBulls, nCows, nGuesses: INTEGER;
	  code: ARRAY SIZE OF CHAR;
	  guess: ARRAY TEN OF CHAR;
	  verbose, delete: BOOLEAN;            (* program options *)
	  
		(* League Table *)
		N: INTEGER;                          (* number of users in the League Table *)
		tab: ARRAY tabLen OF Line;           (* array for the League Table *)
		userName: Name;
		f: Files.File;
		r: Files.Rider;
		
		
  (* Utilities *)

  PROCEDURE HALT; 
  BEGIN ASSERT(FALSE)                    (* exit the program *)
  END HALT;
  
  PROCEDURE CAP (ch: CHAR): CHAR;
  (* Capitalizes ASCII lower-case letters while leaving 
     capital letters and all other characters unchanged *)
    VAR res: CHAR;
  BEGIN
    IF (60X < ch) & (ch < 7BX) THEN
      res := CHR(ORD(ch) - (ORD("a") - ORD("A")))
    END
  RETURN res
  END CAP;
	  
	PROCEDURE WriteLn (s: ARRAY OF CHAR);
	BEGIN Out.String(s); Out.Ln
	END WriteLn;
	
	PROCEDURE WriteRealTo1Dec (x: REAL);
		VAR ix, d: INTEGER;
	BEGIN ASSERT(x >= 0.0);
		ix := FLOOR(x);                         (* integer part of x *)
		d := FLOOR(10.0*(x + 0.05 - FLT(ix)));  (* rounded first decimal of x *)
		IF ix < 10 THEN Out.Char(" ") END; 
		Out.Int(ix, 0); Out.Char("."); Out.Int(d, 0 )
	END WriteRealTo1Dec;	  


	(* Options *)  
	  
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
		WriteLn("To give up and reveal the code type ? and enter.");
		WriteLn("When a game is finished, another one begins immediately.");
		WriteLn("If you do not wish to continue playing, type q and enter");
		WriteLn("To join the League start the game with ./moo -n YourName");
		WriteLn("Your personal performance data will then be shown in the League Table.");
		Out.Ln;
		WriteLn("Have fun!");
		Out.Ln	
	END Instruct;
	
	PROCEDURE Usage;
	BEGIN
		WriteLn("Usage: moo [-? | -h] [-v] [-i | -vi] [-l | -L | -vl | -vL] [-n Name]");
		WriteLn("  -? | -h  display this message.");
		WriteLn("  -v       verbose output.");
		WriteLn("  -i       display game instructions.");
		WriteLn("  -l | -L  display the League Table.");
		WriteLn("  -n Name  enter your Name for the League Table.");
	END Usage;
	
	PROCEDURE ShowLeagueTable;
		VAR i, j, m: INTEGER;
	BEGIN
		f := Files.Old(fileName);
		IF f # NIL THEN  (* League Table file exists *)
			IF verbose THEN
				WriteLn("                             `´        ");                                                                 
				WriteLn("L e a g u e  T a b l e  for  M  O  O --");
				WriteLn("                             /\  /´`\  ");
			END;
			WriteLn("Name     wAvg  Avg mov gam  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16+");
			WriteLn("---------------------------------------------------------------------------");
			Files.Set(r, f, 0);
			Files.ReadInt(r, m);	
			IF m = fileMark THEN
				Files.ReadInt(r, N); 
				i := 0; 
				WHILE i < N DO
					Files.ReadString(r, tab[i].name);
		(*		IF tab[i].name # "" THEN *)
						Out.String(tab[i].name); 
						FOR j := 1 TO nameLen - 1 - Strings.Length(tab[i].name) DO Out.Char(" ") END;
						Files.ReadReal(r, tab[i].wAverage); WriteRealTo1Dec(tab[i].wAverage); Out.Char(" ");
						Files.ReadReal(r, tab[i].average);  WriteRealTo1Dec(tab[i].average);
						Files.ReadInt (r, tab[i].movesToDate); Out.Int(tab[i].movesToDate, 4);
						Files.ReadInt (r, tab[i].gamesToDate); Out.Int(tab[i].gamesToDate, 4);
						FOR j := 0 TO movesLen - 1 DO Files.ReadInt(r, tab[i].moves[j]) END;
						FOR j := 1 TO movesLen - 1 DO          Out.Int(tab[i].moves[j], 3) END;
						Out.Ln;
		(*		END;                     *)
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
		VAR i, (* j, *) k, res: INTEGER;
			arg: ARRAY nameLen OF CHAR;
	BEGIN
		FOR i := 0 TO Args.count - 1 DO
			Args.Get(i, arg, res);
			IF arg[0] = "-" THEN
				IF (arg = "-n") OR (arg = "-d") THEN
					IF arg[1] = "d" THEN delete := TRUE END;
					IF i < Args.count - 1 THEN INC(i); Args.Get(i, arg, res) END;
					userName := "";  Strings.Insert(arg, 0, userName)
				ELSE (* arg # -n & arg # -d *)
					k := 1;
					WHILE arg[k] # 0X DO
						IF     arg[k] = "v" THEN verbose := TRUE
						ELSIF  arg[k] = "i" THEN Instruct
						ELSIF (arg[k] = "?") OR (arg[k] = "h") THEN Usage; HALT
						ELSIF (arg[k] = "l") OR (arg[k] = "L") THEN ShowLeagueTable; HALT
						ELSE WriteLn("illegal option -- "); Out.Char(arg[k]); Out.Ln; Usage; HALT
						END;
						INC(k)
					END (* WHILE *)
				END (* IF arg = "-n" *)
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
			n := Random.Int(9);     (* generate a random integer in the range 0..9 *)
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
		VAR continue: BOOLEAN;  askGuess: BOOLEAN;  i, t: INTEGER;
		
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
			t := Input.Time();  (* to prevent infinite loop on ^D *)
			WriteLn("? ");  In.Line(guess);  
			IF (Strings.Length(guess) = 4) & AllDigits(guess) THEN 
				askGuess := FALSE
			ELSIF ((CAP(guess[0]) = "Q") & (guess[1] = 0X)) OR (Input.Time() - t < 100) THEN
				askGuess := FALSE;  continue := FALSE
			ELSIF (guess[0] = "?") & (guess[1] = 0X) THEN
				Out.String("The code was ");
				FOR i := 0 TO SIZE - 1 DO Out.Char(code[i]) END; Out.Ln;
				askGuess := FALSE;  continue := FALSE
			ELSE
				WriteLn("bad guess")
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
		tab[n].movesToDate := 0;
		tab[n].gamesToDate := 0;
		FOR i := 0 TO movesLen - 1 DO tab[n].moves[i] := 0 END;
		tab[n].wAverage := 100.0;
		tab[n].average := 100.0
	END InitTabLine;			
	

	PROCEDURE SaveTable (register: BOOLEAN);
	(* Save the League Table from main store into a file; if needed, register the file.
		 Only newly created files need registration in the directory. *)
		VAR i, j: INTEGER;
	BEGIN
		Files.Set(r, f, 0);
		Files.WriteInt(r, fileMark);  (* write a magic number used as a file type signature *)
		Files.WriteInt(r, N);         (* number of players in the League Table *)
		FOR i := 0 TO tabLen - 1 DO
			Files.WriteString(r, tab[i].name);
			Files.WriteReal  (r, tab[i].wAverage);
			Files.WriteReal  (r, tab[i].average);
			Files.WriteInt   (r, tab[i].movesToDate);
			Files.WriteInt   (r, tab[i].gamesToDate);
			FOR j := 0 TO movesLen - 1 DO Files.WriteInt(r, tab[i].moves[j]) END;
		END;
		IF register THEN
			Files.Register(f);  
			Files.Close(f);     (* should not be necessary *)
			Out.String("New file registered."); Out.Ln 
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
			N := 0;
			FOR i := 0 TO tabLen - 1 DO InitTabLine(i) END
		END ClearTable;			

	BEGIN
		f := Files.Old(fileName);
		IF f = NIL THEN
			Out.String("New file for League Table created."); Out.Ln;
			f := Files.New(fileName);
			ClearTable;
			SaveTable(TRUE)  (* save and register a new empty file *)
		ELSE
			Files.Set(r, f, 0);
			Files.ReadInt(r, m);
			IF m = fileMark THEN
				Files.ReadInt(r, N);
				FOR i := 0 TO tabLen - 1 DO
					Files.ReadString(r, tab[i].name);
					Files.ReadReal  (r, tab[i].wAverage);
					Files.ReadReal  (r, tab[i].average);
					Files.ReadInt   (r, tab[i].movesToDate);
					Files.ReadInt   (r, tab[i].gamesToDate);
					FOR j := 0 TO movesLen - 1 DO Files.ReadInt(r, tab[i].moves[j]) END;
				END;
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
			DEC(N);
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
				END
			END UpdateLine;
			
		BEGIN
			(* Search userName *)
  		i := 0;  WHILE (i < tabLen) & (tab[i].name # userName) DO INC(i) END;
			IF (i # tabLen) & (tab[i].name = userName) THEN  (* name found *)
			  UpdateLine(i)
			ELSE                                             (* name not found *)
				IF N < tabLen THEN  (* enough room in the table array *)
				(* Add current player in line N *)
					tab[N].name := userName;  UpdateLine(N);  
					INC(N)             
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
		Out.Int(nBulls, 4 - SIZE);
		IF nBulls = 1 THEN Out.String(" bull,  ") ELSE Out.String(" bulls, ") END;
		Out.Int(nCows, 0);
		IF nCows = 1 THEN Out.String(" cow") ELSE Out.String(" cows") END; Out.Ln 
	END PrintOut;

  
	PROCEDURE Main;
		VAR continue: BOOLEAN;
	BEGIN
		N := 0;
		userName := "";  verbose := FALSE;  delete := FALSE;
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
					Out.String("new game for "); Out.String(userName) 
				END; Out.Ln;
				nBulls := 0;  nCows := 0;  nGuesses := 0;
				NumGen;
				WHILE nBulls < 4 DO
					nBulls := 0;  nCows := 0;
					continue := TakeGuess();
					IF continue THEN
						INC(nGuesses);
						Match;
						PrintOut
					ELSE
						ShowLeagueTable; 
						HALT
					END
				END;
				IF verbose THEN
					WriteLn("`´        ");                                                                 
					WriteLn("M  O  O --");
					WriteLn("/\  /´`\  ")
				END;
				Out.Int(nGuesses, 0); 
				IF nGuesses = 1 THEN WriteLn(" guess") ELSE WriteLn(" guesses") END; Out.Ln;
				IF userName # "" THEN UpdateLeagueTable END
			UNTIL FALSE
		END
	END Main;
	
BEGIN
	Main
END moo.

   
