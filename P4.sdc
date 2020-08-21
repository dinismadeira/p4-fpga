#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period "10.0 MHz" [get_ports ADC_CLK_10]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK1_50]
create_clock -period "50.0 MHz" [get_ports MAX10_CLK2_50]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}]
#set_clock_groups -asynchronous -group {[get_clocks {altera_reserved_tck}]}  -group {[get_clocks {*clk_in*}]} -group { [get_clocks {*pll1|inclk*}] }
set_clock_groups -exclusive -group {MAX10_CLK1_50} 
set_clock_groups -exclusive -group {clock_control|pll_p4|altpll_component|auto_generated|pll1|clk[0]} 
set_clock_groups -exclusive -group {IO|gsensor|u_spi_pll|altpll_component|auto_generated|pll1|clk[0]}
set_clock_groups -exclusive -group {IO|interrupt_generator|ADC|adc_mega_0|ADC_CTRL|adc_pll|auto_generated|pll1|clk[0]}

#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



