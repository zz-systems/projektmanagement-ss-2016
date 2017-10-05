@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.2\\bin
call %xv_path%/xelab  -wto 485d9add827145c995ff2a5d25c529dc -m64 --debug typical --relax --mt 2 -L work -L pm_lib -L secureip --snapshot tb_lbp_kernel_behav pm_lib.tb_lbp_kernel -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
