# GarageOS: Building a Smart Garage

A few months ago, the garage door opener motor at my house failed. I don't blame it -- after decades of dutifully opening and closing its 160 lb door on command, perhaps it was time for a rest. Also this old garage door opener didn't have the benifits of modern technology, like secure radio codes, advanced drive systems and of course, internet connectivity.

Walking through the aisle of a suburban Home Depot, I was amazed to see how many of the garage door openers sold there provided some sort of app to control and get notifications about the door. Those features seem cool, but besides a hefty $200 price premium, I don't just want a smart garage door opener, I want a complete smart garage. So, I bought the cheapest opener for $60 bucks and set off to build a smart garage myself: GarageOS.

## Scope it out
Given my [background](http://dwcares.com/2013/08/19/slide-deck-framing/), for most projects that I take on, even the fun ones, I go through a quick process of planning. Really, what's the pain that I'm trying to solve, to make my life better...not just add technology for technology sake (even though there's some of that too).

### Problems worth solving
1. When I'm heading out on a walk or a bike ride, I always go out the garage since that's the best way to get to town, and it's where all the wagons, strollers and bikes are stored. This means brining a garage door remote on every walk, if I forget it, I'm essentially locked out. I wish I always had a garage door remote with me.
2. When I'm halfway across the country on a vacation, I always have that pit in my stomach -- did I leave the garage door open? I wish I could just know, even if I'm in a different time zone.
3. When I pull into the garage with the car, space is at a premium. If I don't pull to close enough, the garage door won't close or I won't be able to get the trunk open, if I pull to close, I wont be able to walk pass the car. I wish I could just know the sweet spot of when I'm parked correctly.
4. When I'm at work, it would be great if I knew my wife's car was home yet, or if she's still on her way.

### Most important to me
Given these problems, let's decide on a few capabilities worth building in our GarageOS. If I build these capabilities, I'll solve most of my major problems. Also, besides the new capabilities that I'm adding to my garage, I have some requirements that make are essential to making this something that is actually helping me, not making my life worse.
* Open and close the door
* Know if the door is open, and for how long
* Know if a car is parked
* Know if I'm parked correctly
* Don't interfere with the safety or reliablilty of the garage
* Be as reliable as a physical garage door opener

### Other cool stuff
In the future, we might want to add some more cool stuff too, but for now we'll park these for future consideration. 
* Know temperature and humidity
* More security features and cameras
* Security alerts and texts
* Log arrival/departure times
* Speech command and control, conversational AI (what could go wrong?)

![Open the pod bay doors](https://media.giphy.com/media/3o7qDJw6t5ss2FLr32/giphy.gif)

## The Hardware Build

### Things used in the project
* [Particle Photon](https://store.particle.io/collections/photon)
* [Particle Relay Shield](https://store.particle.io/collections/shields-and-kits)
* [5mm Common Cathode RGB LED](http://www.amazon.com/microtivity-IL612-Diffused-Controllable-Common/dp/B006S21SQO/ref=sr_1_1?s=industrial&ie=UTF8&qid=1464707436&sr=1-1&keywords=5mm+rgb+led)
* [5 dB Antenna](http://www.amazon.com/Wi-fi-Antenna-RP-SMA-Antennas-Cables/dp/B00A4I3AGE?ie=UTF8&psc=1&redirect=true&ref_=oh_aui_detailpage_o06_s00)
* [Magnetic Reed Switch](http://www.amazon.com/Directed-Electronics-8601-Magnetic-Switch/dp/B0009SUF08?ie=UTF8&psc=1&redirect=true&ref_=oh_aui_detailpage_o03_s00)
* [Strong Disc Magnet](http://www.amazon.com/Industrial-Grade-10E794-Magnet-Ceramic/dp/B007OXE56G/ref=sr_1_2?s=industrial&ie=UTF8&qid=1464707385&sr=1-2&keywords=magnet)
* [Hc-SR04 Ultrasonic ping sensor](http://www.amazon.com/Mihappy-Ultrasonic-Distance-Measuring-Transducer/dp/B00IJWZTI4?ie=UTF8&psc=1&redirect=true&ref_=oh_aui_detailpage_o08_s00)

### Step 1: Opening and closing the doors


*The Garage Door Switch*

So the first and most obvious thing for me to build was to open and close the doors. This way I could use a website or my phone to open the door when I'm out on a walk. I was nervous about figuring out how to actually toggle the door open and closed. But then I took the switch off the wall, connected the two wires and the door came to life and travelled down the track. No magic in this wall switch, it just completes the circuit like any switch. Then I just needed to figure out how to do it from the the internets.

*Relay all the things*

 It turns out, doing this is amazingly easy with a Particle Photon and a relay. A relay is like a digitally controlled switch. It's just as easy to use as turning an LED on and off (the 'hello world' of IoT Projects) but instead of turning a light on, it changes the world around you by switching potentially higher voltage stuff like Christmas lights, rocket launch circuits, or in this case a garage door. To control it from the internet, all I did was follow the Particle: [Control an LED from the 'nets](https://docs.particle.io/guide/getting-started/examples/photon/#control-leds-over-the-39-net) sample and replace LED in the circuit with the relay. Sweet. I hooked the other side of the relay up to the door switch on the wall, and I was in business!
 
### Step 2: Reading the Garage Door State
 
 *But, is the door open tho?*
 
 Something I quickly figured out after demoing that I could open my garage door from across the country, is that I had created a new problem for myself. If I forgot how many times I hit the button, or accidently opened the door, I had no idea if the door was open or closed, potentially leaving the garage and all of it's cluttered goodies vulnerable for theft.
 
 *Magnetic reed switch*
 
 After a tiny bit of reseach I found a Magnetic Reed Switch. It's basically, what you see on those window security systems. One side is a basic magnet, and the other side is a switch that closes when another magnet is nearby. For the garage door, I put a heavy duty magnet on the door, and a mounted the switch on the wall so when the door was closed, the magnet would line up with the switch. When the door was open, the switch would be open. Then it was just a matter of running a bunch of wires through the rafters from the door to the Photon, mounted by the wall.
 
### Step 3: Parking distance
The next thing we want to be able to do is to read the parking distance of the car the car parked in the garage. Essentially, how far is the car parked from the wall? Then we want to indicate to the driver of the car with some sort of visual status that they've parked correctly, or parked too close.

*Ultrasonic ping sensor* 

In order to measure the parking distance, I ended up using an ultrasonic ping sensor. It's basically a microphone and a speaker in one. The microphone is listening for a specific tone, and the speaker is emitting that tone at a specified interval. Then in the code, I was measure how long it takes for the tone to to bounce back from the car as it approaches the wall. With the speed of sound a constant, I could calcuate this is centemeters. 

I could then use this measured distance value to report the status back to the driver. In my case, I was looking for a sweet spot of 50 inches. If it was any less than 50 inches, it was too close, or any greater than 60 inches, and the car is not pulled in far enough. I used these values to decide what color to change the led to. 

### Hardware overview

Now that the hardware is built and in place, now it's just a matter of writing the firmware to behave the way we want it to, and write a mobile app to wrap it all up. 

### Wiring Diagram
![Wiring diagram](images/garageos-fritzing.png)

## The Firmware

The Particle Photon runs a continuous loop that monitors sensors and publishes state to the Particle Cloud.

### Pin assignments

| Pin | Function |
|-----|----------|
| D0 | Small door relay |
| D1 | Big door relay |
| A0 | Small door magnetic reed switch |
| A1 | Big door magnetic reed switch |
| A2 | Parking LED (Yellow) |
| A3 | Parking LED (Magenta) |
| A4 | Parking LED (Cyan) |
| D6 | Ultrasonic sensor trigger |
| D7 | Ultrasonic sensor echo |

### Cloud variables

| Variable | Type | Description |
|----------|------|-------------|
| `door1Status` | int | Small door: 0 = closed, 1 = open |
| `door2Status` | int | Big door: 0 = closed, 1 = open |
| `car1Distance` | int | Parking distance in inches |
| `car1Status` | int | 0 = not parked, 1 = parked, 2 = too close |
| `wifiStrength` | int | WiFi RSSI in dBm |

### Cloud functions

| Function | Argument | Description |
|----------|----------|-------------|
| `toggleDoor` | `r1` or `r2` | Pulses relay for 500ms to toggle the door |

### Sensor smoothing

Both door sensors and the parking sensor use statistical smoothing (100-sample windows) to filter noise. The parking sensor also uses standard deviation to reject outlier readings.

### Heartbeat

The firmware publishes a JSON heartbeat event every 60 seconds (or immediately on state change). This includes all sensor values, door open durations, and uptime. The iOS and watchOS apps subscribe to these events for real-time updates.

### SMS alerts

A Particle webhook (`firmware/webhook.json`) can be configured with Twilio credentials to send SMS alerts when a door has been open for too long.

## The Software Build

### iOS App

The iPhone app connects to the Particle Cloud via the Particle iOS SDK (CocoaPods) and provides:

* **Door control** -- Force press (3D Touch) the Small or Big door button to toggle
* **Door status** -- Visual indicators show open/closed state with open duration timers
* **Parking distance** -- Shows car distance in inches with a progress bar
* **Signal strength** -- Displays WiFi RSSI and last update time
* **Real-time updates** -- Subscribes to heartbeat and door-status-change events via Particle Cloud SSE

### watchOS App

The Apple Watch companion app is a standalone SwiftUI app that talks directly to the Particle Cloud REST API -- no iPhone required. It works independently over WiFi or cellular.

* **Crown dial to trigger** -- Rotate the Digital Crown to fill a ring; when it reaches the threshold, the door toggles. This intentional gesture prevents accidental triggers.
* **Haptic feedback** -- Subtle clicks at 50% and 75%, satisfying success haptic at 100%
* **Door status** -- Full blue ring = closed, empty ring = open. Polls every 10 seconds.
* **Optimistic updates** -- Icon morphs immediately on trigger using SF Symbol animations, then confirms with the cloud
* **Decay** -- Ring fades back to zero after 1 second of inactivity
* **Two pages** -- Swipe horizontally between Small Door and Big Door

## Project Structure

```
garageos/
  firmware/
    garageos.ino          # Main Particle Photon firmware
    statistic.h/.cpp      # Sensor smoothing library
    webhook.json          # Twilio SMS alert webhook config
  iOS/
    GarageOS/             # iPhone app (UIKit + Particle SDK)
      AppDelegate.swift
      ViewController.swift
      GarageClient.swift  # Particle Cloud singleton
      Secrets.swift       # Credentials (gitignored)
    GarageOSWatch/        # Watch app (SwiftUI + REST API)
      GarageOSWatchApp.swift
      DoorDialView.swift  # Crown dial UI
      GarageManager.swift # Status polling + door toggle
      ParticleAPI.swift   # Direct Particle Cloud REST client
    Podfile               # CocoaPods (iOS app only)
  images/
    garageos-fritzing.png # Wiring diagram
    garageos-fritzing.fzz # Editable Fritzing source
```

## Setup

### Prerequisites

* Xcode 15+
* CocoaPods (`brew install cocoapods`)
* A Particle Photon with the firmware flashed
* A Particle Cloud account

### iOS & watchOS apps

1. Clone the repo
2. Create `iOS/GarageOS/Secrets.swift` with your credentials:
   ```swift
   public class Secrets {
       static let particleUser: String = "your@email.com"
       static let particlePassword: String = "your-password"
       static let particleDeviceID: String = "your-device-id"
   }
   ```
3. Install pods:
   ```
   cd iOS
   pod install
   ```
4. Open `iOS/GarageOS.xcworkspace` in Xcode
5. Build and run the **GarageOS** scheme for iPhone
6. Build and run the **GarageOSWatch** scheme for Apple Watch

### Firmware

1. Set up your Particle Photon on your WiFi network via the [Particle app](https://docs.particle.io/getting-started/getting-started/photon/)
2. Flash `firmware/garageos.ino` via the [Particle Web IDE](https://build.particle.io) or Particle CLI
3. Wire up the hardware per the [wiring diagram](images/garageos-fritzing.png)

## License

[MIT](LICENSE)
