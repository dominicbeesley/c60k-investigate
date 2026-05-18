library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity c60k_som_probe is
   port (

      sys_clk              : in            std_logic;

      C2339_4_C20          : out           std_logic;
      C2400_4_W21          : out           std_logic;
      BTB9900_4_V19        : out           std_logic;

      UART_TXD             : out           std_logic
);
end entity;

architecture rtl of c60k_som_probe is

constant    C_CLOCKSPEED   : natural := 50000000;
constant    C_BAUD         : natural := 19200;
constant    C_DIV          : natural := C_CLOCKSPEED / C_BAUD;
constant    S_LENGTH       : natural := 24;
constant    C_MAX_PHASE    : natural := 5;


signal      i_bauddiv_ctr  : integer range 0 to C_DIV-1 := 0;


signal      i_bit_clk      : std_logic := '1';

signal      r_phase        : integer range 0 to C_MAX_PHASE := 0;
signal      r_flip_all     : std_logic := '0';
signal      i_phase        : std_logic_vector(C_MAX_PHASE downto 0);

signal      i_mem_D_io_5   : std_logic;


-- reset process
signal      r_ctr_res     : unsigned(10 downto 0) := (others => '0');
signal      i_rst          : std_logic;

begin

   p_phase:process(r_phase)
   begin
      for i in C_MAX_PHASE downto 0 loop
         if r_phase = i then
            i_phase(i) <= '0';          -- not masked!
         else
            i_phase(i) <= '1';
         end if;
      end loop;

   end process;


   p_rst:process(sys_clk)
   begin
      if rising_edge(sys_clk) then
         if r_ctr_res(r_ctr_res'high) /= '1' then
            r_ctr_res <= r_ctr_res + 1;
         end if;
      end if;
   end process;

   i_rst <= not(std_logic(r_ctr_res(r_ctr_res'high)));

   p_bit_clk:process(sys_clk)
   begin
      if rising_edge(sys_clk) then
         i_bit_clk <= '0';
         if i_rst = '1' then
            i_bauddiv_ctr <= 0;
            i_bit_clk <= '1';
         elsif i_bauddiv_ctr >= C_DIV-1 then
            i_bauddiv_ctr <= 0;
            i_bit_clk <= '1';
         else
            i_bauddiv_ctr <= i_bauddiv_ctr + 1; 
         end if;
      end if;

   end process;

   p_rep:process(sys_clk)
   variable v_ctr : integer range 0 to (S_LENGTH + 1)*10 := 0;   
   begin
      if rising_edge(sys_clk) then
         if i_rst = '1' then
            v_ctr := 0;
            r_phase <= 0;
         elsif i_bit_clk = '1' then
            if v_ctr = ((S_LENGTH+1)*10)-1 then
               v_ctr := 0;
               if r_phase = C_MAX_PHASE then
                  r_phase <= 0;
                  r_flip_all <= not r_flip_all;
               else
                  r_phase <= r_phase + 1;
               end if;
            else
               v_ctr := v_ctr + 1;
            end if;
         end if;
      end if;

   end process;



   e_so_01_00:entity work.serialout generic map( G_LENGTH => 20,  G_MESSAGE =>"C2339_4_C20         ", G_MASK => 'Z', G_INIT => '1') port map ( rst => i_rst, mask => i_phase(0), bit_clk => i_bit_clk, so => C2339_4_C20 );
   e_so_01_01:entity work.serialout generic map( G_LENGTH => 20,  G_MESSAGE =>"C2400_4_W21         ", G_MASK => 'Z', G_INIT => '1') port map ( rst => i_rst, mask => i_phase(0), bit_clk => i_bit_clk, so => C2400_4_W21 );
   e_so_01_02:entity work.serialout generic map( G_LENGTH => 20,  G_MESSAGE =>"BTB9900_4_V19       ", G_MASK => 'Z', G_INIT => '1') port map ( rst => i_rst, mask => i_phase(0), bit_clk => i_bit_clk, so => BTB9900_4_V19 );

   e_so_01_03:entity work.serialout generic map( G_LENGTH => 20,  G_MESSAGE =>"UART TXD U15        ", G_MASK => 'Z', G_INIT => '1') port map ( rst => i_rst, mask => i_phase(0), bit_clk => i_bit_clk, so => UART_TXD );

   

end architecture rtl;
      
      
