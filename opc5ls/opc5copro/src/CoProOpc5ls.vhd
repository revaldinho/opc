library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity CoProOpc5ls is
    port (
        -- GOP Signals
        fastclk   : in    std_logic;
        tp        : out   std_logic_vector(8 downto 2);
        test      : out   std_logic_vector(6 downto 1);
        sw        : in    std_logic_vector(2 downto 1);
        fcs       : out   std_logic;

        -- Tube signals (use 16 out of 22 DIL pins)
        h_phi2    : in    std_logic;  -- 1,2,12,21,23 are global clocks
        h_addr    : in    std_logic_vector(2 downto 0);
        h_data    : inout std_logic_vector(7 downto 0);
        h_rdnw    : in    std_logic;
        h_cs_b    : in    std_logic;
        h_rst_b   : in    std_logic;
        h_irq_b   : inout std_logic;


        -- Ram Signals
        ram_cs       : out   std_logic;
        ram_oe       : out   std_logic;
        ram_wr       : out   std_logic;
        ram_addr     : out   std_logic_vector (18 downto 0);
        ram_data     : inout std_logic_vector (7 downto 0)
    );
end CoProOpc5ls;

architecture BEHAVIORAL of CoProOpc5ls is

    component opc5lscpu
        port(
            din     : in    std_logic_vector(15 downto 0);
            dout    : out   std_logic_vector(15 downto 0);
            address : out   std_logic_vector(15 downto 0);
            rnw     : out   std_logic;
            clk     : in    std_logic;
            reset_b : in    std_logic;
            int_b   : in    std_logic   
        );
    end component;

    component ram
        port(
            din     : in    std_logic_vector(15 downto 0);
            dout    : out   std_logic_vector(15 downto 0);
            address : in    std_logic_vector(12 downto 0);
            rnw     : in    std_logic;
            clk     : in    std_logic;
            cs_b    : in    std_logic
        );
    end component;

    component tube
        port(
            h_addr     : in    std_logic_vector(2 downto 0);
            h_cs_b     : in    std_logic;
            h_data     : inout std_logic_vector(7 downto 0);
            h_phi2     : in    std_logic;
            h_rdnw     : in    std_logic;
            h_rst_b    : in    std_logic;
            h_irq_b    : inout std_logic;
         -- drq        : out   std_logic;
         -- dackb      : in    std_logic;
            p_addr     : in    std_logic_vector(2 downto 0);
            p_cs_b     : in    std_logic;
            p_data_in  : in    std_logic_vector(7 downto 0);
            p_data_out : out   std_logic_vector(7 downto 0);
            p_rdnw     : in    std_logic;
            p_phi2     : in    std_logic;
            p_rst_b    : out   std_logic;
            p_nmi_b    : inout std_logic;
            p_irq_b    : inout std_logic
          );
    end component;

-------------------------------------------------
-- clock and reset signals
-------------------------------------------------

    signal clk_16M00     : std_logic;
--    signal phi0          : std_logic;
--    signal phi1          : std_logic;
--    signal phi2          : std_logic;
--    signal phi3          : std_logic;
    signal cpu_clken     : std_logic;
--    signal clken_counter : std_logic_vector (1 downto 0);
    signal RSTn          : std_logic;
    signal RSTn_sync     : std_logic;

-------------------------------------------------
-- parasite signals
-------------------------------------------------

    signal p_cs_b_en     : std_logic;
    signal p_cs_b        : std_logic;
    signal p_data_out    : std_logic_vector (7 downto 0);
    
-------------------------------------------------
-- internal memory signals
-------------------------------------------------

    signal mem_cs_b        : std_logic;
    signal mem_data_out    : std_logic_vector (15 downto 0);
-------------------------------------------------
-- cpu signals
-------------------------------------------------

    signal cpu_R_W_n  : std_logic;
    signal cpu_addr   : std_logic_vector (15 downto 0);
    signal cpu_din    : std_logic_vector (15 downto 0);
    signal cpu_dout   : std_logic_vector (15 downto 0);
    signal cpu_IRQ_n  : std_logic;
    signal cpu_IRQ_n_sync  : std_logic;
begin

