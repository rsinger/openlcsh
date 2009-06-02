require 'json'
require 'nokogiri'
class Subject
  require 'platform_client'
#  include DataMapper::Resource
  
#  property :id, Serial
#  property :uri, String
#  property :etag, String
#  property :last_modied, DateTime
#  property :content, Text
  attr_accessor :uri, :pref_label, :editorial_notes, :broader, :narrower, :predicates, :scope_notes, :alt_labels, :json, 
    :same_as, :related, :created, :modified, :in_scheme, :rdfxml, :lcc
  
  def initialize
    @predicates = {}
    
  end
  
  def self.new_from_platform(response)
    subject = case response.header['content-type'][0]
    when 'application/json'
      self.new_from_json_response(response.body.content)
    when 'application/rdf+xml' then self.new_from_rdfxml_response(response.body.content)
    when 'application/rss+xml' then self.new_from_rss_response(response.body.content)
    else nil
    end
    return subject
  end
  
  def self.new_from_rdfxml_response(content)
    skos = self.new
    skos.rdfxml = content
    skos
  end
  
  def self.new_from_json_response(content)
    json = JSON.parse(content)
    return nil if json.empty?
    skos = self.new
    u = json.keys[0]
    skos.uri = u
    skos.json = json
    skos.pref_label = json[u]['http://www.w3.org/2004/02/skos/core#prefLabel'][0]['value']
    skos.predicates[:@pref_label] = 'http://www.w3.org/2004/02/skos/core#prefLabel'
    if json[u]['http://www.w3.org/2004/02/skos/core#editorialNote']
      skos.editorial_notes ||=[] 
      json[u]['http://www.w3.org/2004/02/skos/core#editorialNote'].each do | note |
        skos.editorial_notes << note['value']
      end
    end
    if json[u]['http://www.w3.org/2004/02/skos/core#scopeNote']
      skos.scope_notes ||=[] 
      json[u]['http://www.w3.org/2004/02/skos/core#scopeNote'].each do | note |
        skos.scope_notes << note['value']
      end
    end 
    if json[u]['http://www.w3.org/2004/02/skos/core#altLabel']
      skos.alt_labels ||=[] 
      json[u]['http://www.w3.org/2004/02/skos/core#altLabel'].each do | alt |
        skos.alt_labels << alt['value']
      end
    end 
    if json[u]['http://www.w3.org/2004/02/skos/core#related']
      skos.related ||=[] 
      json[u]['http://www.w3.org/2004/02/skos/core#related'].each do | rel |
        skos.related << rel['value']
      end
    end          
    if json[u]['http://www.w3.org/2002/07/owl#sameAs']
      skos.same_as ||= []
      json[u]['http://www.w3.org/2002/07/owl#sameAs'].each do | same_as |
        skos.same_as << same_as['value']
      end
    end
    if json[u]['http://www.w3.org/2004/02/skos/core#broader']
      skos.broader ||=[]
      json[u]['http://www.w3.org/2004/02/skos/core#broader'].each do | broader |
        skos.broader << broader['value']
      end
    end
    if json[u]['http://www.w3.org/2004/02/skos/core#narrower']
      skos.narrower ||=[]
      json[u]['http://www.w3.org/2004/02/skos/core#narrower'].each do | narrower |
        skos.narrower << narrower['value']
      end
    end    
    if json[u]['http://purl.org/dc/terms/modified']
      skos.modified = DateTime.parse(json[u]['http://purl.org/dc/terms/modified'][0]['value'])
    end
    if json[u]['http://purl.org/dc/terms/created']
      skos.created = Date.parse(json[u]['http://purl.org/dc/terms/created'][0]['value'])
    end    
    if json[u]['http://purl.org/dc/terms/LCC']
      skos.lcc = json[u]['http://purl.org/dc/terms/LCC'][0]['value']
    end    
    if json[u]['http://www.w3.org/2004/02/skos/core#inScheme']
      skos.in_scheme ||=[]
      json[u]['http://www.w3.org/2004/02/skos/core#inScheme'].each do | scheme |
        skos.in_scheme << scheme['value']
      end
    end
    skos
  end

  def to_json
    @json.to_json
  end
  
  def to_ntriples
    ntriples = ''
    @json[@uri].keys.each do | predicate |
      @json[@uri][predicate].each do | triple |
        ntriples << "<#{@uri}> <#{predicate}> "
        if triple['type'] == 'uri'
          ntriples << "<#{triple['value']}>"
        else
          ntriples << "\"#{triple['value']}\""
          if triple['lang']
            ntriples << "@#{triple['lang']}"
          end
          if triple['datatype']
            ntriples << "^^<#{triple['datatype']}>"
          end
        end
        ntriples << " .\n"
      end      
    end
    ntriples
  end
  
  def to_rdfxml
    @rdfxml
  end
  
  def to_rss
    rss = "<rdf:RDF xmlns=\"http://purl.org/rss/1.0/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" "          
    rss << "xmlns:relevance=\"http://a9.com/-/opensearch/extensions/relevance/1.0/\" "
    rss << "xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" "
    rss << "xmlns:owl=\"http://www.w3.org/2002/07/owl#\" "
    rss << "xmlns:os=\"http://a9.com/-/spec/opensearch/1.1/\" " 
    rss << "xmlns:skos=\"http://www.w3.org/2004/02/skos/core#\">"
    rss << "<channel rdf:about=\"#{@uri}\">"
    rss << "<link>#{@uri}</link>"
    rss << "<title>#{@pref_label}</title>"
    rss << "<description>#{@pref_label} as found at:  #{@uri}</description>"
    rss << "<items>"
    rss << "<rdf:Seq><rdf:li rdf:resource=\"#{@uri}\"/></rdf:Seq>"
    rss << "</items>"
    rss << "</channel>"
    rss << "<item rdf:about=\"#{@uri}\">"
    rss << "<title>#{@pref_label}</title>"
    rss << "<link>#{@uri}</link>"
    if @narrower
      @narrower.each do | narrower |
        rss << "<skos:narrower rdf:resource=\"#{narrower}\" />"
      end
    end
    if @broader
      @broader.each do | broader |
        rss << "<skos:broader rdf:resource=\"#{broader}\" />"
      end
    end
    
    if @related
      @related.each do | rel |
        rss << "<skos:related rdf:resource=\"#{rel}\" />"
      end
    end
    rss << "</item>"
    rss << "</rdf:RDF>"
    rss
  end
  
  def self.new_from_rss_response(content)
    results = SearchResult.new
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}
    doc = Nokogiri::XML(content)
    if total = doc.xpath('//rss:channel/os:totalResults', namespaces[:rss].merge(namespaces[:os]))
      results.total_results = total.first.content.to_i
    end
    if items_per_page = doc.xpath('//rss:channel/os:itemsPerPage', namespaces[:rss].merge(namespaces[:os]))
      results.items_per_page = items_per_page.first.content.to_i
    end  
    if offset = doc.xpath('//rss:channel/os:startIndex', namespaces[:rss].merge(namespaces[:os]))
      results.offset = offset.first.content.to_i
    end    
    doc.xpath('//rss:item', namespaces[:rss]).each do | item |
      results << self.new_subject_from_rss_item(item)
    end
    results
  end
  
  def self.new_subject_from_rss_item(item)
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}    
    subj = self.new
    subj.uri = item['about']
    if pl = item.xpath('./skos:prefLabel', namespaces[:skos])
      subj.pref_label = pl.first.content
    end
    item.xpath('./skos:altLabel', namespaces[:skos]).each do | al |
      subj.alt_labels ||=[]
      subj.alt_labels << al.content
    end
    subj    
  end
  
  def self.new_from_augment_service(content)
    related = []
    namespaces = {:os=>{'os'=>'http://a9.com/-/spec/opensearch/1.1/'},:rdf=>{'rdf'=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#'},
      :skos=>{'skos'=>'http://www.w3.org/2004/02/skos/core#'}, :rss=>{'rss'=>'http://purl.org/rss/1.0/'}}
    doc = Nokogiri::XML(content) 
    doc.xpath('//rss:item', namespaces[:rss]).each do | item |
      item.xpath('//skos:Concept', namespaces[:skos]).each do | concept |
        related << self.new_subject_from_rss_item(concept)
      end
    end       
    return related
  end
end
