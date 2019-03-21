require 'json'
require 'rest-client'

def seconds_to_hms(sec)
  [sec / 3600, sec / 60 % 60, sec % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
end

url = "https://petition.parliament.uk/petitions/241584/count.json"
record_file = "counts.txt"

if File.exist?(record_file)
	counts = JSON.parse(File.read(record_file))
else
	puts "initializing counts"
	File.write(record_file, "{}")
	counts = {}
end

count = counts[counts.keys.last]
count = 0 if count.nil?

sleep_time = 5
time_since_last_update = 0

while true
	last_count = count

	begin
		count = JSON.parse(RestClient.get(url))["signature_count"]
		time_since_last_update = 0
	rescue
		time_since_last_update = time_since_last_update + sleep_time
		print "."
		sleep sleep_time
		next
	end
	print "\n" if time_since_last_update != 0

	diff = count - last_count

	time_string = Time.now.strftime("%Y-%m-%d %H:%M:%S")
	counts[time_string] = count
	File.write(record_file, JSON.dump(counts))
	
	per_second = diff/(sleep_time + time_since_last_update)
	
	if per_second == 0	
		until_1m = 17000000-count
		seconds_until_1m = until_1m
	else
		until_1m = 17000000-count
		seconds_until_1m = until_1m/per_second
	end
	
	puts "#{time_string} [#{count}] [+#{diff.to_s.rjust(5,' ')}] [#{per_second.to_s.rjust(5, ' ')}/sec] [#{seconds_to_hms(seconds_until_1m)} to 17M] - #{(diff/10).times.map { "#" }.join("")}"

	sleep sleep_time

end