---------------------------------------------------------------------
-- instantiated components
---------------------------------------------------------------------

    inst_dcm_49_16 : entity work.dcm_49_16 port map (
        CLKIN_IN  => fastclk,
        CLK0_OUT  => clk_16M00,
        CLK0_OUT1 => open,
        CLK2X_OUT => open
    );

    inst_mem : ram port map (
        din     => cpu_dout,
        dout    => mem_data_out,
        address => cpu_addr(12 downto 0),
        rnw     => cpu_R_W_n,
        clk     => not clk_16M00,
        cs_b    => mem_cs_b
    );

    inst_opc5ls: opc5lscpu port map(    
        din     => cpu_din,
        dout    => cpu_dout,
        address => cpu_addr,
        rnw     => cpu_R_W_n,
        clk     => clk_16M00,       -- this needs to be gated with clken
        reset_b => RSTn_sync,
        int_b   => cpu_IRQ_n_sync
    );
    

    inst_tube: tube port map (
        h_addr          => h_addr,
        h_cs_b          => h_cs_b,
        h_data          => h_data,
        h_phi2          => h_phi2,
        h_rdnw          => h_rdnw,
        h_rst_b         => h_rst_b,
        h_irq_b         => h_irq_b,
        p_addr          => cpu_addr(2 downto 0),
        p_cs_b          => p_cs_b_en,
        p_data_in       => cpu_dout(7 downto 0),
        p_data_out      => p_data_out,
        p_rdnw          => cpu_R_W_n,
        p_phi2          => clk_16M00,
        p_rst_b         => RSTn,
--      p_nmi_b         => cpu_NMI_n,
        p_irq_b         => cpu_IRQ_n
    );

    p_cs_b_en <= not((not p_cs_b) and cpu_clken);

    p_cs_b <= '0' when cpu_addr(15 downto 3) = "1111111011111" else '1';

    mem_cs_b <= '0' when p_cs_b = '1' else '1';

    cpu_din <=
        x"00" & p_data_out when   p_cs_b = '0' else
              mem_data_out when mem_cs_b = '0' else
        x"aaaa";

    ram_cs <= '1';
    ram_oe <= '1';
    ram_wr <= '1';
    ram_addr <= (others => '0');
    ram_data <= (others => 'Z');

    fcs <= '1';

    testpr : process(clk_16M00)
    begin
--        if (sw(1) = '1' and sw(2) = '1') then
          if rising_edge(clk_16M00) then

            test(6) <= cpu_R_W_n;
            if cpu_addr = x"FEFF" then
                test(5) <= '1';
            else
                test(5) <= '0';
            end if;
            test(4) <= cpu_IRQ_n_sync;
            test(3) <= p_cs_b;
            if cpu_addr = x"FEFE" then
                test(2) <= '1';
            else
                test(2) <= '0';
            end if;
            test(1) <= RSTn;

            tp(8) <= cpu_addr(6);
            tp(7) <= cpu_addr(5);
            tp(6) <= cpu_addr(4);
            tp(5) <= cpu_addr(3);
            tp(4) <= cpu_addr(2);
            tp(3) <= cpu_addr(1);
            tp(2) <= cpu_addr(0);
        end if;
    end process;


--------------------------------------------------------
-- synchronise interrupts
--------------------------------------------------------

    sync_gen : process(clk_16M00, RSTn_sync)
    begin
        if RSTn_sync = '0' then
            cpu_IRQ_n_sync <= '1';
        elsif rising_edge(clk_16M00) then
            if (cpu_clken = '1') then
                cpu_IRQ_n_sync <= cpu_IRQ_n;
            end if;
        end if;
    end process;

    rst_gen : process(clk_16M00)
    begin
        if rising_edge(clk_16M00) then
            RSTn_sync <= RSTn;
        end if;
    end process;
    cpu_clken <= '1';
    

--------------------------------------------------------
-- clock enable generator

-- 4MHz
-- cpu_clken active on cycle 0, 4, 8, 12
-- address/data changes on cycle 1, 5, 9, 13
-- phi0 active on cycle 1..2
-- phi1 active on cycle 2..3
-- phi2 active on cycle 3..0
-- phi3 active on cycle 0..1
--------------------------------------------------------
--    clk_gen : process(clk_16M00, RSTn)
--    begin
--        if rising_edge(clk_16M00) then
--            clken_counter <= clken_counter + 1;
--            cpu_clken     <= clken_counter(0) and clken_counter(1);
--            phi0          <= not clken_counter(1);
--            phi1          <= phi0;
--            phi2          <= phi1;
--            phi3          <= phi2;
--        end if;
--        RSTn_sync <= RSTn;
--    end process;
    
end BEHAVIORAL;
