#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "driver/adc.h"
#include "sdkconfig.h"

#include "esp32/ulp.h"
#include "esp_sleep.h"
#include "driver/rtc_io.h"
#include "soc/rtc_cntl_reg.h"
#include "ulp_main.h"

extern const uint8_t ulp_main_bin_start[] asm("_binary_ulp_main_bin_start");
extern const uint8_t ulp_main_bin_end[]   asm("_binary_ulp_main_bin_end");

static void blink_led(int,int);
static void init_ulp_program(void);
static void start_ulp_program(void);
static void eloc_function(void);

//#define BLINK_GPIO CONFIG_BLINK_GPIO
#define BLINK_GPIO 2

void app_main() 
{
    esp_sleep_wakeup_cause_t cause = esp_sleep_get_wakeup_cause();
    if (cause != ESP_SLEEP_WAKEUP_ULP) {
        // starting device for the first time
        blink_led(60, 20); // comment out later
        init_ulp_program();

    } else {
        // woken up by the ULP
        eloc_function();
    }

    // goto deep sleep
    start_ulp_program();
    ESP_ERROR_CHECK( esp_sleep_enable_ulp_wakeup() );
    esp_deep_sleep_start();
}

static void init_ulp_program(void)
{
    esp_err_t err = ulp_load_binary(0, ulp_main_bin_start,
            (ulp_main_bin_end - ulp_main_bin_start) / sizeof(uint32_t));
    ESP_ERROR_CHECK(err);


    /* Configure ADC channel */
    /* Note: when changing channel here, also change 'adc_channel' constant
       in main.S */
    adc1_config_channel_atten(ADC1_CHANNEL_6, ADC_ATTEN_DB_11);
    adc1_config_width(ADC_WIDTH_BIT_12);
    adc1_ulp_enable();

    /* Set low and high thresholds, approx. 1.35V - 1.75V*/
    ulp_low_thr = 0;
    ulp_high_thr = 4000;
}

static void start_ulp_program(void)
{
    /* Reset sample counter */
    //ulp_sample_counter = 0;

    /* Start the program */
    esp_err_t err = ulp_run(&ulp_entry - RTC_SLOW_MEM);
    ESP_ERROR_CHECK(err);
}

static void eloc_function(void)
{
    blink_led(60, 20);
    // ToDo:
    // 1. capture data from ADCs for 27 second
    // 2. save to SD card
    // 3. run ML on the data
    // 4. if elephant detected, send notification through LoRa
}

static void blink_led(int interval, int times)
{
    gpio_pad_select_gpio(BLINK_GPIO);
    gpio_set_direction(BLINK_GPIO, GPIO_MODE_OUTPUT);

    for (int i = 0; i < times; i++)
    {
        printf("Turning on the LED\n");
        gpio_set_level(BLINK_GPIO, 1);
        vTaskDelay(interval / portTICK_PERIOD_MS);
        printf("Turning off the LED\n");
        gpio_set_level(BLINK_GPIO, 0);
        vTaskDelay(interval / portTICK_PERIOD_MS);
    }
}
