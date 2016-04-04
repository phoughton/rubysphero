
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