-- Full Adder Component
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    Port ( a : in STD_LOGIC;
           b : in STD_LOGIC;
           cin : in STD_LOGIC;
           sum : out STD_LOGIC;
           cout : out STD_LOGIC);
end full_adder;

architecture dataflow of full_adder is
    signal a_xor_b: std_logic;
begin
    a_xor_b <= a xor b;
    sum <= a xor b xor cin;
    cout <= (a_xor_b and cin) or (a and b);
end dataflow;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity carry_save_mult is
    Generic ( n : integer := 8 );
    Port ( a : in STD_LOGIC_VECTOR (n-1 downto 0);
           b : in STD_LOGIC_VECTOR (n-1 downto 0);
           p : out STD_LOGIC_VECTOR (2*n-1 downto 0));
end carry_save_mult;

architecture Behavioral of carry_save_mult is
    component full_adder is port (
        a : in STD_LOGIC;
        b : in STD_LOGIC;
        cin : in STD_LOGIC;
        sum : out STD_LOGIC;
        cout : out STD_LOGIC);
    end component;
    
    -- Create type for an array N bit by N bit signal 
    type ab_array_type is array (n-1 downto 0) of STD_LOGIC_VECTOR(n-1 downto 0);
    signal ab : ab_array_type;
    
    -- Create type for FA array N-1 bit by N bit signal 
    type fa_array_type is array (n-2 downto 0) of STD_LOGIC_VECTOR(n-1 downto 0);
    signal FA_a, FA_b, FA_cin, FA_sum, FA_cout : fa_array_type;
    
begin
    -- Generate ab array (bit-by-bit products)
    ab_gen: for i in 0 to n-1 generate
        ab_bit_gen: for j in 0 to n-1 generate
            ab(i)(j) <= a(i) and b(j);
        end generate;
    end generate;
    
    -- Generate full adders for each row
    row_gen: for i in 0 to n-2 generate
        col_gen: for j in 0 to n-1 generate
            fa_inst: full_adder port map (
                a => FA_a(i)(j),
                b => FA_b(i)(j),
                cin => FA_cin(i)(j),
                sum => FA_sum(i)(j),
                cout => FA_cout(i)(j)
            );
        end generate;
    end generate;
    
    -- Assign inputs for first row (row 0)
    FA_a(0) <= '0' & ab(0)(n-1 downto 1);
    FA_b(0) <= ab(1)(n-1 downto 0);
    FA_cin(0) <= ab(2)(n-2 downto 0) & '0';
    
    -- Assign inputs for intermediate rows (rows 1 to n-3)
    intermediate_rows: for i in 1 to n-3 generate
        FA_a(i) <= ab(i+1)(n-1) & FA_sum(i-1)(n-1 downto 1);
        FA_b(i) <= FA_cout(i-1)(n-1 downto 0);
        FA_cin(i) <= ab(i+2)(n-2 downto 0) & '0';
    end generate;
    
    -- Assign inputs for last row (row n-2)
    FA_a(n-2) <= ab(n-1)(n-1) & FA_sum(n-3)(n-1 downto 1);
    FA_b(n-2) <= FA_cout(n-3)(n-1 downto 0);
    FA_cin(n-2) <= FA_cout(n-2)(n-2 downto 0) & '0';
    
    -- Final product assignment
    -- Bit 0
    p(0) <= ab(0)(0);
    
    -- Bits 1 to n-2 (sum from first FA in each row except last)
    p_middle: for i in 1 to n-2 generate
        p(i) <= FA_sum(i-1)(0);
    end generate;
    
    -- Bits n-1 to 2n-2 (sum from last row)
    p_upper: for i in n-1 to 2*n-2 generate
        p(i) <= FA_sum(n-2)(i-(n-1));
    end generate;
    
    -- Bit 2n-1 (carry out from last FA in last row)
    p(2*n-1) <= FA_cout(n-2)(n-1);

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mult is 
    port(
        clk: in std_logic;
        a: in std_logic_vector(7 downto 0);
        b: in std_logic_vector(7 downto 0);
        p: out std_logic_vector(15 downto 0)
    );
end mult;

architecture Behavioral of mult is
    component carry_save_mult is
        Generic ( n : integer := 8 );
        Port ( a : in STD_LOGIC_VECTOR (7 downto 0);
               b : in STD_LOGIC_VECTOR (7 downto 0);
               p : out STD_LOGIC_VECTOR (15 downto 0)
            );
    end component;
    
    signal a_reg : STD_LOGIC_VECTOR (7 downto 0);
    signal b_reg : STD_LOGIC_VECTOR (7 downto 0);
    signal p_internal : STD_LOGIC_VECTOR (15 downto 0);
    
begin
    process (clk) 
    begin
        if (rising_edge(clk)) then
            a_reg <= a;
            b_reg <= b;
            p <= p_internal;
        end if;
    end process;
    
    csm: carry_save_mult 
        generic map (n => 8)
        port map (
            a => a_reg,
            b => b_reg,
            p => p_internal
        );
end Behavioral;