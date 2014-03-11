require 'rsolr-ext'
module Mapper
  class SearchWorker
    def initialize(config, dictionary)
      @host = config["host"]
      @solr = RSolr::Ext.connect :url => @host
      @distance = 0
      @dictionary = dictionary
    end
    #кіл-ть документів в колекції
    def get_total_docs(flag = false)
      begin
        response = @solr.find :q=>'*:*'
      rescue => e
        p e
        return false
      end
      count = response["response"]["numFound"].to_i
      raise TypeError "Wrong response" if count.nil?
      p "Total docs found: #{count}"
      count
      (flag) ? response.ok? : count
    end
    #TODO: включити правильно delta-import
    def get_import_type
      (get_total_docs) ? 'delta-import' : 'full-import'
      'full-import'
    end
    #індексування бази
    def index
      @solr.get 'dataimport', :params => {:command => get_import_type}
    end
    def check_index
      @solr.get 'dataimport'
    end
    def remove_index
      begin
        host = 'localhost'
        port = '8983'
        delete_path = '/solr/mapper_development/update?stream.body=<delete><query>*:*</query></delete>'
        commit_path = '/solr/mapper_development/update?stream.body=<commit/>'
        delete_code = Net::HTTP.get_response(host, delete_path, port).code.to_i
        commit_code = Net::HTTP.get_response(host, commit_path, port).code.to_i
        (delete_code == 200 && commit_code == 200) ? true : false
      rescue => e
        p e
      end
    end
    # екранування спец.символів які використовує Solr
    #TODO: + AND OR && ||
    def escape str
      str.gsub(/[\/+\-!(){}\[\]^\"~\*?\\:]/) {|item| "\\#{item}"}
    end
    def boost(query, k = 100)
      # 1. Знаходимо усі слова
      # 2. Розтавляємо ^ в залежності від порядку слів у запиті
      words = []
      arr = query.split(" ")
      size = arr.length + 1
      arr.each do |word|  
      
        word = word[1..-1] if word[0] == "/"
        (word[0] == "-") ? words << word : words << "#{word}^#{(size -= 1) * k}"
      end
      words.join(" ")
    end
    #віднімає непотрібні слова такі як прийменники та інші
    def minus query
      # 1. Визначити масив слів для віднімання
      # 2. Добавити знак мінус для слів у строці
      result = query.split(" ").map! do |word|
        #word = word.downcase # TODO: downcase для українських та рос. слів
        matched = @dictionary.join(",").match(/#{word}/i)
        (matched) ?  word = "-#{word}" : word
      end
      p result
      result.join(" ")
    end
    def server_running?
      get_total_docs(true)
    end
    def cut_float str
      (str.index ".") ? str.split(".")[0] : str
    end
    def find(fields, rows = 1)
      raise ArgumentError "No query given" if fields.nil?
      raise ArgumentError "Title is empty!" if fields[:title].empty?
      options = Hash.new
      options[:title] = boost minus(escape(fields[:title]))
      options[:model] = boost(escape(cut_float fields[:model]), 1000) unless fields[:model].nil? || fields[:model].empty?
    
      solr_params = {
        :queries => options,
        :rows => rows,
        :wt => :ruby
      }
      response = @solr.find solr_params
      response[:count] = response["response"]["numFound"].to_i
      response
    end
  end
end
