#author: nychka08@yandex.ua

require 'rubygems'
require 'capybara'
require 'capybara-webkit'
require 'capybara/dsl'
require_relative 'logger_custom'

Capybara.run_server = false
Capybara.current_driver = :webkit # <=:selenium || :webkit
Capybara.app_host = 'http://market.yandex.ua'

  class Parser
      extend Capybara::DSL
      include Capybara::DSL
      
      extend Logger_Custom
      Logger_Custom.setFilePath("market.log")
      #Logger_Custom.welcome
	
      #attr_accessor :tryAgain, :writeLog, :errorHandler, :retries
      @@retries = 3 # <= кіл-ть спроб
      # retry block
      @@tryAgain = Proc.new do
	    if @@retries > 0
		  p "Try to visit. Retries left: #{@@retries}"
		  @@retries -= 1
		  redo # <= retry doesn't work in Proc
	    end
      end
      
      # write to log
      @@writeLog = Proc.new do |message, status|
	    Logger_Custom.write(message, status)
	    p "Wrote into log"
      end
      
      # handling errors
      #TODO: придумати опрацювання помилок
      @@errorHandler = Proc.new do
	    exit
      end
      
      @@commonBlock = Proc.new do |message, status|
	    @@tryAgain.call
	    @@writeLog.call(message, status)
	    @@errorHandler.call
      end
      
      @@get = Proc.new do |url|
	    visit(url)
	    @@code = page.driver.status_code
	    raise Capybara::CapybaraError unless (200..399).member?(@@code) # <= #throw an exception when server code response is not 200
	    p  "Status code: #{@@code} OK :)"
      end
      
      @@find = Proc.new do |selector|
	    page.all(selector)
      end
	
      # wrap for visit
      def get(data)
	    
	  begin
	        if data.include? "/"
		      @@get.call(data)
	        else
		      p "has selector? #{page.has_selector? data}"
		      raise Capybara::ElementNotFound unless page.has_selector? data
		      return @@find.call(data)
	        end
	  rescue Capybara::Webkit::InvalidResponseError => e # <= wrong domain address
		p "Fatal error"
		@@commonBlock.call(e.message, "fatal")
	  rescue Capybara::CapybaraError # <= bad response from server
		p "bad response"
		@@commonBlock.call("Status code: #{@@code}", "error")
          rescue Capybara::ElementNotFound => e
		p e.message
		@@commonBlock.call(e.message, "warn")
          rescue => e
		p e.message
	  else
		#return
	  end
      end
      #розбиває крихту на хеш-таблицю
      def getHashFromUrl(node, mode)
	      href = node[:href]
	      id = self.send("get#{mode.capitalize!}Id", href)
	      name = node.text
	      {:href => href, :id => id, :name => name}
      end
      def getCategoryId(url)
	      url.split("hid=")[1]
      end
      def getProductId(url)
	     url.split(/modelid=([0-9]+)/)[1]
      end
      def getPageNumber(url)
		url.split("page=")[1]
      end
  end
  class ParserBot < Parser
   
    def initialize
	@categories = Array.new
    end
    def showCategories
	p @categories
    end
    def getCategories
      get('/index-full.xml')
      
      #1. знаходимо всі потрібні категорії
      get(".guru > a").each { |cat| @categories << getHashFromUrl(cat, "category") } # <= Exception! b > a
      @categories
    end
  end
  class CategoryParserBot < Parser
	def initialize(category)
		@category = category
	end
	#займається збором всіх посилань на товари у категорії
	#посилання на товар allProducts[:pages][0][:products][0][:productInfo][:href]
	def getProductsUrls
	      productBot = PageParserBot.new @category # <= передаємо першу категорію нашому боту, який буде парсити продукти
	      @productsUrls = productBot.getAllCategoryProducts # <= Витягує всі посилання на товари у вибраній категорії
        end
	def getProductsDetails
	    url = @productsUrls[:pages][1][:products][3][:productInfo][:href] # <= друга сторінка 4 товар
	    pBot = ProductParserBot.new url
	    hash = {}
	    hash[:subcategories] = pBot.getSubcategories
	    hash[:description] = pBot.getDescription
	    p hash
        end
  end
  # вибирає детальну інформацію для продукта
  class ProductParserBot < Parser
	
      def initialize(url)
	     get(url)
      end
      def getSubcategories
	      crumbs = get('div.b-breadcrumbs a')
	      arr = Array.new
	      crumbs.each do |crumb|
		      arr << getHashFromUrl(crumb, "category") do |hash|
			       hash[:name] = crumb.find('span').text
		      end
	      end
	      arr
      end
      #опис для продукта
      def getDescription
	      price = get('.b-model-prices__avg').first();
	      name = get('h1.b-page-title').first().text;
	  {
	      :name => name,
	      :price => price.find('.b-prices__num').text,
	      :currency => price.find('.b-prices__currency').text,
	      :image => get("img[alt='#{name}']").first()[:src]
	  }
      end
      #характеристики для продукта
      def getСharacteristics
	    #TODO: вибрати характеристики продукту
      end
  end
  #парсить сторінки одна за одну для даної категорії
  class PageParserBot < Parser
	include Capybara::DSL
	
	def initialize(category)
		@category = category
	end
	#переходить до всіх товарів вибраної категорії і витягує інформацію про продукти
	#! вже саму інформацію про продукт (опис, катринки, характеристики) опрацьовує ProductParserBot
	def getAllCategoryProducts
		get(@category[:href])
		#Переходимо на сторінку всіх товарів даної категорії
		get("/search.xml?hid=#{@category[:id]}")
		#який загальний збір даних про продукти
		allProducts = {:pages => Array.new}
		allProducts[:category] = @category
		allProducts[:pages] << getPageData
		#пробігаємся по всім сторінкам, аж до кінця
		1.times do 
			get('.b-pager__next').first().click # <= посилання далі
			allProducts[:pages] << getPageData
		end
		#p allProducts
		allProducts
	end
	#обробляє дані з сторінки і повертає хеш-таблицю з результатами
	def getPageData
	    pageLog = {:products => Array.new} # <= дані про товари зібрані з однієї сторінки
	    pageLog[:url] = page.current_url
	    pageLog[:page] = getPageNumber(pageLog[:url])
	    #збирає силки тільки тих продуктів, які розміщені на Маркеті безпосередньо
	    onlyYandexProducts = get(".b-offers_type_guru_mix .b-offers__desc").each do |productContainer|
		    crumbs, hash = Array.new, {}
		    #витягуємо крихти
		    productContainer.all(".b-offers__bcrumbs a").each {|crumb| crumbs << getHashFromUrl(crumb, "category")}
		    hash[:crumbs] = crumbs
		    #знаходимо посилання на продукт
		    product = productContainer.find(".b-offers__title a")
		    #витягуємо всі потрібні дані
		    hash[:productInfo] = getHashFromUrl product, "product"
		    pageLog[:products] << hash
	    end
	    #дані для перевірки цілісності
	    pageLog[:wholeness] = onlyYandexProducts.length === pageLog[:products].length # <= чи дорівнює кіл-ть силок для опрацювання  кіл-ті уже опрацьованих
	    p "current page is :#{pageLog[:page]}"
	    pageLog
	end
  end

bot = ParserBot.new
categories = bot.getCategories # <= масив з категоріями
autoCategoryBot = CategoryParserBot.new categories[0] # <= створюємо бота для опрацювання категорії
#передаємо кіл-ть сторінок для опрацювання
categoryProductsUrls = autoCategoryBot.getProductsUrls # <= витягує всі посилання товарів у категорії
p categoryProductsUrls
# записуємо у базу силки
# далі інший бот бере посилання з бази і витягує деталі до товару, також записує в базу
autoCategoryBot.getProductsDetails # <= витягує всі дані про продукти у категоріїl




