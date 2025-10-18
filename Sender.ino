#include <esp_now.h>
#include <WiFi.h>

typedef struct sensor_data {
    float accX;
    float accY;
    float accZ;
    float gyroX;
    float gyroY;
    float gyroZ;
} sensor_data;

const uint8_t leftNodeMAC[] = {0x80, 0x65, 0x99, 0xE9, 0x64, 0xD6};
const uint8_t rightNodeMAC[] = {0x80, 0x65, 0x99, 0xE9, 0xE9, 0x30}; 

bool compareMac(const uint8_t * mac1, const uint8_t * mac2) {
    for(int i = 0; i < 6; i++) {
        if(mac1[i] != mac2[i]) return false;
    }
    return true;
}

void OnDataRecv(const esp_now_recv_info *info, const uint8_t *data, int data_len) {
    sensor_data *sensorReadings = (sensor_data *)data;
    
    if(compareMac(info->src_addr, leftNodeMAC)) {
        Serial.print("L");
        Serial.printf("%0.2f,%0.2f,%0.2f,%0.2f,%0.2f,%0.2f\n", 
                    sensorReadings->accX, sensorReadings->accY, sensorReadings->accZ,
                    sensorReadings->gyroX, sensorReadings->gyroY, sensorReadings->gyroZ);
    }
    else if(compareMac(info->src_addr, rightNodeMAC)) {
        Serial.print("R");
        Serial.printf("%0.2f,%0.2f,%0.2f,%0.2f,%0.2f,%0.2f\n", 
                    sensorReadings->accX, sensorReadings->accY, sensorReadings->accZ,
                    sensorReadings->gyroX, sensorReadings->gyroY, sensorReadings->gyroZ);
    }
}

void setup() {
    Serial.begin(115200);
    WiFi.mode(WIFI_STA);
    
    // Initialize ESP-NOW
    if (esp_now_init() != ESP_OK) {
        Serial.println("ESP-NOW initialization failed!");
        delay(1000);
        ESP.restart();
    }
    Serial.println("ESP-NOW initialized successfully!");
    
    esp_now_register_recv_cb(OnDataRecv);
}

void loop() {
    delay(2000);
}
