require 'benchmark'

class Test < PriceManager
   def empty_products
      Price.delete_all
      Product.delete_all
    end
    def benchmark
      Benchmark.bm do |x|
        x.report("delete"){empty_products}
        x.report("insert")do
          load_from_dir
        end
      end
    end
end
