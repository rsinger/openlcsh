require 'json'
class Subject
  require 'platform_client'
#  include DataMapper::Resource
  
#  property :id, Serial
#  property :uri, String
#  property :etag, String
#  property :last_modied, DateTime
#  property :content, Text
  attr_accessor :uri, :pref_label, :editorial_notes, :broader, :narrower, :predicates, :scope_notes, :alt_labels, :json, 
    :same_as, :related, :created, :modified, :in_scheme, :rdfxml
  
  def initialize
    @predicates = {}
    
  end
  
  def self.new_from_platform(response)
    puts response.header['content-type'].inspect
    subject = case response.header['content-type'][0]
    when 'application/json'
      puts "Well, ok, we matched that.."
      self.new_from_json_response(response.body.content)
    when 'application/rdf+xml' then self.new_from_rdfxml_response(response.body.content)
    else nil
    end
    puts subject
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
        puts triple.inspect
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
    

end
