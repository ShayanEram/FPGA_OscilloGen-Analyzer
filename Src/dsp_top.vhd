library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dsp_top is
  port (
    clk            : in  std_logic;
    reset_n        : in  std_logic;

    -- UART physical pins
    uart_rx_i      : in  std_logic;
    uart_tx_o      : out std_logic
  );
end entity;

architecture rtl of dsp_top is

  -- UART stream (bytes)
  signal rx_data       : std_logic_vector(7 downto 0);
  signal rx_valid      : std_logic;
  signal rx_ready      : std_logic;

  signal tx_data       : std_logic_vector(7 downto 0);
  signal tx_valid      : std_logic;
  signal tx_ready      : std_logic;

  -- Command decoder
  type command_t is (CMD_NONE, CMD_FFT, CMD_FILTER, CMD_EDGE, CMD_MOD, CMD_WAVE);
  signal current_cmd   : command_t := CMD_NONE;
  signal cmd_valid     : std_logic;

  -- Raw sample stream into processing (e.g., 16-bit signed)
  signal in_s_data     : std_logic_vector(15 downto 0);
  signal in_s_valid    : std_logic;
  signal in_s_ready    : std_logic;

  -- Processed stream out
  signal out_s_data    : std_logic_vector(15 downto 0);
  signal out_s_valid   : std_logic;
  signal out_s_ready   : std_logic;

  -- Block I/O
  signal fft_out_data, filt_out_data, edge_out_data, mod_out_data, wave_out_data
    : std_logic_vector(15 downto 0);
  signal fft_out_valid, filt_out_valid, edge_out_valid, mod_out_valid, wave_out_valid
    : std_logic;
  signal fft_out_ready, filt_out_ready, edge_out_ready, mod_out_ready, wave_out_ready
    : std_logic;

  -- Enables
  signal en_fft, en_filt, en_edge, en_mod, en_wave : std_logic;

begin
  ---------------------------------------------------------------------------
  -- UART: convert serial to byte stream and back
  ---------------------------------------------------------------------------
  u_uart_rx: entity work.uart_rx
    port map (
      clk       => clk,
      reset_n   => reset_n,
      rx_i      => uart_rx_i,
      data_o    => rx_data,
      valid_o   => rx_valid,
      ready_i   => rx_ready
    );

  u_uart_tx: entity work.uart_tx
    port map (
      clk       => clk,
      reset_n   => reset_n,
      tx_o      => uart_tx_o,
      data_i    => tx_data,
      valid_i   => tx_valid,
      ready_o   => tx_ready
    );

  ---------------------------------------------------------------------------
  -- Protocol splitter: first byte is command, following bytes are payload
  ---------------------------------------------------------------------------
  u_cmd_splitter: entity work.command_splitter
    port map (
      clk         => clk,
      reset_n     => reset_n,
      rx_data_i   => rx_data,
      rx_valid_i  => rx_valid,
      rx_ready_o  => rx_ready,

      cmd_o       => current_cmd,
      cmd_valid_o => cmd_valid,

      sample_o    => in_s_data,
      sample_valid_o => in_s_valid,
      sample_ready_i => in_s_ready
    );

  ---------------------------------------------------------------------------
  -- Command decoder: enables selected block
  ---------------------------------------------------------------------------
  en_fft  <= '1' when current_cmd = CMD_FFT   else '0';
  en_filt <= '1' when current_cmd = CMD_FILTER else '0';
  en_edge <= '1' when current_cmd = CMD_EDGE   else '0';
  en_mod  <= '1' when current_cmd = CMD_MOD    else '0';
  en_wave <= '1' when current_cmd = CMD_WAVE   else '0';

  ---------------------------------------------------------------------------
  -- DSP blocks (stubs below)
  ---------------------------------------------------------------------------
  u_fft: entity work.block_fft
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable_i    => en_fft,
      data_i      => in_s_data,
      valid_i     => in_s_valid,
      ready_o     => in_s_ready,
      data_o      => fft_out_data,
      valid_o     => fft_out_valid,
      ready_i     => fft_out_ready
    );

  u_filter: entity work.block_filter
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable_i    => en_filt,
      data_i      => in_s_data,
      valid_i     => in_s_valid,
      ready_o     => open, -- shared in_s_ready through mux
      data_o      => filt_out_data,
      valid_o     => filt_out_valid,
      ready_i     => filt_out_ready
    );

  u_edge: entity work.block_edge
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable_i    => en_edge,
      data_i      => in_s_data,
      valid_i     => in_s_valid,
      ready_o     => open,
      data_o      => edge_out_data,
      valid_o     => edge_out_valid,
      ready_i     => edge_out_ready
    );

  u_mod: entity work.block_mod
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable_i    => en_mod,
      data_i      => in_s_data,
      valid_i     => in_s_valid,
      ready_o     => open,
      data_o      => mod_out_data,
      valid_o     => mod_out_valid,
      ready_i     => mod_out_ready
    );

  u_wave: entity work.block_wave
    port map (
      clk         => clk,
      reset_n     => reset_n,
      enable_i    => en_wave,
      data_i      => in_s_data,
      valid_i     => in_s_valid,
      ready_o     => open,
      data_o      => wave_out_data,
      valid_o     => wave_out_valid,
      ready_i     => wave_out_ready
    );

  ---------------------------------------------------------------------------
  -- Output mux: select processed stream based on command
  ---------------------------------------------------------------------------
  out_s_data  <= fft_out_data  when en_fft  = '1' else
                 filt_out_data when en_filt = '1' else
                 edge_out_data when en_edge = '1' else
                 mod_out_data  when en_mod  = '1' else
                 wave_out_data when en_wave = '1' else
                 (others => '0');

  out_s_valid <= fft_out_valid  when en_fft  = '1' else
                 filt_out_valid when en_filt = '1' else
                 edge_out_valid when en_edge = '1' else
                 mod_out_valid  when en_mod  = '1' else
                 wave_out_valid when en_wave = '1' else
                 '0';

  -- Backpressure goes to selected block
  fft_out_ready  <= out_s_ready when en_fft  = '1' else '0';
  filt_out_ready <= out_s_ready when en_filt = '1' else '0';
  edge_out_ready <= out_s_ready when en_edge = '1' else '0';
  mod_out_ready  <= out_s_ready when en_mod  = '1' else '0';
  wave_out_ready <= out_s_ready when en_wave = '1' else '0';

  ---------------------------------------------------------------------------
  -- Pack processed 16-bit samples back into UART bytes
  ---------------------------------------------------------------------------
  u_stream_to_uart: entity work.stream_to_uart
    port map (
      clk          => clk,
      reset_n      => reset_n,
      data_i       => out_s_data,
      valid_i      => out_s_valid,
      ready_o      => out_s_ready,
      tx_data_o    => tx_data,
      tx_valid_o   => tx_valid,
      tx_ready_i   => tx_ready
    );

end architecture;
