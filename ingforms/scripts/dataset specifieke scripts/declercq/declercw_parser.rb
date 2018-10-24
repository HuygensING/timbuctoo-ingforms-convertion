require 'open-uri'
require 'rexml/document'
require 'rexml/streamlistener'
require 'rubygems'
require 'cgi'
#require 'htmlentities'

include REXML


class Parser

    def Parser.parseFile(inputfilename,outputfilename,collection,afk,number)
        listener = MyListener.new(outputfilename,collection,afk,number)
        source = File.new File.expand_path(inputfilename)
        Document.parse_stream(source, listener)
        listener.closing_lines
        source.close
    end

    def Parser.parseString(id,xml,output_file,collection,afk)
        listener = MyListener.new(output_file,collection,afk,1)
        Document.parse_stream(xml, listener)
    end

end


class MyListener
    include StreamListener

    def closing_lines
        rdf_rdf =<<EOF
  </rdf:Description>

EOF
#        @output.puts rdf_rdf
#        @output.puts
    end

    def initialize(outputfile,collection,afk,number)
        @output = outputfile
        @level = 1
        @indent = ""
        @collection = collection
        @afk = afk
        @number = number
        @seq = ""
        @in_datum = false
        @in_dag = false
        @dag = ""
        @in_maand = false
        @maand = ""
        @in_jaar = false
        @jaar = ""
	@in_scan_nr = false
	@scan_nr = ""
    end

    def page_start attrs
        put_out "\n#{@indent}<#{@afk}:page>"
    end

    def page_end
        put_out "</#{@afk}:page>"
    end

    def page_start attrs
        put_out "\n#{@indent}<#{@afk}:page>"
    end

    def page_end
        put_out "</#{@afk}:page>"
    end

    def ingevoerd_door_start attrs
        put_out "\n#{@indent}<#{@afk}:ingevoerd_door>"
    end

    def ingevoerd_door_end
        put_out "</#{@afk}:ingevoerd_door>"
    end

    def jaar_start attrs
        put_out "\n#{@indent}<#{@afk}:jaar>"
    end

    def jaar_end
        put_out "</#{@afk}:jaar>"
    end

    def scannummer_start attrs
        put_out "\n#{@indent}<#{@afk}:scannummer>"
	@in_scan_nr = true
	@scan_nr = ""
    end

    def scannummer_end
        put_out "</#{@afk}:scannummer>"
	put_out "\n<schema:title>#{@scan_nr}</schema:title>"
	@in_scan_nr = false
    end

    def url_start attrs
        put_out "\n#{@indent}<#{@afk}:url>"
    end

    def url_end
        put_out "</#{@afk}:url>"
    end

    def links_of_rechts_start attrs
        put_out "\n#{@indent}<#{@afk}:links_of_rechts>"
    end

    def links_of_rechts_end
        put_out "</#{@afk}:links_of_rechts>"
    end

    def paginanummer_start attrs
        put_out "\n#{@indent}<#{@afk}:paginanummer>"
    end

    def paginanummer_end
        put_out "</#{@afk}:paginanummer>"
    end

    def transcriptie_start attrs
        put_out "\n#{@indent}<#{@afk}:transcriptie rdf:parseType=\"Literal\">"
    end

    def transcriptie_end
        put_out "</#{@afk}:transcriptie>"
    end

    def opmerkingen_start attrs
        put_out "\n#{@indent}<#{@afk}:opmerkingen rdf:parseType=\"Literal\">"
    end

    def opmerkingen_end
        put_out "</#{@afk}:opmerkingen>"
    end

    def table
       	{}
    end

    def tag_start(name,attrs)
        if table.has_key? name
            name = table[name][@level] if table[name].has_key?(@level)
        end
        if table.has_key? name
            name = table[name][0] if table[name][1]==@level
        end
        if @level==1
