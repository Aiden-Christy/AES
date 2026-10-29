----------------------------------------------------------------------------------------------------------------------------------------
--
--	RADPC
--  SOFT ERROR MITIGATION CONTROLLER
--
--	CREATED BY CHRIS MAJOR
--  RESILIENT COMPUTING
-- 	01/07/20
--
--!	@file
--!	@brief Component for the Soft Error Mitigation Controller, based on the SEM IP Example Project
--  Note: the UART communication baudrate is 19200! 
--
----------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------------------------------------
--  LIBRARIES
----------------------------------------------------------------------------------------------------------------------------------------

-- IEEE Standard Library
library IEEE;
    
	--! IEEE Standard Logic Library
	use IEEE.STD_LOGIC_1164.ALL;


-- -- Xilinx Libraries
-- library unisim;

--     -- Xilinx primitive libraries
--     use unisim.vcomponents.all;


----------------------------------------------------------------------------------------------------------------------------------------
--  ENTITY
----------------------------------------------------------------------------------------------------------------------------------------
entity sem_controller is
port (
    i_clk                       : in        std_logic;                                      --! Input Clock
    
    i_inject_strobe             : in        std_logic;                                      --! Command Injection Strobe
    i_inject_command            : in        std_logic_vector( 39 downto 0 );                --! Command Injection 
    
    o_sem_status                : out       std_logic_vector( 7 downto 0 );                 --! SEM Status Bits
    
    i_icap_to_sem               : in        std_logic_vector(31 downto 0);                  --! ICAP port output (SEM input)
    o_sem_to_icap               : out       std_logic_vector(31 downto 0);                  --! ICAP port input (SEM output)
    o_icap_csib                 : out       std_logic;                                      --! ICAP Enable (Active Low)
    o_icap_rdwrb                : out       std_logic;                                      --! ICAP Read/Write
    i_icap_grant                : in        std_logic;                                      --! ICAP Access Grant
    
    i_fecc_crcerr               : in        std_logic;                                      --! Frame ECC CRC Flag
    i_fecc_eccerr               : in        std_logic;                                      --! Frame ECC ECC Flag
    i_fecc_eccerrsingle         : in        std_logic;                                      --! Frame ECC Single Error Flag
    i_fecc_syndromevalid        : in        std_logic;                                      --! Frame ECC Syndrome Valid Flag
    i_fecc_syndrome             : in        std_logic_vector(12 downto 0);                  --! Frame ECC Syndrome
    i_fecc_far                  : in        std_logic_vector(25 downto 0);                  --! Frame ECC FAR Register
    i_fecc_synbit               : in        std_logic_vector(4 downto 0);                   --! Frame ECC Syndrome Bit
    i_fecc_synword              : in        std_logic_vector(6 downto 0);                   --! Frame ECC Syndrome Word
    
    i_monitor_rx                : in        std_logic;                                      --! SEM UART RX
    o_monitor_tx                : out       std_logic                                       --! SEM UART TX
);
end entity;


----------------------------------------------------------------------------------------------------------------------------------------
--  ARCHITECTURE
----------------------------------------------------------------------------------------------------------------------------------------
architecture sem_controller_arch of sem_controller is


	------------------------------------------------------------------------------------------------------------------------------------
	--  COMPONENT DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------
    
    -- Declare the component for the Soft Error Mitigation device
    component sem_0
    port (
        status_heartbeat                : out   std_logic;
        status_initialization           : out   std_logic;
        status_observation              : out   std_logic;
        status_correction               : out   std_logic;
        status_classification           : out   std_logic;
        status_injection                : out   std_logic;
        status_essential                : out   std_logic;
        status_uncorrectable            : out   std_logic;
        
        monitor_txdata                  : out   std_logic_vector(7 downto 0);
        monitor_txwrite                 : out   std_logic;
        monitor_txfull                  : in    std_logic;
        
        monitor_rxdata                  : in    std_logic_vector(7 downto 0);
        monitor_rxread                  : out   std_logic;
        monitor_rxempty                 : in    std_logic;
        
        inject_strobe                   : in    std_logic;
        inject_address                  : in    std_logic_vector(39 downto 0);
        
        fecc_crcerr                     : in    std_logic;
        fecc_eccerr                     : in    std_logic;
        fecc_eccerrsingle               : in    std_logic;
        fecc_syndromevalid              : in    std_logic;
        fecc_syndrome                   : in    std_logic_vector(12 downto 0);
        fecc_far                        : in    std_logic_vector(25 downto 0);
        fecc_synbit                     : in    std_logic_vector(4 downto 0);
        fecc_synword                    : in    std_logic_vector(6 downto 0);
        
        icap_o                          : in    std_logic_vector(31 downto 0);
        icap_i                          : out   std_logic_vector(31 downto 0);
        icap_csib                       : out   std_logic;
        icap_rdwrb                      : out   std_logic;
        icap_clk                        : in    std_logic;
        icap_request                    : out   std_logic;
        icap_grant                      : in    std_logic
    );
    end component;


    -- Declare the component for the SEM monitor interface
    component sem_monitor
    port (
        i_clk                           : in    std_logic;
       
        i_monitor_rx                    : in    std_logic;
        o_monitor_tx                    : out   std_logic;
        
        i_monitor_tx_data               : in    std_logic_vector(7 downto 0);
        i_monitor_tx_write              : in    std_logic;
        o_monitor_tx_full               : out   std_logic;
        
        o_monitor_rx_data               : out   std_logic_vector(7 downto 0);
        i_monitor_rx_read               : in    std_logic;
        o_monitor_rx_empty              : out   std_logic
    );
    end component;
    

	------------------------------------------------------------------------------------------------------------------------------------
	-- SIGNAL DECLARATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    signal w_status_heartbeat                   : std_logic;                        --! SEM Heartbeat flag
    signal w_status_initialization              : std_logic;                        --! SEM initialization flag
    signal w_status_observation                 : std_logic;                        --! SEM Observation state flag
    signal w_status_correction                  : std_logic;                        --! SEM Correction state flag
    signal w_status_classification              : std_logic;                        --! SEM Classification state flag
    signal w_status_injection                   : std_logic;                        --! SEM Injection state flag
    signal w_status_essential                   : std_logic;                        --! SEM Essential Bit state flag
    signal w_status_uncorrectable               : std_logic;                        --! SEM Uncorrectable state flag
    
    signal r_monitor_tx_data                    : std_logic_vector(7 downto 0);     --! Register for Monitor internal transmit buffer
    signal w_monitor_tx_write                   : std_logic;                        --! Signal for Monitor transmit buffer write enable
    signal w_monitor_tx_full                    : std_logic;                        --! Signal for Monitor transmit buffer full/empty state
    
    signal r_monitor_rx_data                    : std_logic_vector(7 downto 0);     --! Register for Monitor internal receive buffer
    signal w_monitor_rx_read                    : std_logic;                        --! Signal for Monitor receive buffer read enable
    signal w_monitor_rx_empty                   : std_logic;                        --! Signal for Monitor receive buffer full/empty state


