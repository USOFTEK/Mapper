module Logger_Custom
    require 'logger'
    @@path = 'log.out'
    @@mode = :debug
    
    #задає розташування лог-файлу
    def setFilePath(path)
        raise ArgumentError, "file location is not defined" until path.is_a? String
        @@path = path
    end
    def welcome
        p "Starting logging...Checking for file path.."
        p "Log writes into #{@@path}"
    end
    def write(message, *mode)
        (!mode.empty?) ? mode = mode[0].to_sym :  mode = @@mode;
        File.open(@@path, 'a') do |file|
            logger = Logger.new(file)
            begin
                logger.method(mode).call(message) # <= provide more flexible way of log messaging by adding type of log
            rescue Exception => e
                logger.method(:fatal).call(e.message)
            end
            logger.close
        end
    end
    module_function :write, :setFilePath, :welcome
end