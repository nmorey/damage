# Copyright (C) 2011  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Damage
  module Java
    module XMLParser
      def write(description)
        libName = description.config.libname
        outdir="gen/#{description.config.libname}/java/src/"
        description.config.package.split(".").each() { |dir|
          outdir += dir + "/"
        }
        outdir += libName + "/"
        outputC = Damage::Files.createAndOpen(outdir, "XMLParser.java")
        self.genC(outputC, description)
        outputC.close()

      end
      module_function :write

      private

      def genC(output, description)
        libName = description.config.libname
        params = Damage::Java::nameToParams(description, "dummy")
        uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
        output.puts("
package #{params[:package]};

import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Stack;
        
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.DefaultHandler;

/** XML SAX Handler */
public class XMLParser extends DefaultHandler {

    private static class ParsedObject {
        private final #{uppercaseLibName}Object object;
        private String elementQName = null;
        private final Map<String, List<String>> mapOfList = new HashMap<String, List<String>>();

        private ParsedObject(#{uppercaseLibName}Object o) {
             this.object = o;
        }
    }

    private final String dtdPath;
    private final Stack<ParsedObject> stack = new Stack<ParsedObject>();
    private #{uppercaseLibName}Object root;
        
    /**
     * Parses an XML file
     */
    public static #{uppercaseLibName}Object parse(String filename, String pathToDTD) throws javax.xml.parsers.ParserConfigurationException, IOException, SAXException, SAXParseException{
        return parse(new java.io.File(filename), pathToDTD);
    }
    
    /**
     * Parses an XML file
     */
    public static #{uppercaseLibName}Object parse(java.io.File file, String pathToDTD) throws javax.xml.parsers.ParserConfigurationException, IOException, SAXException, SAXParseException{
        SAXParserFactory factory = SAXParserFactory.newInstance();
        SAXParser parser = factory.newSAXParser();
        XMLParser handler = new XMLParser(pathToDTD);
        parser.parse(file, handler);
        return handler.root;
    }

    /**
     * Constructor
     */
     public XMLParser(String dtdPath) {
         this.dtdPath = dtdPath;
     }

     /* (non-Javadoc)
      * @see org.xml.sax.helpers.DefaultHandler#error(org.xml.sax.SAXParseException)
      */
     @Override
     public void error(SAXParseException e) throws SAXException {
       throw e;
     }

     /* (non-Javadoc)
      * @see org.xml.sax.helpers.DefaultHandler#fatalError(org.xml.sax.SAXParseException)
      */
     @Override
     public void fatalError(SAXParseException e) throws SAXException {
       throw e;
     }

     /* (non-Javadoc)
      * @see org.xml.sax.helpers.DefaultHandler#warning(org.xml.sax.SAXParseException)
      */
     @Override
     public void warning(SAXParseException e) throws SAXException {
     }

     /* (non-Javadoc)
      * @see org.xml.sax.helpers.DefaultHandler#resolveEntity(java.lang.String, java.lang.String)
      */
     @Override
     public InputSource resolveEntity(String publicId, String systemId) throws IOException, SAXException {
       return new InputSource(new FileReader(dtdPath + \"/#{description.config.libname}.dtd\"));
     }

    /* (non-Javadoc)
     * @see org.xml.sax.helpers.DefaultHandler#endElement(java.lang.String, java.lang.String, java.lang.String)
     */
    @Override
    public void endElement(String uri, String localName, String qName) throws SAXException {
      stack.peek().object.endElement(this, qName);
    }

    /* (non-Javadoc)
     * @see org.xml.sax.helpers.DefaultHandler#characters(char[], int, int)
     */
    @Override
    public void characters(char[] ch, int start, int length) throws SAXException {
      if (!stack.isEmpty()) {
        ParsedObject po = stack.peek();
        if (po.elementQName != null) {
          List<String> list = po.mapOfList.get(po.elementQName);
          if (list == null) {
            list = new LinkedList<String>();
            po.mapOfList.put(po.elementQName, list);
          }
          list.add(new String(ch,start,length).intern());
        }
      }
    }

    public void endElement() {
      ParsedObject o = stack.pop();
      o.object.createArraysCallback(o.mapOfList);
    }

    public void push(#{uppercaseLibName}Object obj) {
      stack.push(new ParsedObject(obj));
    }

    public #{uppercaseLibName}Object getRoot() {
      return root;
    }

    public void waitForElement(String qName) {
      if (!stack.isEmpty()) {
        stack.peek().elementQName = qName;
      }
    }

    public boolean isWaitingFor(String qName) {
      return (!stack.isEmpty() && qName != null && qName.equals(stack.peek().elementQName));
    }

    /* (non-Javadoc)
     * @see org.xml.sax.helpers.DefaultHandler#startElement(java.lang.String, java.lang.String, java.lang.String, org.xml.sax.Attributes)
     */
    @Override
    public void startElement(String uri, String localName, String qName, Attributes attributes) throws SAXException {
      if (stack.isEmpty()) {
");
        description.entries.each(){ |name, entry|
          params = Damage::Java::nameToParams(description, name)
          output.puts("\t\t/** Parse #{name} structures */");
          output.puts("\t\tif (\"#{name}\".equals(qName)) {\n");
          output.puts("\t\t\troot = #{params[:class]}.createFromXML(this, attributes);\n");
          output.puts("\t\t\treturn;\n");
          output.puts("\t\t}\n");
        }

        output.puts("
      } else {
        stack.peek().object.startElement(this, qName, attributes);
      }
    }
}
");
      end
      module_function :genC
    end
  end
end
