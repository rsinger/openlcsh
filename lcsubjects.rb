require 'rubygems'
require 'sinatra'

require 'haml'
require 'rdf_objects/pho'
require 'rack/conneg'
configure do
  Store = RDFObject::Store.new('http://api.talis.com/stores/lcsh-info')
  Curie.add_prefixes! :skos=>"http://www.w3.org/2004/02/skos/core#", :lcsh=>'http://LCSubjects.org/vocab/1#',
   :owl=>'http://www.w3.org/2002/07/owl#', :wgs84 => 'http://www.w3.org/2003/01/geo/wgs84_pos#', :dcterms => 'http://purl.org/dc/terms/',
   :umbel=>'http://umbel.org/umbel#', :rss=>'http://purl.org/rss/1.0/'  
end
use(Rack::Conneg) { |conneg|
  Rack::Mime::MIME_TYPES['.nt'] = 'text/plain'     
  conneg.set :accept_all_extensions, false
  conneg.set :fallback, :html
  conneg.ignore('/public/')
  conneg.ignore('/stylesheets/')
  conneg.provide([:rdf, :nt, :html, :json])
}

before do
  if negotiated?
    content_type negotiated_type
  end
end

get '/' do
  haml :welcome
end

get '/subjects/:id' do
  unless params['id'] =~ /#concept$/
    params['id'] << "#concept"
  end  
  #response = Store.describe("http://lcsubjects.org/subjects/#{params['id']}")
  #@subject = response.resource
  #@collection = response.collection
  response = describe_graph_objects("http://lcsubjects.org/subjects/#{params['id']}")
  @subject = response.collection["http://lcsubjects.org/subjects/#{params['id']}"]
  @collection = response.collection
  puts @collection.inspect  
  halt 404, "Not found" unless @subject
  #replace_uris_in_collection(@collection, rel_response.collection)
  @title = @subject.skos['prefLabel']
  respond_to do | wants |
    wants.rdf { @collection.to_xml() }
    wants.html { haml :subject, :layout=>:subject_layout }
    wants.nt {@subject.to_ntriples() }
    wants.json {@subject.to_json() }
  end  
end

get '/search/' do
  @title = 'Search LCSubjects.org'
  query = (params['q']||"*:*").clone
  query << " +resourcetype:(\"Authorized Heading\"||\"Juvenile Heading\")"
  opts = {}
  opts['max'] = params['max']||25
  opts['offset'] = params['offset']||0
  if params['sort']
    opts['sort'] = params['sort']
  end

  response = Store.search(query, opts)
  @results = SearchResult.new_from_search_result(response.resource)
  @title << ": #{params['q']}"
  facet_response = Store.facet((params['q']||"*:*"),["collection","resourcetype"], {:top=>25, :output=>"xml"}) 
  @results.parse_facet_response(facet_response.body.content)
  haml :search, :layout=>:search_layout
end

