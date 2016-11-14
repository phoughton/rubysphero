require 'rubyserial'
require 'date'

module SpheroUtilities


	def print_format_bytes(bytes)
		return_str=""
		bytes.each do |rsp_array|
			return_str += rsp_array.to_s(16)
			return_str +=  " "
		end # each
		return return_str
	end # def 


	def do_checksum(bytes)
		total=0
		bytes.each do | a_byte |
			total+=a_byte
		end # each
		logd "Checksum of these bytes: #{print_format_bytes(bytes)}"
		chk1= (total%256)
		chk2=  (chk1 ^ 0b11111111)
		logd "Checksum calculated: #{chk2.to_s(16)}"
		return chk2
		
	end # def 

	def add_checksum(full_bytes)
		to_chk_bytes = full_bytes.drop(2)
		full_bytes.push do_checksum(to_chk_bytes)
		return full_bytes
	end # def
	
	def logd(log_str="")
		puts DateTime.now.strftime("%Y-%m-%d %H:%M:%S.%L") + " " + log_str
	end # def 

end # mod 

class SpheroClient

	include SpheroUtilities
	COMMS_RETRY=5
	
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
		request=SpheroRequest.new(:synchronous)

		request.did=0x00 
		request.cid=0x01 # Ping
		request.seq=get_sequence
		request.dlen=0x01
		
		return send_and_check(request)
	end # def 

	def send_and_check(request)
		send_data(request.build_packet)

		COMMS_RETRY.times do
			response = read_data(request)
			if request.seq == response.echoed_seq then
				logd("Sent and received Sequences MATCH.")	
				return true
			end # if 
			logd("Sequences do NOT MATCH. Sent:#{request.seq} Rec:#{response.echoed_seq} ")
		end # times
		return false
	end # data 
	
	def send_data(data)
		logd("Wire send next.")
		@connection.write data
	end # def 

	def read_data(request)
		#logd ("Length to read: #{length}")
		#bytes=@connection.read(length).unpack("C*")
		bytes=[]
		get_more_data = true 

		begin 
			byte_maybe=@connection.getbyte
			print ","

			if byte_maybe
				bytes.push byte_maybe
				logd("Wire returned a byte: #{byte_maybe}")
		
				response = SpheroResponse.new(bytes.dup)
				if request.seq == response.echoed_seq then
					if response.valid
						logd("Response is valid!!!")
						return response
					else
						logd("Response not valid yet...")
					end # if 
				end # if 
			else
				#get_more_data = false
				print "."
				sleep 0
			end # else 
		end while get_more_data
		
		#logd("Wire read finished.")
		#response = SpheroResponse.new( bytes)
		#logd ("Length actually read: #{response.raw_length}")

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
				return true
			else 
				sleep 1	
			end # if 
		end # upto 	
		return false
	end # def 
	
	
	def set_back_led_output(brightness)
		logd()
		logd "Building request: set back led output b"
		
		request=SpheroRequest.new(:synchronous)

		request.did=0x02 
		request.cid=0x21 
		request.seq=get_sequence
		request.dlen=0x02
		request.push_data brightness 
		
		return send_and_check(request)	
	
	end # def 
	
	def set_heading(heading_raw) 
		logd
		logd( "Building request: Set Heading")

		request=SpheroRequest.new(:synchronous)
		heading = heading_raw%359
		logd( "Heading: #{heading}")

		request.did=0x02 
		request.cid=0x01
		request.seq=get_sequence
		request.dlen=0x03
		
		request.push_data(heading , :a16bit)
		
		return send_and_check(request)	
	
	end # def 

	def set_colour(chosen_colour) 
		logd
		logd("Locating RGB values for: #{chosen_colour}")
		return set_colour_rgb(COLOURS[chosen_colour][0],COLOURS[chosen_colour][1],COLOURS[chosen_colour][2])
	end # def 
	
	
	def set_colour_rgb(red_value,green_value,blue_value)
		logd
		logd "Building request: colour"
		
		request=SpheroRequest.new(:synchronous)


		request.did=0x02 
		request.cid=0x20 # Set RGB Output
		request.seq=get_sequence
		request.dlen=0x05
		request.push_data red_value 
		request.push_data green_value
		request.push_data blue_value  
		flag=0x01
		request.push_data flag 
		
		return send_and_check(request)

	end # def 

	def roll(heading_raw=0, speed=0xFF)
		logd()
		logd( "Building request: roll")

		request=SpheroRequest.new(:synchronous)
		heading = heading_raw%359
		logd( "Heading: #{heading}")

		request.did=0x02 
		request.cid=0x30 # Roll
		request.seq=get_sequence
		request.dlen=0x05

		state=0x01
		
		request.push_data speed
		request.push_data(heading , :a16bit)
		request.push_data state
		
		return send_and_check(request)	

	end #def 

	def get_sequence
		@sequence_val+=1
		if @sequence_val > 255
			@sequence_val=0 
		end # if
		logd("Getting seq: #{@sequence_val}")
		return @sequence_val
	end # def 
	
	def initialize(bluetooth_address)
		@sequence_val=0 
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
	attr_accessor :echoed_seq
	attr_accessor :raw_data
	attr_accessor :data
	attr_accessor :valid


	def initialize(raw_data)
		@valid=false
		@raw_data=raw_data.dup
		@data=process_data(raw_data)
	end # def
	
	def raw_length
		if @data==nil
			return 0
		else
			@raw_data.length
		end # else
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
				logd("Response data:#{bytes}")
				@echoed_seq=bytes[1]
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
	attr_accessor :sequence

	
	def initialize(type=:synchronous)
		if type==:synchronous
			@sop1=0xFF
			@sop2=0xFF 
		end # if
		
		@packet_data=Array.new
		@payload_data=Array.new
	end # def 

	def length
		return @packet_data.length
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