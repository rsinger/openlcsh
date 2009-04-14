class SearchResult
  attr_accessor :query, :offset, :total_results, :items_per_page
  attr_reader :results
  
  def initialize()
    @results = []
  end
  def <<(subject)
    @results << subject
  end

end
