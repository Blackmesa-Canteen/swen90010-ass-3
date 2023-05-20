package body MyCalculator with SPARK_Mode is

    -- Init the calc
    procedure Init(C : out MyCalculator; VarDb : in VariableStore.Database ;MasterPINString : in String) is
    begin
        -- init master pin
        C.MasterPIN := PIN.From_String(MasterPINString);
      
        -- point to stack bottom
        C.size := 0;
        -- init stack array
        C.storage := (others => 0);
        
        -- init variable storage
        c.VariableDB := VarDb;

        -- default is locked
        C.isLocked := True;

    end Init;

    -- try unlock. 
    procedure Unlock(C : in out MyCalculator; PINString : in String)is
    begin
        -- if locked, compare password and try to unlock
        if (PIN."="(PIN.From_String(PINString), C.MasterPIN)) then
            C.isLocked := False;
        else
            -- wrong password
            Put_Line("Password is wrong.");
        end if;

    end Unlock;

    -- try lock
    procedure Lock(C : in out MyCalculator; PINString : in String) is
    begin
        -- set a new master pin, and then lock the calculator
        C.MasterPIN := PIN.From_String(PINString);
        C.isLocked := True;
    end Lock;

    -- Get whether is locked or not
    function IsLocked(C : in MyCalculator) return Boolean is
    begin
        return C.isLocked;
    end IsLocked;

    -- Push a number in
    procedure PushNumber(C : in out MyCalculator; NumIn : in Item) is
    begin
        C.size := C.size + 1;
        C.storage(C.size) := NumIn;
    end PushNumber;

    -- pop a number out
    procedure PopNumber(C : in out MyCalculator; NumOut : out Item) is
    begin
        NumOut := C.storage(C.size);
        C.size := C.size - 1;
    end PopNumber;

    -- The commands “+”, “-”, “*” and “/” each pop the top two values 
    -- from the operand stack and compute the corresponding arithmetic 
    -- operation on them (addition, subtraction, multiplication and division, respectively), 
    -- and push the result onto the stack.
    procedure PerformOperation(C : in out MyCalculator; 
                               Operator : in String; 
                               NumOut : out Item) is
    begin
        -- pop the top two values from the operand stack
            declare 
                Num1 : Item;
                Num2 : Item;
                Max_Integer : constant Integer := Integer'Last;
                Min_Integer : constant Integer := Integer'First;
                Temp_R : Long_Long_Integer;
            begin                
                -- pop out the number
                pragma Assert (not IsLocked(C));
                PopNumber(C, Num1);
                pragma Assert (not IsLocked(C));
                PopNumber(C, Num2);

                 -- compute the corresponding arithmetic operation on them
                if Operator = "+" then
                     -- check addition overflow
                        Temp_R := Long_Long_Integer(Num1) + Long_Long_Integer(Num2);
                        if (Temp_R > Long_Long_Integer(Max_Integer) or 
                            Temp_R < Long_Long_Integer(Min_Integer)) then
                            -- rollback the stack, show error info
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num2);
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num1);
                            NumOut := 0;
                            Put_Line("Addition overflow.");
                            return;
                        end if;

                        -- check addition positive overflow
                        --  if (IsNum2Possitive and Num1 > Max_Integer - Num2) then
                        --      raise MyExceptions.Calc_Exception with "Addition overflow.";
                        --  end if;

                        -- check addition negative overflow
                        --  if (not IsNum2Possitive and Num1 < Min_Integer - Num2) then
                        --      raise MyExceptions.Calc_Exception with "Addition overflow.";
                        --  end if;

                        NumOut := Num1 + Num2;
                        pragma Assert (not IsLocked(C));
                        PushNumber(C, NumOut);
                elsif Operator = "-" then
                    -- check substraction overflow
                        Temp_R := Long_Long_Integer(Num1) - Long_Long_Integer(Num2);
                        if (Temp_R > Long_Long_Integer(Max_Integer) or 
                            Temp_R < Long_Long_Integer(Min_Integer)) then
                            -- rollback the stack, show error info
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num2);
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num1);
                            NumOut := 0;
                            Put_Line("Substraction overflow.");
                            return;
                        end if;

                        -- check subtraction positive overflow
                        --  if (not IsNum2Possitive and Num1 > Max_Integer + Num2) then
                        --      raise MyExceptions.Calc_Exception with "Subtraction overflow.";
                        --  end if;

                        -- check substraction negative overflow
                        --  if (IsNum2Possitive and Num1 < Min_Integer + Num2) then
                        --      raise MyExceptions.Calc_Exception with "Subtraction overflow.";
                        --  end if;

                        NumOut := Num1 - Num2;
                        pragma Assert (not IsLocked(C));
                        PushNumber(C, NumOut);
                elsif Operator = "*" then
                        -- check multiplication overflow
                        if (if Num1 > 0 and Num2 > 0 then Num1 >= (Min_Integer+1)/Num2 and Num1 <= Max_Integer/Num2
                                elsif Num1 >= 0 and Num2 < 0 then Num1 <= (Min_Integer+1)/Num2 and Num1 >= Max_Integer/Num2
                                elsif Num1 < 0 and Num2 >= 0 then Num2 <= (Min_Integer+1)/Num1 and Num2 >= Max_Integer/Num1
                                elsif Num1 < 0 and Num2 < 0 then Num1 <= (Min_Integer+1)/Num2 and Num1 >= Max_Integer/Num2
                                elsif Num1 = 0 or Num2 = 0 then True
                           ) then
                            NumOut := Num1 * Num2;
                            Temp_R := Long_Long_Integer(NumOut);
                            pragma Assert(Temp_R >= Long_Long_Integer(Min_Integer) and Temp_R <= Long_Long_Integer(Max_Integer));
                            -- push the result
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, NumOut);
                        else
                            -- rollback the stack, show error info
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num2);
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num1);
                            NumOut := 0;
                            Temp_R := Long_Long_Integer(NumOut);
                            pragma Assert(Temp_R = 0);
                            Put_Line("Multiplication overflow.");
                            return; 
                        end if;
                elsif Operator = "/" then
                    -- check divide 0
                        if (Num2 = 0) then
                            -- rollback the stack, show error info
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num2);
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num1);
                            NumOut := 0;
                            Put_Line("Divition 0.");
                            return;
                        end if;

                        -- check division overflow
                        Temp_R := Long_Long_Integer(Num1) / Long_Long_Integer(Num2);
                        if (Temp_R > Long_Long_Integer(Max_Integer) or 
                            Temp_R < Long_Long_Integer(Min_Integer)) then
                            -- rollback the stack, show error info
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num2);
                            pragma Assert (not IsLocked(C));
                            PushNumber(C, Num1);
                            NumOut := 0;
                            Put_Line("Divition overflow.");
                            return;
                        end if;

                        -- check division overflow
                        --  if (Num1 = Max_Integer and Num2 = -1) then
                        --      raise MyExceptions.Calc_Exception with "Division overflow.";
                        --  end if;
                        NumOut := Num1 / Num2;
                        pragma Assert (not IsLocked(C));
                        PushNumber(C, NumOut);
                else
                        -- rollback the stack, show error info
                        pragma Assert (not IsLocked(C));
                        PushNumber(C, Num2);
                        pragma Assert (not IsLocked(C));
                        PushNumber(C, Num1);
                        NumOut := 0;
                        Put_Line("Invalid operator.");
                end if;
            end;
    end PerformOperation;


    -- For a string var, the procedure loads the value stored 
    -- in variable var and pushes it onto the stack.
    procedure LoadVar(C : in out MyCalculator; VarString: in String; Var : out VariableStore.Variable) is
    begin
        declare
            Num : Item;
        begin
            Var := VariableStore.From_String(VarString);
            if VariableStore.Has_Variable(C.VariableDB, Var) then
                Num := VariableStore.Get(C.VariableDB, Var);
                PushNumber(C, Num);
            else
                Put_Line("Variable " & VarString & " is undefined in stack.");
            end if;
        end;
     
    end LoadVar;

    -- pops the value from the top of the stack and stores it 
    -- into variable var, defining that variable if it is not already defined.
    procedure StoreVar(C : in out MyCalculator; VarString: in String; Var : out VariableStore.Variable) is
    begin
        declare
            V : VariableStore.Variable;
            Num : Item;
        begin
            -- pop the value from the top of the stack
            PopNumber(C, Num);

            -- store the value into variable var
            V := VariableStore.From_String(VarString);
            Var := V;
            VariableStore.Put(C.VariableDB, V, Num);
        end;
    
    end StoreVar;

    -- makes variable var undefined (i.e. it will not be printed by subsequent “list” commands).
    procedure RemoveVar(C : in out MyCalculator; VarString: String; Var : out VariableStore.Variable) is 
    begin
        declare
            V : VariableStore.Variable;
        begin
            V := VariableStore.From_String(VarString);
            Var := V;
            -- remove the variable
            if VariableStore.Has_Variable(C.VariableDB, V) then
                VariableStore.Remove(C.VariableDB, V);
            end if;
        end;
    end RemoveVar;
end MyCalculator;
