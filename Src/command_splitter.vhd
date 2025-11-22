library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity command_splitter is
  port (
    clk, reset_n    : in  std_logic;
    rx_data_i       : in  std_logic_vector(7 downto 0);
    rx_valid_i      : in  std_logic;
    rx_ready_o      : out std_logic;

    cmd_o           : out command_t;
    cmd_valid_o     : out std_logic;

    sample_o        : out std_logic_vector(15 downto 0);
    sample_valid_o  : out std_logic;
    sample_ready_i  : in  std_logic
  );
end entity;

architecture rtl of command_splitter is
  type state_t is (S_CMD, S_LEN_H, S_LEN_L, S_PAYLOAD_H, S_PAYLOAD_L);
  signal st          : state_t := S_CMD;
  signal cmd_reg     : command_t := CMD_NONE;
  signal len_rem     : unsigned(15 downto 0) := (others => '0');
  signal hi_byte     : std_logic_vector(7 downto 0);
begin
  rx_ready_o     <= '1'; -- simple always-ready for UART input
  cmd_o          <= cmd_reg;
  cmd_valid_o    <= '1' when st = S_LEN_H else '0'; -- pulse after command decoded

  sample_o       <= hi_byte & rx_data_i;
  sample_valid_o <= '1' when (st = S_PAYLOAD_L and rx_valid_i = '1') else '0';

  process(clk, reset_n)
    variable cmd_byte : std_logic_vector(7 downto 0);
  begin
    if reset_n = '0' then
      st      <= S_CMD;
      cmd_reg <= CMD_NONE;
      len_rem <= (others => '0');
      hi_byte <= (others => '0');
    elsif rising_edge(clk) then
      if rx_valid_i = '1' then
        case st is
          when S_CMD =>
            cmd_byte := rx_data_i;
            case cmd_byte is
              when x"01" => cmd_reg <= CMD_FFT;
              when x"02" => cmd_reg <= CMD_FILTER;
              when x"03" => cmd_reg <= CMD_EDGE;
              when x"04" => cmd_reg <= CMD_MOD;
              when x"05" => cmd_reg <= CMD_WAVE;
              when others => cmd_reg <= CMD_NONE;
            end case;
            st <= S_LEN_H;

          when S_LEN_H =>
            len_rem(15 downto 8) <= unsigned(rx_data_i);
            st <= S_LEN_L;

          when S_LEN_L =>
            len_rem(7 downto 0) <= unsigned(rx_data_i);
            st <= S_PAYLOAD_H;

          when S_PAYLOAD_H =>
            hi_byte <= rx_data_i;
            st <= S_PAYLOAD_L;

          when S_PAYLOAD_L =>
            if len_rem = 0 then
              st <= S_CMD;
            else
              len_rem <= len_rem - 1;
              st <= S_PAYLOAD_H;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
