/*
In order to enable ULP code to run, open a terminal in PlatformIO and run the following comand:
	pio run -t menuconfig
It opens a GUI menu on the terminal. In that menu, go through the following steps:
	Component config ---> ESP32-specific --> Enable Ultra Low Power (ULP) Coprocessor
*/

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

	/* ADC1 channel 6, GPIO34 */
	.set adc_channel, 6

	/* Configure the number of ADC samples to average on each measurement.
	   For convenience, make it a power of 2. */
	.set adc_oversampling_factor_log, 2
	.set adc_oversampling_factor, (1 << adc_oversampling_factor_log)

	/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	/* Low threshold of ADC reading.
	   Set by the main program. */
	.global low_thr
low_thr:
	.long 0

	/* High threshold of ADC reading.
	   Set by the main program. */
	.global high_thr
high_thr:
	.long 0

	/* Counter of measurements done */
	.global sample_counter
sample_counter:
	.long 0

	.global last_result
last_result:
	.long 0

	/* Code goes into .text section */
	.text

	.global entry
entry:
	/* increment sample counter */
	move r3, sample_counter
	ld r2, r3, 0
	add r2, r2, 1
	st r2, r3, 0

	/* do measurements using ADC */
	/* r0 will be used as accumulator */
	move r0, 0
	/* initialize the loop counter */
	stage_rst
measure:
	/* measure and add value to accumulator */
	adc r1, 0, adc_channel + 1
	add r0, r0, r1
	/* increment loop counter and check exit condition */
	stage_inc 1
	jumps measure, adc_oversampling_factor, lt

	/* divide accumulator by adc_oversampling_factor.
	   Since it is chosen as a power of two, use right shift */
	rsh r0, r0, adc_oversampling_factor_log
	/* averaged value is now in r0; store it into last_result */
	move r3, last_result
	st r0, r3, 0

	/* compare with low_thr; wake up if value < low_thr */
	move r3, low_thr
	ld r3, r3, 0
	sub r3, r0, r3
	stage_rst
	jump try_wakeup, ov

	/* compare with high_thr; wake up if value > high_thr */
	move r3, high_thr
	ld r3, r3, 0
	sub r3, r3, r0
	stage_rst
	jump try_wakeup, ov

	/* start everything all over again */
	jump entry

try_wakeup:
	STAGE_INC 1
	JUMPS exit, 10, GT

	READ_RTC_FIELD(RTC_CNTL_LOW_POWER_ST_REG, RTC_CNTL_RDY_FOR_WAKEUP)
	AND r0, r0, 1

	JUMP try_wakeup, eq
	WAKE

exit:
	HALT