begin

    
    ------------------------------------------------------------------------------------------------------------------------------------
	--  INSTANTIATIONS
	------------------------------------------------------------------------------------------------------------------------------------

    -- Instantiate the SEM device based on the Xilinx IP core
    SEM_DEVICE_0 : sem_0 port map (
        status_heartbeat                => w_status_heartbeat,
        status_initialization           => w_status_initialization,
        status_observation              => w_status_observation,
        status_correction               => w_status_correction,
        status_classification           => w_status_classification,
        status_injection                => w_status_injection,
        status_essential                => w_status_essential,
        status_uncorrectable            => w_status_uncorrectable,
        
        monitor_txdata                  => r_monitor_tx_data,
        monitor_txwrite                 => w_monitor_tx_write,
        monitor_txfull                  => w_monitor_tx_full,
        
        monitor_rxdata                  => r_monitor_rx_data,
        monitor_rxread                  => w_monitor_rx_read,
        monitor_rxempty                 => w_monitor_rx_empty,
        
        inject_strobe                   => i_inject_strobe,
        inject_address                  => i_inject_command,
        
        fecc_crcerr                     => i_fecc_crcerr,
        fecc_eccerr                     => i_fecc_eccerr,
        fecc_eccerrsingle               => i_fecc_eccerrsingle,
        fecc_syndromevalid              => i_fecc_syndromevalid,
        fecc_syndrome                   => i_fecc_syndrome,
        fecc_far                        => i_fecc_far,
        fecc_synbit                     => i_fecc_synbit,
        fecc_synword                    => i_fecc_synword,

        icap_clk                        => i_clk,        
        icap_o                          => i_icap_to_sem,
        icap_i                          => o_sem_to_icap,
        icap_csib                       => o_icap_csib,
        icap_rdwrb                      => o_icap_rdwrb,
        icap_grant                      => i_icap_grant,
        icap_request                    => open
    );


    -- Instantiate the SEM Monitor component
    MONITOR_0 : sem_monitor port map (
        i_clk                           => i_clk,
        
        i_monitor_rx                    => i_monitor_rx,
        o_monitor_tx                    => o_monitor_tx,

        i_monitor_tx_data               => r_monitor_tx_data,
        i_monitor_tx_write              => w_monitor_tx_write,
        o_monitor_tx_full               => w_monitor_tx_full,
        
        o_monitor_rx_data               => r_monitor_rx_data,
        i_monitor_rx_read               => w_monitor_rx_read,
        o_monitor_rx_empty              => w_monitor_rx_empty
    );
    

    -- Route the SEM status signals to their outputs
    o_sem_status(0)                     <= w_status_heartbeat;
    o_sem_status(1)                     <= w_status_initialization;
    o_sem_status(2)                     <= w_status_observation;
    o_sem_status(3)                     <= w_status_correction;
    o_sem_status(4)                     <= w_status_classification;
    o_sem_status(5)                     <= w_status_injection;
    o_sem_status(6)                     <= w_status_essential;
    o_sem_status(7)                     <= w_status_uncorrectable;


end architecture;
----------------------------------------------------------------------------------------------------------------------------------------
--  END OF CODE
----------------------------------------------------------------------------------------------------------------------------------------