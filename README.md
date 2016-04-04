# rubysphero

Rubysphero is a simple driver for Orbotix's Sphero.

Example code:
```Ruby 
require './sphero_comms'

sphero = SpheroClient.new "COM5"  

SpheroClient::COLOURS.each_key do |colour_name|
	sphero.set_colour(colour_name)
	sleep 2
end # each	
	
sphero.ping

sphero.orientation
	
sphero.roll(0,70)
sleep 2 
sphero.roll(90,70)
sleep 2 
sphero.roll(180,70)
sleep 2 
sphero.roll(270,70)


sphero.close
```