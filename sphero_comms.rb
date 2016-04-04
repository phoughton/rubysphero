require 'rubyserial'
require './sphero_utilities'

class SpheroClient

	include SpheroUtilities

		COLOURS = { 	:blue 	=> 	[0x00,0x00,0xFF],
							:green 	=> 	[0x00,0xFF,0x00],
							:red	=>	[0xFF,0x00,0x00],
							:orange	=>	[0xFF,0x8C,0x00],
							:yellow	=>	[0xFF,0xFF,0x00],
							:white	=>	[0xFF,0xFF,0xFF],
							:black	=>	[0x00,0x00,0x00],
							:pink	=>	[0xFF,0x00,0xFF],
							:grey	=>	[0x80,0x80,0x80]}
	
	def ping
		logd()
		logd "Building request: ping"
		request=SpheroRequest.new()

		request.sop1=0xFF	
		request.sop2=0xFF

		request.did=0x00 
		request.cid=0x01 # Ping
		request.seq=0x52
		request.dlen=0x01
		send_data(request.build_packet)
		
		read_data
	end # def 

	def send_data(data)
		logd("Wire send next.")
		@connection.write data

	end # def 

	def read_data
		bytes=@connection.read(7).unpack("C*")
		logd("Wire read finished.")
		response = SpheroResponse.new( bytes)

		return response
		
	end	# def
	
	def orientation
			
		set_back_led_output(255)
		set_colour(:black)
		1.step(720,5) do | heading | 	
			roll(heading , 0)
			
			inputted_text=gets.chomp
			
			if inputted_text =="" then
				# spin
			elsif inputted_text==" "			
				set_back_led_output(0)
				set_heading(heading)
				set_colour(:white)
				break
			else 
				sleep 1	
			end # if 
		end # upto 	
	
	end # def 
	
	
	def set_back_led_output(brightness)
		logd()
		logd "Building request: set back led output b"
		
		request=SpheroRequest.new()

		request.sop1=0xFF	
		request.sop2=0xFF

		request.did=0x02 
		request.cid=0x21 
		request.seq=0x53
		request.dlen=0x02
		request.push_data brightness 
		
		send_data(request.build_packet)
		read_data	
	
	end # def 
	
	def set_heading(heading_raw) 
		logd
		logd( "Building request: Set Heading")

		request=SpheroRequest.new()
		heading = heading_raw%359
		logd( "Heading: #{heading}")
		
		request.sop1=0xFF	
		request.sop2=0xFF

		request.did=0x02 
		request.cid=0x01
		request.seq=0x55
		request.dlen=0x03
		
		request.push_data(heading , :a16bit)
		
		send_data(request.build_packet)
		read_data	
	
	
	end # def 

	def set_colour(chosen_colour) 
		logd
		logd("Locating RGB values for: #{chosen_colour}")
		set_colour_rgb(COLOURS[chosen_colour][0],COLOURS[chosen_colour][1],COLOURS[chosen_colour][2])
	end # def 
	
	
	def set_colour_rgb(red_value,green_value,blue_value)
		logd
		logd "Building request: colour"
		
		request=SpheroRequest.new()

		request.sop1=0xFF	
		request.sop2=0xFF

		request.did=0x02 
		request.cid=0x20 # Set RGB Output
		request.seq=0x53
		request.dlen=0x05
		request.push_data red_value 
		request.push_data green_value
		request.push_data blue_value  
		flag=0x01
		request.push_data flag 
		
		send_data(request.build_packet)
		read_data
	end # def 

	def roll(heading_raw=0, speed=0xFF)
		logd()
		logd( "Building request: roll")

		request=SpheroRequest.new()
		heading = heading_raw%359
		logd( "Heading: #{heading}")
		
		request.sop1=0xFF	
		request.sop2=0xFF

		request.did=0x02 
		request.cid=0x30 # Roll
		request.seq=0x54
		request.dlen=0x05

		state=0x01
		
		request.push_data speed
		request.push_data(heading , :a16bit)
		request.push_data state
		
		send_data(request.build_packet)
		read_data	

	end #def 

	def initialize(bluetooth_address)
		return open(bluetooth_address)
	end # class

	def open(bluetooth_address)
		begin
			@connection   = Serial.new bluetooth_address, 115200 ,8
		rescue RubySerial::Exception
			open bluetooth_address
		end
		return @connection
	end # def 

	def close
		@connection.close
	end # def 

end # class 

class SpheroResponse      
	
	include SpheroUtilities
	
	attr_accessor :calculated_checksum
	attr_accessor :raw_checksum

	attr_accessor :raw_data
	attr_accessor :data
	attr_accessor :valid


	def initialize(raw_data)
		@valid=false
		@data=process_data(raw_data)
	end # def
	
	def process_data(bytes)
		if bytes.length == 0  
			logd "Response: None received"
		elsif bytes==nil
			logd "Response: Was nil"
		else 
			logd "Response data raw: #{print_format_bytes(bytes)}"
			bytes.shift
			bytes.shift
			@raw_checksum=bytes.pop

			@calculated_checksum=do_checksum( bytes )
			logd "Response checksum: #{@calculated_checksum.to_s(16)}"
			if @raw_checksum == @calculated_checksum then
				logd("Response Checksum is good")
				@valid=true
				@data=bytes
			end # if 
			
		end # else 
		
	end	# def
end # class

class SpheroRequest
	include SpheroUtilities
	
	attr_accessor :sop1
	attr_accessor :sop2
	attr_accessor :did
	attr_accessor :cid
	attr_accessor :dlen
	attr_accessor :seq
	attr_accessor :checksum
	#attr_accessor :payload_data

	
	def initialize
		@packet_data=Array.new
		@payload_data=Array.new
	end # def 
	
	def build_packet
		packet_no_checksum=[@sop1, @sop2, @did, @cid, @seq, @dlen]

		packet_no_checksum.concat @payload_data
		packet_with_checksum=add_checksum(packet_no_checksum)
		packet_packed=packet_with_checksum.pack("C*")	
		logd(print_format_bytes(packet_with_checksum))
		@packet_data=packet_packed
		return @packet_data
	end # def
	
	def push_data(data_input, length=:a8bit)
		# 8bit and 16bit numbers
		if data_input > 0xFF then
			logd("Greater than 255, splitting into MSB and LSB)}")
			logd("Masked: #{(data_input & 0b0000000100000000 ).to_s(2)}")
			data_input_msb = 	 (data_input & 0b0000000100000000) >> 8
			data_input_lsb = 	data_input & 0b0000000011111111
			
			logd("data_input MSB #{data_input_msb.to_s(2)}")
			logd("data_input LSB #{data_input_lsb.to_s(2)}")		
			@payload_data.push data_input_msb
			@payload_data.push data_input_lsb
		
		else 
			if length==:a16bit
				@payload_data.push 0x00
			end #if 
			@payload_data.push data_input
		end # else 
	end # def
	
end # class 