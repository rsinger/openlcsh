require 'rubygems'
require "bundler/setup"
require 'sinatra'

require 'haml'
require 'sasquatch'
require 'rdf/rdfobjects'
require 'rdf/json'
require 'rdf/rdfxml'
require 'rack/conneg'
module RDF
  class LCSH < RDF::Vocabulary("http://LCSubjects.org/vocab/1#");end
  class WGS84 < RDF::Vocabulary('http://www.w3.org/2003/01/geo/wgs84_pos#');end  
  class UMBEL < RDF::Vocabulary('http://umbel.org/umbel#');end  
end
configure do
  Store = Sasquatch::Store.new('lcsh-info')
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
  response = Store.augment("http://lcsubjects.org/subjects/#{params['id']}")
  @subject = response["http://lcsubjects.org/subjects/#{params['id']}"]
  @collection = response
  
  halt 404, "Not found" unless @subject

  @title = @subject.SKOS.prefLabel.first
  respond_to do | wants |
    wants.rdf {
      RDF::RDFXML::Writer.buffer do |writer|
        @collection.each_statement do |statement|
          writer << statement
        end
        writer
      end      
    }
    wants.html { haml :subject, :layout=>:subject_layout }
    wants.nt {@collection.to_ntriples() }
    wants.json {@collection.to_json() }
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
  @results = SearchResult.new(response)
  @title << ": #{params['q']}"
  @results.facet((params['q']||"*:*"),["collection","resourcetype"]) 
  haml :search, :layout=>:search_layout
end

helpers do
  
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
    return @collection[scheme]["http://www.w3.org/2000/01/rdf-schema#label"]
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
    matches.each do | m |
      if m.to_s =~ /^http:\/\/lcsubjects\.org\//
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
    total_results = search_results.results.total_results
    items_per_page = search_results.results.max_results
    offset = search_results.results.start_index
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
  attr_reader :results, :facets
  def initialize(results)
    @results = results
  end

  def parse_facet_response(fcts)
    return unless fcts
    @facets = {}
    fcts["facet_results"]["fields"]['field'].each do |field|
      @facets[field['name']] = []
      next unless field['term']
      field['term'] = [field['term']] if field['term'].is_a?(Hash)
      field['term'].each do |term|        
        @facets[field['name']] << {:term=>term['value'], :number=>term['number'], :uri=>term['search_uri']}
      end
    end
  end  
  
  def facet(terms, fields)
    parse_facet_response(FacetSearch.search(terms, fields))
  end
end

class FacetSearch
  include HTTParty
  base_uri "http://api.talis.com/stores/lcsh-info/services"
  format :xml
  def self.search(terms, fields)
    r = self.get("/facet", :query=>{:query=>terms, :fields=>fields.join(","), :top=>25, :output=>"xml"})
    if r.code == 200      
      r.parsed_response
    end
  end
end