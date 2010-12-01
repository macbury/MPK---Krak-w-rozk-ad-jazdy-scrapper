class SqliteDumper
	attr_accessor :logger
	def initialize(logger, dump)
		self.logger = logger
		
		self.logger.info "================================================="
		self.logger.info "Generating MD5 Checksum"
		
		db_id = Digest::MD5.hexdigest(dump.inspect)
		self.logger.info "DB checksum is #{db_id}"
		
		db_path = "./tmp/#{db_id}.sqlite3"
		
		if File.exists?(db_path)
			self.logger.info "DB with the same data exists..."
			return
		end
		
		self.logger.info "Creating sqlite3 file: #{db_path}"
		File.open(db_path, "w")
		
		self.logger.info "Opening..."
		ActiveRecord::Base.establish_connection({ :adapter => "sqlite3", :database => db_path, :pool => 5, :timeout => 5000 })
		
		self.logger.info "Migrating DB..."
		ActiveRecord::Base.logger = self.logger
		ActiveRecord::Migrator.migrate('db/migrate', nil)
		
		db = SQLite3::Database.new(db_path)
		
		self.logger.info "Dumping bus plan to file..."
		
		line_index = 0
		plan_index = 0
		stop_index = 0
		dump.each do |line|
			line[:directions].each do |direction, stops|
				sql = "INSERT INTO lines (id, number, type, direction, description) VALUES (#{line_index}, #{line[:number]}, #{line[:type]}, #{direction.inspect}, #{line[:description].inspect})"
				
				ActiveRecord::Base.connection.execute(sql)
				
				stops.each_with_index do |stop|
					name = stop[:name]
					
					sql = "INSERT INTO stops (id, line_id, name) VALUES (#{stop_index}, #{line_index}, #{name.inspect})"
					ActiveRecord::Base.connection.execute(sql)

					stop[:time].each do |day_type, times|
						times.each do |time|
							sql = "INSERT INTO plan (id, stop_id, type, time) VALUES (#{plan_index}, #{stop_index}, #{day_type}, #{time})"

							ActiveRecord::Base.connection.execute(sql)
							plan_index += 1
						end
					end
					
					stop_index += 1
				end
				
				line_index += 1
			end
		end
		
		File.open("./version.txt", "w") do |file|
			file.write db_id
		end
		
		self.logger.info "Compressing database..."
		shell = "cd ./tmp; tar -czf ../stores/#{db_id}.tar.gz #{db_id}.sqlite3"
		self.logger.info "exec: #{shell}"
		exec(shell)
	end
end