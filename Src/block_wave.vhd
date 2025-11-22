entity block_wave is
  port (
    clk, reset_n  : in  std_logic;
    enable_i      : in  std_logic;
    data_i        : in  std_logic_vector(15 downto 0); -- optional amplitude
    valid_i       : in  std_logic;
    ready_o       : out std_logic;
    data_o        : out std_logic_vector(15 downto 0);
    valid_o       : out std_logic;
    ready_i       : in  std_logic
  );
end;

architecture rtl of block_wave is
  signal phase : unsigned(15 downto 0) := (others => '0');
  signal wave  : signed(15 downto 0);
  function sin_lut(p : unsigned(15 downto 0)) return signed is
  begin
    return signed(std_logic_vector(p)); -- replace with proper LUT
  end function;
begin
  ready_o <= ready_i;

  process(clk, reset_n)
  begin
    if reset_n = '0' then
      phase   <= (others => '0');
      data_o  <= (others => '0');
      valid_o <= '0';
    elsif rising_edge(clk) then
      if enable_i = '1' and ready_i = '1' then
        phase  <= phase + 1; -- set step size via command if needed
        wave   <= sin_lut(phase);
        data_o <= std_logic_vector(wave);
        valid_o <= '1';
      else
        valid_o <= '0';
      end if;
    end if;
  end process;
end architecture;
