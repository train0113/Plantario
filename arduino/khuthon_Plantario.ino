#include <Wire.h>
#include <DHT11.h>
#include <SoftwareSerial.h>

SoftwareSerial BLE(9, 8);
DHT11 dht11(A0);

int Sensor_pin = A1;
int LED_R = 3;
int LED_G = 4;

void setup() {
  Serial.begin(9600);
  BLE.begin(9600);

  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
}

void loop() {
  int sensorValue = analogRead(Sensor_pin); // ground humidity
  int humidityPercent = map(sensorValue, 1023, 300, 0, 100);
  humidityPercent = constrain(humidityPercent, 0, 100);
  
  int lightValue = analogRead(A2); // light

  float temp, humi; // temperature and air humidity
  int result = dht11.read(humi, temp);
  
  BLE.print("Light: ");
  BLE.println(lightValue);
  
  BLE.print("Water: ");
  BLE.print(humidityPercent);
  BLE.println(" %");

  BLE.print("Temp:"); 
  BLE.println(temp); 
  BLE.print("Humi:");
  BLE.println(humi); 
  BLE.println();

  delay(2000);
}
