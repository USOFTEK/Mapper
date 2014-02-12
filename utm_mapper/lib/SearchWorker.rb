require 'rsolr-ext'

class SearchWorker
  # <= TODO: include EM::Deferrable
  def initialize(config, dictionary)
    p "Config for search: " + config["host"]
    @solr = RSolr::Ext.connect :url => config["host"]
    @distance = 0
    @dictionary = dictionary
  end
  #кіл-ть документів в колекції
  def get_total_docs
    total = @solr.get 'select', :params => {:q => "*:*", :wt => :ruby}
    count = total["response"]["numFound"]
    raise TypeError "Wrong response" if count.nil?
    p "Total docs found: #{count.to_i}"
    count
  end
  #TODO: включити правильно delta-import
  def get_import_type
    (get_total_docs) ? 'delta-import' : 'full-import'
    'full-import'
  end
  #індексування бази
  def index
    response = @solr.get 'dataimport', :params => {:command => get_import_type}
    p response
    self
  end
  # екранування спец.символів які використовує Solr
  def escape str
    str.gsub(/[+\-!(){}\[\]^\"~\*?\\:]/) {|item| "\\#{item}"}
  end
  def boost(query, k = 100)
    # 1. Знаходимо усі слова
    # 2. Розтавляємо ^ в залежності від порядку слів у запиті
    words = []
    arr = query.split(" ")
    size = arr.length + 1
    arr.each do |word|  
      (word[0] == "-") ? words << word : words << "#{word}^#{(size -= 1) * k}"
    end
    words.join(" ")
  end
  #віднімає непотрібні слова такі як прийменники та інші
  def minus query
    # 1. Визначити масив слів для віднімання
    # 2. Добавити знак мінус для слів у строці
    result = query.split(" ").map! do |word|
       word = word.downcase # TODO: downcase для українських та рос. слів
       matched = @dictionary.join(",").match(/#{word}/)
       (matched) ?  word = "-#{word}" : word
    end
    p result
    result.join(" ")
  end
  def find(fields)
    raise ArgumentError "No query given" if fields.nil?
    raise ArgumentError "Title is empty!" if fields[:title].empty?
    #TODO: implement Booster for boosting
    options = Hash.new
    options[:title] = boost minus(escape fields[:title])
    options[:model] = boost(escape(fields[:model]), 1000) unless fields[:model].nil? || fields[:model].empty?
    
    solr_params = {
          :queries => options,
          :rows => 5,
          :wt => :ruby
    }
    response = @solr.find solr_params
    response[:count] = response["response"]["numFound"].to_i
    response
  end
end

