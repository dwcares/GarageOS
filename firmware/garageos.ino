#include "Statistic.h"

// Photon Pins
int door1Relay = D0; // Small door
int door2Relay = D1; // Big Door

int door1Sensor = A0;
int door2Sensor = A1;

int car1YellowLED = A2;
int car1MagentaLED = A3;
int car1CyanLED = A4;

int car1SensorTrig = D6;
int car1SensorEcho = D7;

// Particle Cloud variables
int wifiStrength;

int door1Status = 0;
int door2Status = 0;

int door1LastOpenTime = 0;
int door2LastOpenTime = 0;
int door1OpenDuration = 0;
int door2OpenDuration = 0;

int car1ParkingStatus = 0;
int car2ParkingStatus = 0;

int car1Distance = 0;
int car2Distance = 0;

int const CAR_STATUS_NOTPARKED = 0;
int const CAR_STATUS_PARKED = 1;
int const CAR_STATUS_PARKEDCLOSE = 2;
int const CAR_STATUS_INVALID = -1;

int const DOOR_STATUS_CLOSED = 0;
int const DOOR_STATUS_OPEN = 1;

// Parking Sensor Smoothing
Statistic car1SensorStats; 
int const MAX_PARKING_TICKS = 100;
int const MAX_STDEV = 10;
int const PARKING_SENSOR_DELAY_MS = 10;
static bool sensorInit = false;

// Door Sensor Analog Smoothing
Statistic door1SensorStats; 
Statistic door2SensorStats; 

int const MIN_DOOR_THRESHOLD = 250;
int const MAX_DOOR1_TICKS = 100; 
int const MAX_DOOR2_TICKS = 100; 

// Server health
bool needsPublish = true;
int lastPublish = 0;
int const MIN_PUBLISH_DELTA = 1000;
int const MAX_PUBLISH_DELTA = 10000;

STARTUP(WiFi.selectAntenna(ANT_EXTERNAL));

void setup()
{
    pinMode(door1Relay, OUTPUT); 
    pinMode(door2Relay, OUTPUT);

    pinMode(car1YellowLED, OUTPUT);
    pinMode(car1MagentaLED, OUTPUT);
    pinMode(car1CyanLED, OUTPUT);
    
    Particle.variable("door1Status", &door1Status, INT);
    Particle.variable("door2Status", &door2Status, INT);
    Particle.variable("car1Distance", &car1Distance, INT);
    Particle.variable("car2Distance", &car2Distance, INT);
    Particle.variable("car1ParkingStatus", &car1ParkingStatus, INT);
    Particle.variable("car2ParkingStatus", &car2ParkingStatus, INT);
    Particle.variable("wifiStrength", &wifiStrength, INT);

    Particle.function("requestUpdate", requestUpdate);
    Particle.function("toggleDoor", toggleDoor);
    
    door1SensorStats.clear();
    door2SensorStats.clear();
    car1SensorStats.clear();
    
    digitalWrite(car1YellowLED, LOW);
    digitalWrite(car1MagentaLED, LOW);
    digitalWrite(car1CyanLED, LOW);
}

void loop()
{
    heartbeat();
    
    monitorCarStatusChange();
    monitorDoorStatusChange();

}

////////////////////////////////////
////////// PARKING STATUS ////////// 
////////////////////////////////////

void monitorCarStatusChange() {
  
  int tempParkingStatus = car1ParkingStatus;
   
  updateCarStatus();

  if (tempParkingStatus != car1ParkingStatus) {
      needsPublish  = true;
  }
}

bool updateCarStatus() {

    int car1DistanceRAW = measureInches(car1SensorTrig, car1SensorEcho, PARKING_SENSOR_DELAY_MS);
    
    car1SensorStats.add(car1DistanceRAW);
    
    updateCarStatusLED(getParkingStatusFromDistance(car1DistanceRAW));
    
   if (car1SensorStats.count() >= MAX_PARKING_TICKS) {
      if (car1SensorStats.pop_stdev() >= MAX_STDEV) {
          car1Distance = max(car1SensorStats.maximum(), 100);
      } 
      else {
          car1Distance = (int) car1SensorStats.average();
      }
          
      car1ParkingStatus = getParkingStatusFromDistance(car1Distance);
      car1SensorStats.clear();
    }
}

int measureInches(pin_t trig_pin, pin_t echo_pin, uint32_t wait)
{
    uint32_t duration, inches, cm;
    if (!sensorInit) {
        pinMode(trig_pin, OUTPUT);
        digitalWriteFast(trig_pin, LOW);
        pinMode(echo_pin, INPUT);
        delay(50);
        sensorInit = true;
    }

    digitalWriteFast(trig_pin, HIGH);
    delayMicroseconds(wait);
    digitalWriteFast(trig_pin, LOW);
  
    duration = pulseIn(echo_pin, HIGH);

    inches = duration / 74 / 2;
    cm = duration / 29 / 2;
    
    return inches;
}

