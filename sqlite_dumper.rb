class SqliteDumper
	attr_accessor :logger
	def initialize(logger, dump)
		self.logger = logger
		
		self.logger.info "================================================="
		self.logger.info "Generating MD5 Checksum"
		
		db_id = Digest::MD5.hexdigest(dump.inspect)
		self.logger.info "DB checksum is #{db_id}"
		
		db_path = "./stores/#{db_id}.sqlite3"
		
		if File.exists?(db_path)
			self.logger.info "DB with the same data exists..."
			return
		end
		
		File.open("./version.txt", "w") do |file|
			file.write db_id
		end
		
		self.logger.info "Creating sqlite3 file: #{db_path}"
		File.open(db_path, "w")
		
		self.logger.info "Opening..."
		ActiveRecord::Base.establish_connection({ :adapter => "sqlite3", :database => db_path, :pool => 5, :timeout => 5000 })
		
		self.logger.info "Migrating DB..."
		ActiveRecord::Base.logger = self.logger
		ActiveRecord::Migrator.migrate('db/migrate', nil)
		
		self.logger.info "Dumping bus plan to file..."
		
	end
	
	
end