#            code = "#{name[0].upcase}#{@number}"
            code = sprintf("%s%06d",name[0].upcase,@number)
        lines =<<EOF


  <rdf:Description rdf:about="https://resource.huygens.knaw.nl/ingforms/#{@collection}/#{name}/#{code}">
    <rdf:type rdf:resource="https://resource.huygens.knaw.nl/ingforms/#{@collection}/#{name}" />
EOF
            put_out lines
        else
            begin
                result = self.send( "#{name}_start", attrs )
                rescue => detail
#                    STDERR.puts "#{detail}\nin #{name}"
                end
#            return result
        end
        @level += 1
        @indent = "  " * @level
    end

    def text( text )
        unless text.strip.empty?
	    text.gsub!(/&nbsp;/,"&#160;")
	    text.gsub!(/(\s)&(\s)/,"\\1&amp;\\2")
	    text.gsub!(/([a-zA-Z])&([a-zA-Z])/,"\\1&amp;\\2")
	    text.gsub!(/&amp;amp;/,"&amp;")
	    text.gsub!(/<br ([^>]*)>/,"<br \\1/>")
	    text.gsub!("//>","/>")
	    if @in_jaar
		@jaar = text.strip
	    elsif @in_maand
		@maand = text.strip
	    elsif @in_dag
		@dag = text.strip
	    else
		put_out "#{text.strip}"
	    end
	    @scan_nr = text.strip if @in_scan_nr
#            @text << text
        end
    end

    def tag_end(name)
        if table.has_key? name
            name = table[name][@level-1] if table[name].has_key?(@level-1)
        end
        if @level==2
            @output.puts "\n  </rdf:Description>"
        else
            begin
                result = self.send( "#{name}_end" )
                rescue => detail
#                    STDERR.puts "end: #{detail}\nin #{name}"
                end
#            return result
        end
        @level -= 1
        @indent = "  " * @level
    end

    def put_out( arg )
        @output.write arg
        arg
    end

    def verwerk_datum
        if !@maand.empty?
 	    maand = sprintf("-%02d",@maand.to_i)
        end
        if !@dag.empty?
 	    dag = sprintf("-%02d",@dag.to_i)
        end
        return "#{@jaar}#{maand}#{dag}"
    end

end

def help_message
    STDERR.puts "use: ruby parser -d directory -c collection -o output"
    exit(0)
end

if __FILE__ == $0

    inputfile = ""
    directory = ""
    outputfile = ""
    collection = ""
    # evt aanpassen:
    resource = "https://resource.huygens.knaw.nl/ingforms/const_comm"

    (0..(ARGV.size-1)).each do |i|
        case ARGV[i]
            # voeg start en stop tags toe
            when '-i' then begin inputfile = ARGV[i+1] end
            when '-d' then begin directory = ARGV[i+1] end
            when '-c' then begin collection = ARGV[i+1] end
            when '-o' then begin outputfile = ARGV[i+1] end
            when '-r' then begin resource = ARGV[i+1] end
            when '-h' then begin help_message end
        end
    end

    if directory.empty? || outputfile.empty? || collection.empty?
        help_message
    end

    afk = collection[0]
    output = File.new(outputfile,"w")
    # aanpassen:
    rdf_rdf =<<EOF
<?xml version="1.0"?>
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:#{afk}="https://resource.huygens.knaw.nl/#{collection}/#{afk}"
    xmlns:schema="http://schema.org/"
    xmlns:fc="https://resource.huygens.knaw.nl/constitutionele_commissies/fc"
    xmlns:person="https://resource.huygens.knaw.nl/constitutionele_commissies/person">
EOF

    output.puts rdf_rdf

    if File.directory?(directory)
        number = 1
        wd = Dir.getwd
        Dir.chdir(directory)
        file_list = Dir.glob("**/*.xml")
        file_list.each do |filename|
            #STDERR.puts filename
            Parser.parseFile(filename,output,collection,afk,number)
            number += 1
        end

    end
    
    rdf_rdf =<<EOF

</rdf:RDF>

EOF

    output.puts rdf_rdf
    
end

