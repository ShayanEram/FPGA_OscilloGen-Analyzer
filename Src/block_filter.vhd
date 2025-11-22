entity block_filter is
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

architecture rtl of block_filter is
  -- Example: 3-tap moving average (very simple)
  signal d0, d1, d2 : signed(15 downto 0) := (others => '0');
  signal sum        : signed(17 downto 0);
begin
  ready_o <= ready_i;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      d0 <= (others => '0');
      d1 <= (others => '0');
      d2 <= (others => '0');
      data_o <= (others => '0');
      valid_o <= '0';
    elsif rising_edge(clk) then
      if valid_i = '1' and enable_i = '1' and ready_i = '1' then
        d2 <= d1;
        d1 <= d0;
        d0 <= signed(data_i);
        sum <= resize(d0,18) + resize(d1,18) + resize(d2,18);
        data_o <= std_logic_vector(resize(sum / 3, 16));
        valid_o <= '1';
      else
        valid_o <= '0';
      end if;
    end if;
  end process;
end architecture;
