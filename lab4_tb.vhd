library IEEE;
library std;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_textio.all;
use STD.TEXTIO.ALL;

entity mult_tb is
end mult_tb;

architecture Behavioral of mult_tb is
    constant PERIOD: time := 10 ns;
    file input_file : text open read_mode is "mult8x8.dat";
    
    -- Component declaration for mult (must match exactly)
    component mult
        port(
            clk: in std_logic;
            a: in std_logic_vector(7 downto 0);
            b: in std_logic_vector(7 downto 0);
            p: out std_logic_vector(15 downto 0)
        );
    end component;
    
    -- Signal declarations
    signal clk : std_logic := '0';
    signal a : std_logic_vector(7 downto 0) := (others => '0');
    signal b : std_logic_vector(7 downto 0) := (others => '0');
    signal p : std_logic_vector(15 downto 0);
    
begin 
    -- Entity instantiation for mult 
    uut: mult port map (
        clk => clk,
        a => a,
        b => b,
        p => p
    );
    
    -- Generate the clock signal 
    clk_process: process
    begin
        clk <= '0';
        wait for PERIOD/2;
        clk <= '1';
        wait for PERIOD/2;
    end process;
    
    -- Test bench process
    tb: process is 
        variable input_line: line;
        variable a_var: std_logic_vector(7 downto 0);
        variable b_var: std_logic_vector(7 downto 0);
        variable p_var: std_logic_vector(15 downto 0);
        variable test_count: integer := 0;
        variable error_count: integer := 0;
        variable space_char: character;
        
        -- Helper function to convert std_logic_vector to string
        function to_hex_string(slv : std_logic_vector) return string is
            variable result : string(1 to slv'length/4);
            variable temp : std_logic_vector(3 downto 0);
            variable char_val : character;
        begin
            for i in 0 to slv'length/4-1 loop
                temp := slv(slv'length-1-i*4 downto slv'length-4-i*4);
                case temp is
                    when "0000" => char_val := '0';
                    when "0001" => char_val := '1';
                    when "0010" => char_val := '2';
                    when "0011" => char_val := '3';
                    when "0100" => char_val := '4';
                    when "0101" => char_val := '5';
                    when "0110" => char_val := '6';
                    when "0111" => char_val := '7';
                    when "1000" => char_val := '8';
                    when "1001" => char_val := '9';
                    when "1010" => char_val := 'A';
                    when "1011" => char_val := 'B';
                    when "1100" => char_val := 'C';
                    when "1101" => char_val := 'D';
                    when "1110" => char_val := 'E';
                    when "1111" => char_val := 'F';
                    when others => char_val := 'X';
                end case;
                result(i+1) := char_val;
            end loop;
            return result;
        end function;
        
    begin 
        report "Starting testbench...";
        
        -- Wait for a few clock cycles before starting
        wait for 3 * PERIOD;
        wait until rising_edge(clk);
        
        report "Beginning test vector processing...";
        
        while not endfile(input_file) loop 
            readline(input_file, input_line);
            
            -- Skip empty lines
            if input_line'length = 0 then
                next;
            end if;
            
            -- Read first hex value (a)
            hread(input_line, a_var);
            read(input_line, space_char); -- read space
            
            -- Read second hex value (b)  
            hread(input_line, b_var);
            read(input_line, space_char); -- read space
            
            -- Read third hex value (expected result)
            hread(input_line, p_var);
            
            -- Apply inputs on rising edge
            wait until rising_edge(clk);
            a <= a_var;
            b <= b_var;
            
            -- Wait for two clock periods (pipeline delay)
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            
            -- Check the result after settling
            wait for 1 ns;
            
            if p /= p_var then
                error_count := error_count + 1;
                report "Test " & integer'image(test_count + 1) & " FAILED: a=" & to_hex_string(a_var) & 
                       ", b=" & to_hex_string(b_var) & 
                       ", expected=" & to_hex_string(p_var) & 
                       ", got=" & to_hex_string(p)
                       severity error;
            end if;
            
            test_count := test_count + 1;
            
            -- Print progress every 10000 tests (reduce console output)
            if test_count mod 10000 = 0 then
                report "Completed " & integer'image(test_count) & " tests...";
            end if;
            
        end loop;
        
        file_close(input_file);
        
        -- Report completion
        if error_count = 0 then
            report "*** SIMULATION COMPLETED SUCCESSFULLY ***";
            report "*** ALL " & integer'image(test_count) & " TESTS PASSED ***";
        else
            report "*** SIMULATION COMPLETED WITH ERRORS ***";
            report "*** " & integer'image(error_count) & " ERRORS OUT OF " & integer'image(test_count) & " TESTS ***";
        end if;
        
        report "Testbench finished.";
        wait;
    end process;
end Behavioral;