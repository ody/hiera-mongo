class Hiera
    module Backend
        class Mongo_backend
            def initialize
                require 'mongo'
                
                @db = Mongo::Connection.new(Config[:mongo][:server]).db(Config[:mongo][:database])

                Hiera.debug("Hiera mongo backend starting")
            end

            def lookup(key, scope, order_override, resolution_type)
                answer = Backend.empty_answer(resolution_type)

                Hiera.debug("Looking up #{key} in mongo backend")

                Backend.datasources(scope, order_override) do |source|
                    Hiera.debug("Looking for data source #{source}")

                    collection = @db[source] || next

                    row = collection.find('name' => key).to_a
                    
                    next if row.empty?
                    data = row[0]['value'] || next

                    # for array resolution we just append to the array whatever
                    # we find, we then goes onto the next file and keep adding to
                    # the array
                    #
                    # for priority searches we break after the first found data item
                    case resolution_type
                    when :array
                        answer << Backend.parse_answer(data, scope)
                    else
                        answer = Backend.parse_answer(data, scope)
                        break
                    end
                end

                return answer
            end
        end
    end
end