helpers do
  def describe_graph_objects(uri)
    sparql = "DESCRIBE <#{uri}> ?o WHERE { <#{uri}> ?p ?o .}"
    response = Store.sparql_describe(sparql)
    return response
  end
  
  def get_related_labels(uri)
    sparql = "PREFIX skos: <http://www.w3.org/2004/02/skos/core#>\n"
    sparql << "CONSTRUCT {?o skos:prefLabel ?label .\n"
    sparql << "?o <http://LCSubjects.org/vocab/1#type> ?t}\n"
    sparql << "WHERE\n{\n<#{uri}> ?p ?o .\n?o skos:prefLabel ?label .\n"
    sparql << "?o <http://LCSubjects.org/vocab/1#type> ?t .\n}"
    response = Store.sparql_construct(sparql) 
    return response
  end
  def replace_uris_in_collection(old_collection, new_collection)
    new_collection.each_pair do |uri, resource|
      old_collection[uri] = resource
    end
  end
  
   
  def date_display(date_literal)
    if date_literal.value.is_a?(String)
      date = DateTime.parse(date_literal.value)
    else
      date = date_literal.value
    end
    date.strftime("%A, %B %d, %Y - %I:%m:%S %p")
  end
  def scheme_labels(scheme)
    label = case scheme.uri
    when "http://lcsubjects.org/schemes/conceptScheme" then "LCSubjects.org"
    when "http://lcsubjects.org/schemes/authorities" then "LC Authorized Headings"
    when "http://lcsubjects.org/schemes/topicalTerms" then "Topical Terms"
    when "http://lcsubjects.org/schemes/geographicNames" then "Geographic Names"
    when "http://lcsubjects.org/schemes/corporateNames" then "Corporate Names"
    when "http://lcsubjects.org/schemes/personalNames" then "Personal Names"
    when "http://lcsubjects.org/schemes/generalSubdivision" then "General Subdivisions"
    when "http://lcsubjects.org/schemes/uniformTitles" then "Uniform Titles"
    when "http://lcsubjects.org/schemes/formSubdivision" then "Form Subdivisions"
    when "http://lcsubjects.org/schemes/chronologicalSubdivision" then "Chronological Subdivisions"
    when "http://lcsubjects.org/schemes/genreFormTerms" then "Genre/Form Terms"
    when "http://lcsubjects.org/schemes/meetings" then "Meetings"
    when "http://lcsubjects.org/schemes/geographicSubdivision" then "Geographic Subdivisions"
    when "http://lcsubjects.org/schemes/juvenileHeadings" then "LC Juvenile Headings"
    end
    label
  end
  
  def scheme_label(scheme)
    puts @collection[scheme.uri].assertions.inspect
    return @collection[scheme.uri]["http://www.w3.org/2000/01/rdf-schema#label"]
  end
  
  def set_facet_search(facet)
    uri = Addressable::URI.parse(facet[:uri])
    p = CGI.parse(uri.query)
    p['q'] = p['query']
    p.delete('query')
    return uri_for("/search/", p)
  end
  
  def url_from_uri(u)
    uri = Addressable::URI.parse(u)
    return(uri_for("/subjects/#{uri.path.split("/").last}"))
  end
  
  def uri_for(path, params={})
    uri = path
    query = []
    params.each_pair do |key,val|
      [*val].each do |v|
        next unless v
        query << "#{key}=#{val}"
      end
    end
    unless query.empty?
      uri << "?#{query.join("&")}"
    end
    uri
  end
  
  def divide_matches(matches)
    match = {}
    [*matches].each do | m |
      if m.uri =~ /^http:\/\/lcsubjects\.org\//
        match[:internal] ||=[]
        match[:internal] << m
      else
        match[:external] ||=[]
        match[:external] << m
      end
    end    
    match
  end
  
  def paginate(search_results)
    total_results = search_results.total_hits
    items_per_page = search_results.results_per_page
    offset = search_results.offset
    total_pages = total_results.divmod(items_per_page)[0]
    return nil if total_pages < 1
    ranges = []
    if total_pages > 10        
      #if offset != (5*items_per_page)
        ranges << (0..4)
      #end
      if offset == ((5*items_per_page) - items_per_page)
        ranges << (5..6)
        ranges << '...'
      else
        ranges << '...'
      end
      start = nil
      endpoint = nil
      if offset > (5*items_per_page)
        start = (offset-items_per_page)/items_per_page
        if (offset/items_per_page) == total_pages
          endpoint = total_pages
        else
          endpoint = (offset+items_per_page)/items_per_page
        end
        ranges << (start..endpoint)
        ranges << '...'
      end
      if !endpoint || endpoint < total_pages
        bottom = (total_pages-4)
        rng = (bottom..total_pages)
        while rng.include?(endpoint)
          bottom += 1
          rng = (bottom..total_pages)
        end
        ranges << rng
      end
    else
      ranges << (0..total_pages)
    end
    ranges
  end
end

class SearchResult
  attr_reader :total_hits, :results_per_page, :hits, :offset, :facets
  def initialize
    @total_hits = 0
    @results_per_page = 0
    @hits = []
  end
  
  def set_total_hits(i)    
    @total_hits = i.to_i
  end
  
  def set_results_per_page(i)
    @results_per_page = i.to_i
  end
  
  def add_hit(h)
    @hits << h
  end
  
  def set_offset(i)
    @offset = i.to_i
  end
  
  def parse_facet_response(xml)
    @facets = {}
    doc = Nokogiri::XML(xml)
    doc.xpath('/f:facet-results/f:fields/f:field', {"f"=>"http://schemas.talis.com/2007/facet-results#"}).each do | field |
      @facets[field.attributes['name'].value] = []
      field.xpath("./f:term", {"f"=>"http://schemas.talis.com/2007/facet-results#"}).each do | term |
        @facets[field.attributes['name'].value] << {:term=>term.attributes["value"].value, :number => term.attributes["number"].value, :uri=>term.attributes["search-uri"].value}
      end
    end
  end  
  
  def self.new_from_search_result(rdf_resource)
    result = self.new
    result.set_total_hits(rdf_resource['http://a9.com/-/spec/opensearch/1.1/']['totalResults'].value)
    result.set_results_per_page(rdf_resource['http://a9.com/-/spec/opensearch/1.1/']['itemsPerPage'].value)
    result.set_offset(rdf_resource['http://a9.com/-/spec/opensearch/1.1/']['startIndex'].value)
    [*rdf_resource.rss["items"].rdf['li']].each do |resource|
      next unless resource
      result.add_hit(resource)
    end
    result
  end
end