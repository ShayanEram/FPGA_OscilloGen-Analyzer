entity block_mod is
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

architecture rtl of block_mod is
  -- Minimal DDS phase and cosine LUT (placeholder)
  signal phase : unsigned(15 downto 0) := (others => '0');
  signal carrier : signed(15 downto 0);
  signal prod    : signed(31 downto 0);
  function cos_lut(p : unsigned(15 downto 0)) return signed is
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
      if valid_i = '1' and enable_i = '1' and ready_i = '1' then
        phase   <= phase + 1; -- set step for desired frequency
        carrier <= cos_lut(phase);
        prod    <= resize(signed(data_i),32) * resize(carrier,32);
        data_o  <= std_logic_vector(prod(30 downto 15)); -- scale back to 16-bit
        valid_o <= '1';
      else
        valid_o <= '0';
      end if;
    end if;
  end process;
end architecture;