int getParkingStatusFromDistance(int distance) {
    
    int parkingStatus = CAR_STATUS_INVALID;
    
   if (car1Distance > 60) {
       parkingStatus = CAR_STATUS_NOTPARKED;
    } else if (car1Distance > 40) {
       parkingStatus = CAR_STATUS_PARKED;
    } else if (car1Distance <= 40) {
        parkingStatus = CAR_STATUS_PARKEDCLOSE;
    }
    
    return parkingStatus;
}

void updateCarStatusLED(int carStatus) {
    
    // Only reflect LED parking status when the door is open
    if (door2Status == DOOR_STATUS_CLOSED) {
        digitalWrite(car1YellowLED, HIGH);
        digitalWrite(car1MagentaLED, HIGH);
        digitalWrite(car1CyanLED, HIGH);
    } else {
        switch (carStatus)
        {
          case CAR_STATUS_NOTPARKED:
          
            // YELLOW
            digitalWriteFast(car1YellowLED, HIGH); 
            digitalWriteFast(car1MagentaLED, LOW); 
            digitalWriteFast(car1CyanLED, LOW); 
            break;
            
          case CAR_STATUS_PARKED:
            
            // GREEN
            digitalWriteFast(car1YellowLED, HIGH);
            digitalWriteFast(car1MagentaLED, LOW); 
            digitalWriteFast(car1CyanLED, HIGH);
            break;
            
          case CAR_STATUS_PARKEDCLOSE:
          
            // RED
            digitalWriteFast(car1YellowLED, HIGH);
            digitalWriteFast(car1MagentaLED, HIGH);
            digitalWriteFast(car1CyanLED, LOW);
            break;
            
          default:
          
            // WHITE
            digitalWrite(car1YellowLED, LOW);
            digitalWrite(car1MagentaLED, LOW);
            digitalWrite(car1CyanLED, LOW);
        }
    }
        
}

////////////////////////////////////
/////////// DOOR STATUS //////////// 
////////////////////////////////////

void monitorDoorStatusChange() {
    
    int tempDoor1Status = door1Status;
    int tempDoor2Status = door2Status;
    
    updateDoorStatus();
 
    
    if (tempDoor1Status != door1Status) {    
        needsPublish = true;
        
        door1LastOpenTime = (door1Status == DOOR_STATUS_OPEN) ? millis() : 0;
    }
    
    if (tempDoor2Status != door2Status) {
        needsPublish = true;
        
        door2LastOpenTime = (door2Status == DOOR_STATUS_OPEN) ? millis() : 0;
    }
    
     updateOpenDuration();
}

void updateDoorStatus()
{
    // Update Door 1 Status
    int door1SensorRaw = analogRead(door1Sensor);
    door1SensorStats.add(door1SensorRaw);
    
    if (door1SensorStats.count() > MAX_DOOR1_TICKS) {
        int door1SensorValue = door1SensorStats.average();
        
        door1Status = door1SensorValue > MIN_DOOR_THRESHOLD ? DOOR_STATUS_OPEN : DOOR_STATUS_CLOSED;
        
        door1SensorStats.clear();
    }

    
    // Update Door 2 Status
    int door2SensorRaw = analogRead(door2Sensor);
    door2SensorStats.add(door2SensorRaw);
    
    if (door2SensorStats.count() > MAX_DOOR2_TICKS) {
        int door2SensorValue = door2SensorStats.average();
        
        door2Status = door2SensorValue > MIN_DOOR_THRESHOLD ? DOOR_STATUS_OPEN : DOOR_STATUS_CLOSED;
        
        door2SensorStats.clear();
    }
}

void updateOpenDuration() {
    door1OpenDuration = (door1Status == DOOR_STATUS_OPEN) ? millis() - door1LastOpenTime : 0;
    door2OpenDuration = (door2Status == DOOR_STATUS_OPEN) ? millis() - door2LastOpenTime : 0;
}

void heartbeat() 
{
    unsigned long now = millis();
    int publishDelta = now - lastPublish;
    
    if (publishDelta > MAX_PUBLISH_DELTA || (publishDelta > MIN_PUBLISH_DELTA && needsPublish )) {
        wifiStrength = WiFi.RSSI();

        String publishString = String::format("{\"uptime\":\"%d\",\"wifiStrength\":%d,\"car1Distance\":%d,\"car1ParkingStatus\":%d,\"door1Status\":%d,\"door2Status\":%d,\"door1OpenDuration\":%d,\"door2OpenDuration\":%d}",now,wifiStrength,car1Distance,car1ParkingStatus,door1Status,door2Status,door1OpenDuration, door2OpenDuration);
        publish("heartbeat", publishString);
    }
}

void publish(String eventName, int message) {
    publish(eventName, String(message)); 
}

void publish(String eventName, String message) {
     Particle.publish(eventName, message);
     lastPublish = millis();
     needsPublish = false;
}

int toggleDoor(String command)
{
  int doorNumber = command.charAt(1) - '0';

  if (doorNumber < 1 || doorNumber > 2) return -1;
  
  publish("door", command);
 
  digitalWrite(doorNumber-1, 1);
  delay(500);
  digitalWrite(doorNumber-1, 0);

  return 1;
}

int requestUpdate(String command)
{
  needsPublish = true;
  return 1;
}



