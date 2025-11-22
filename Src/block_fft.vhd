library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity block_fft is
  port (
    clk, reset_n  : in  std_logic;
    enable_i      : in  std_logic;
    data_i        : in  std_logic_vector(15 downto 0);
    valid_i       : in  std_logic;
    ready_o       : out std_logic;
    data_o        : out std_logic_vector(15 downto 0);
    valid_o       : out std_logic;
    ready_i       : in  std_logic
  );
end;

architecture rtl of block_fft is
begin
  -- Replace with vendor FFT core; this is a passthrough placeholder
  ready_o <= ready_i;
  data_o  <= data_i;
  valid_o <= valid_i and enable_i;
end architecture;
