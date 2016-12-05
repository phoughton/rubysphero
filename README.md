# rubysphero

Rubysphero is a simple ruby driver for Orbotix's Sphero.

Developed and tested in Ruby 2.2.x on Windows 10, but should work on other platforms (Mac & Linux).

## Installation
```gem install rubysphero```

## Example code: Changing colours 
```Ruby 
require 'rubysphero'

sphero = SpheroClient.new "COM4"  

# Cycle through all Colours the driver knows about.
SpheroClient::COLOURS.each_key do |colour_name|
	sphero.set_colour(colour_name)
	sleep 2
end # each	
```

Example code: Orientation and then roll forward at full speed...
```Ruby
require 'rubysphero'

sphero = SpheroClient.new "COM4"  

# Orient which way is back (180 degrees)
# Press and hold 'Enter' to spin the tail light round
# Press SPACE and then Enter to confirm that the tail light is at 180 degrees
sphero.orientation
	
# Roll forward (0 degrees) at speed 70 (out of 255)
sphero.roll(0,127)
sleep 2 

sphero.close
```

Example code: Orientation and the move in a square

You can also see this in action on YouTube:

<iframe width="560" height="315" src="https://www.youtube.com/embed/EesOPdC2aw0" frameborder="0" allowfullscreen></iframe>

Here is the code:
```Ruby
require 'rubysphero'

sphero = SpheroClient.new "COM4"  

sphero.orientation # Orient the Sphero, using Enter key, then Space then Enter.

sphero.roll(0,50)
sleep 1
sphero.roll(90,50)
sleep 1
sphero.roll(180,50)
sleep 1
sphero.roll(270,50)

```

Example code: React when Sphero hits something.
```Ruby
require 'rubysphero'

sphero = SpheroClient.new "COM4"  

# Add first message to show after a collision
sphero.define_event_handling_for(:collision) do
	puts "Bang!"
end # event

# Add second message to show after a collision
sphero.define_event_handling_for(:collision) do
	puts "Crash!"
end # event

sphero.collision_detection(true)

sphero.orientation # Orient the Sphero, using Enter key, then Space then Enter.

sphero.roll(0,255) # Roll 0 degrees at full speed.

sleep 2

```



