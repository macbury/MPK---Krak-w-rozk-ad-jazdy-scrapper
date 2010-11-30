class MPKScrapper
	RootURL = "http://rozklady.mpk.krakow.pl/"
	LineURL = "/linie.aspx"
	
	attr_accessor :logger
	
	def initialize(logger)
		self.logger = logger
		self.logger.info "MPK - Krakow Plan Scrapper"
	end
	
	def run
		self.parse_lines
	end
	
	def parse_lines
		self.logger.info "Opening url: #{LineURL}"
		doc = Nokogiri::HTML(open(File.join([RootURL, LineURL])))
		lines = {}
		
		doc.css("table").each do |table|
			bus_type = table.at_css("th").text
			if bus_type =~ /(autobusowe|tramwajowe|aglomeracyjne)/i
				self.logger.debug ">>>>>>>>>>>>>>>> [ #{bus_type.strip} ] <<<<<<<<<<<<<<<<"

				table.css("td a").each do |line|
					stops_with_url = self.parse_bus_stop(line.text, line[:href])
					
					stops_with_url.each do |direction, stops|
						lines[line.text + " - " + direction] = {}
						stops.each do |stop, url|
							self.logger.debug "&&&&&&&&&&&&&&&&&&&&& #{stop} &&&&&&&&&&&&&&&&&&&&&"
							next if url.nil?
							lines[line.text + " - " + direction][stop] = self.parse_time_table_for_stop_url(url)
						end
					end
				end
			end
		end
		
		SqliteDumper.new(self.logger, lines)
	end
	
	def parse_time_table_for_stop_url(url)
		self.logger.info "Opening: #{url}"
		doc = Nokogiri::HTML(open(url))
		
		time_table = doc.at_css("body > table").css("tr table")[1]
		
		cursing_days = {}
		time_table.css("tr")[0].css("td").each do |td|
			cursing_days[td.text] = []
		end
		
		self.logger.debug "Cursing days: #{cursing_days.map{|d, t| d}.join(", ")}"
		
		table_days_indexes = [[0,1], [2,3], [4,5]]
		
		time_table.css("tr")[1..-2].each do |tr|
			row = tr.css("td")
			#puts row
			cursing_days.each_with_index do |day, day_index|
				day = day[0]
				
				hour_index = table_days_indexes[day_index][0]
				hour_minutes = table_days_indexes[day_index][1]
				
				hour = row[hour_index].text.strip
				row[hour_minutes].text.split(" ").map(&:strip).each do |minute|
					minutes = hour.to_i * 60 + minutes.to_i
					cursing_days[day] = [] unless cursing_days[day]
					cursing_days[day] << minutes
					self.logger.debug "#{hour}:#{minute} -> #{minutes}"
				end
			end
		end
		
		cursing_days
	end
	
	def parse_bus_stop(line, url)
		self.logger.debug "==================== [ #{line} ] ===================="
		
		url = File.join([RootURL, url])
		self.logger.info "Opening url: #{url}"
		
		directions = {}
		
		stops, next_direction_url = self.build_directions_streets(url)
		directions["#{stops.first[0]} -> #{stops.last[0]}"] = stops
		
		if next_direction_url
			stops, next_direction_url = self.build_directions_streets(next_direction_url)
			directions["#{stops.first[0]} -> #{stops.last[0]}"] = stops
		end
		
		directions.each do |direction, stops|
			self.logger.debug "------------- [#{direction}] -------------"
			self.logger.debug stops.map{ |s| s[0] }.join(" -> ")
		end
		
	end
	
	def build_directions_streets(url)
		self.logger.info "Opening: #{url}"
		
		doc = Nokogiri::HTML(open(url))
		streets_url = ""
		
		doc.css("frame").each do |line|
			if line[:name] =~ /l/i
				streets_url = line[:src]
				break
			end
		end
		
		path = url.split("/")
		path = path.join("/").gsub(url.split("/")[-1], "")
		streets_url = File.join([path, streets_url])
		
		doc = Nokogiri::HTML(open(streets_url))
		stops = []
		
		doc.css("ul li a").each do |line|
			next unless (line[:target] =~ /\Ar\Z/i)
			stops << [line.text, File.join([path,line[:href]])]
		end
		
		doc.css("ul li b").each do |line|
			stops << [line.text, nil]
		end
		
		next_direction_url = nil
		doc.css("ul li a").reverse.each do |line|
			next_direction_url = File.join([path,line[:href]]) unless line[:href] =~ /\.\.\/\p\//i
			break
		end
		
		return [stops, next_direction_url]
	end
	
end