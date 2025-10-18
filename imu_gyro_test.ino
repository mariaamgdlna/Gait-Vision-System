#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>
#include <Adafruit_HMC5883_U.h>

Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);
Adafruit_HMC5883_Unified mag = Adafruit_HMC5883_Unified(12346);

#define ITG3200_ADDR 0x68
#define ITG3200_REG_GYRO 0x1D

bool isRunning = true;

void setup() {
  Serial.begin(9600);
  Wire.begin(8, 9);

  // Initialize accelerometer
  if (!accel.begin()) {
    Serial.println("ADXL345 tidak terdeteksi!");
    while (1);
  }

  // Initialize magnetometer
  if (!mag.begin()) {
    Serial.println("HMC5883L tidak terdeteksi!");
    while (1);
  }

  // Initialize gyroscope
  Wire.beginTransmission(ITG3200_ADDR);
  Wire.write(0x3E);
  Wire.write(0x00);
  Wire.endTransmission();

  Serial.println("AccX;AccY;AccZ;GyroX;GyroY;GyroZ;MagX;MagY;MagZ");
  Serial.println("Ketik 'stop' untuk menghentikan program");
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    if (input.equalsIgnoreCase("stop")) {
      isRunning = false;
      Serial.println("Program dihentikan.");
    }
  }

  if (isRunning) {
    sensors_event_t accelEvent, magEvent;
    accel.getEvent(&accelEvent);
    mag.getEvent(&magEvent);

    int16_t gx = 0, gy = 0, gz = 0;
    Wire.beginTransmission(ITG3200_ADDR);
    Wire.write(ITG3200_REG_GYRO);
    Wire.endTransmission(false);
    Wire.requestFrom(ITG3200_ADDR, 6, true);
    
    if (Wire.available() >= 6) {
      gx = Wire.read() << 8 | Wire.read();
      gy = Wire.read() << 8 | Wire.read();
      gz = Wire.read() << 8 | Wire.read();
    }

    Serial.print(accelEvent.acceleration.x); Serial.print(";");
    Serial.print(accelEvent.acceleration.y); Serial.print(";");
    Serial.print(accelEvent.acceleration.z); Serial.print(";");
    Serial.print(gx); Serial.print(";");
    Serial.print(gy); Serial.print(";");
    Serial.print(gz); Serial.print(";");
    Serial.print(magEvent.magnetic.x); Serial.print(";");
    Serial.print(magEvent.magnetic.y); Serial.print(";");
    Serial.println(magEvent.magnetic.z);

    delay(1000);
  }
}
