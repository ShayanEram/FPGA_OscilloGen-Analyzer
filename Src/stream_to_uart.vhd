entity stream_to_uart is
  port (
    clk, reset_n  : in  std_logic;
    data_i        : in  std_logic_vector(15 downto 0);
    valid_i       : in  std_logic;
    ready_o       : out std_logic;
    tx_data_o     : out std_logic_vector(7 downto 0);
    tx_valid_o    : out std_logic;
    tx_ready_i    : in  std_logic
  );
end;

architecture rtl of stream_to_uart is
  type st_t is (S_IDLE, S_SEND_HI, S_SEND_LO);
  signal st : st_t := S_IDLE;
begin
  ready_o    <= '1' when st = S_IDLE else '0';
  tx_valid_o <= '1' when (st = S_SEND_HI or st = S_SEND_LO) else '0';

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      st        <= S_IDLE;
      tx_data_o <= (others => '0');
    elsif rising_edge(clk) then
      case st is
        when S_IDLE =>
          if valid_i = '1' then
            tx_data_o <= data_i(15 downto 8);
            st <= S_SEND_HI;
          end if;

        when S_SEND_HI =>
          if tx_ready_i = '1' then
            tx_data_o <= data_i(7 downto 0);
            st <= S_SEND_LO;
          end if;

        when S_SEND_LO =>
          if tx_ready_i = '1' then
            st <= S_IDLE;
          end if;
      end case;
    end if;
  end process;
end architecture;
