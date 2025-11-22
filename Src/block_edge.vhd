entity block_edge is
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

architecture rtl of block_edge is
  signal prev : signed(15 downto 0) := (others => '0');
  signal diff : signed(16 downto 0);
begin
  ready_o <= ready_i;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      prev    <= (others => '0');
      data_o  <= (others => '0');
      valid_o <= '0';
    elsif rising_edge(clk) then
      if valid_i = '1' and enable_i = '1' and ready_i = '1' then
        diff   <= resize(signed(data_i),17) - resize(prev,17);
        prev   <= signed(data_i);
        data_o <= std_logic_vector(diff(16 downto 1)); -- simple scaling
        valid_o <= '1';
      else
        valid_o <= '0';
      end if;
    end if;
  end process;
end architecture;
