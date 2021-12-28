/*
In order to enable ULP code to run, open a terminal in PlatformIO and run the following comand:
	pio run -t menuconfig
It opens a GUI menu on the terminal. In that menu, go through the following steps:
	Component config ---> ESP32-specific --> Enable Ultra Low Power (ULP) Coprocessor
*/

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

	.bss
	.text

	.global entry
entry:
	STAGE_RST

try_wakeup:
	STAGE_INC 1
	JUMPS exit, 10, GT

	READ_RTC_FIELD(RTC_CNTL_LOW_POWER_ST_REG, RTC_CNTL_RDY_FOR_WAKEUP)
	AND r0, r0, 1

	JUMP try_wakeup, eq
	WAKE

exit:
	HALT