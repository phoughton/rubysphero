# rubysphero

Rubysphero is a simple ruby driver for Orbotix's Sphero.

Developed and tested in Ruby 2.2.x on Windows 10, but should work on other platforms (Mac & Linux).

## Installation
```gem install rubysphero```

## Example code:
```Ruby 
require 'rubysphero'

sphero = SpheroClient.new "COM5"  

# Cycle through all Colours the driver knows about.
SpheroClient::COLOURS.each_key do |colour_name|
	sphero.set_colour(colour_name)
	sleep 2
end # each	
	
sphero.ping

# Orient which way is back (180 degrees)
# Press and hold 'Enter' to spin the tail light round
# Press SPACE and then Enter to confirm that the tail light is at 180 degrees
sphero.orientation
	
# Roll forward (0 degrees) at speed 70 (out of 255)
sphero.roll(0,70)
sleep 2 

sphero.roll(90,70)
sleep 2 

sphero.roll(180,70)
sleep 2 

sphero.roll(270,70)
sleep 2

sphero.close
```