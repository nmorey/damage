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
    module XmlReader
      def write(output, libName, entry, pahole, params)
        output.puts("

          /**
           * XML Reader from a file
           */
          static public #{params[:class]} xmlRead(String filename) throws IOException, DocumentException{
             FileInputStream fis = new FileInputStream(filename);
             BufferedInputStream bis = new BufferedInputStream(fis);
             return xmlRead(bis);
          }

          /**
           * XML Reader from a Stream
           */
          static public #{params[:class]} xmlRead(InputStream is) throws IOException, DocumentException {
            Document root = new SAXReader().read(is);
            return xmlRead(root.getRootElement());
          }

          /**
           * XML Reader from an Element
           */
          static public #{params[:class]} xmlRead(Element el) {
            #{params[:class]} obj=new #{params[:class]}();
            obj.populateFromXMLElement(el);
            return obj;
          }

          /**
           * Populate this object (expected virgin object)
           * @param el and XML Element
           */
          @Override
          public void populateFromXMLElement(Element el) {
");
        check = 0
        entry.fields.each() {|field|
          output.printf("\t\ttry {\n");
          case field.attribute
          when :sort
            check = 1
          when :meta
            check = 1
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :single
                check = 1
                output.printf("\t\t\tString tmp = el.attributeValue(\"#{field.name}\");\n");
                output.printf("\t\t\tif (tmp != null) {\n");
                if field.category == :enum then
                  output.printf("\t\t\t\tfor (#{field.java_type} tmp#{field.java_type}: #{field.java_type}.values()) {\n");
                  output.printf("\t\t\t\t\tif (tmp.equals(tmp#{field.java_type}.toString())) {\n");
                  output.printf("\t\t\t\t\t\tthis._#{field.name} = tmp#{field.java_type};\n");
                  output.printf("\t\t\t\t\t\tbreak;\n");
                  output.printf("\t\t\t\t\t}\n");
                  output.printf("\t\t\t\t}\n");
                else
                  case field.java_type
                  when "String"
                    output.printf("\t\t\t\tthis._#{field.name}=tmp.intern();\n")
                  when "int"
                    output.printf("\t\t\t\tthis._#{field.name}=Integer.parseInt(tmp);\n")
                  when "double"
                    output.printf("\t\t\t\tthis._#{field.name}=Double.parseDouble(tmp);\n")
                  when "byte"
                    output.printf("\t\t\t\tthis._#{field.name}=Byte.parseByte(tmp);\n")
                  when "short"
                    output.printf("\t\t\t\tthis._#{field.name}=Short.parseShort(tmp);\n")
                  when "char"
                    output.printf("\t\t\t\tthis._#{field.name}=tmp.charAt(0);\n")
                  when "float"
                    output.printf("\t\t\t\tthis._#{field.name}=Float.parseFloat(tmp);\n")
                  when "long"
                    output.printf("\t\t\t\tthis._#{field.name}=Long.parseLong(tmp);\n")
                  else
                    raise("Unsupported java-type for #{entry.name}.#{field.name}");
                  end
                end
                output.printf("\t\t\t}\n");
              when :list
                check = 1
                output.printf("\t\t\t@SuppressWarnings(\"unchecked\")\n");
                output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
                output.printf("\t\t\tthis._#{field.name}=new #{field.java_type}[tmp.size()];\n");
                output.printf("\t\t\tint count = 0;\n");
                output.printf("\t\t\tfor (Element #{field.name}Element: tmp) {\n");
                output.printf("\t\t\t\tString #{field.name}String = #{field.name}Element.getTextTrim();\n");
                case field.java_type
                when "String"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=#{field.name}String.intern();\n")
                when "int"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Integer.parseInt(#{field.name}String);\n")
                when "double"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Double.parseDouble(#{field.name}String);\n")
                when "byte"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Byte.parseByte(#{field.name}String);\n")
                when "short"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Short.parseShort(#{field.name}String);\n")
                when "char"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=#{field.name}String.charAt(0);\n")
                when "float"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Float.parseFloat(#{field.name}String);\n")
                when "long"
                  output.printf("\t\t\t\tthis._#{field.name}[count++]=Long.parseLong(#{field.name}String);\n")
                else
                  raise("Unsupported java-type for #{entry.name}.#{field.name}");
                end
                output.printf("\t\t\t}\n");
              else
                raise("Unsupported data qty for #{entry.name}.#{field.name}");
              end
            when :intern
              case field.qty
              when :single
                check = 1
                output.printf("\t\t\tElement #{field.name}Element = el.element(\"#{field.name}\");\n");
                output.printf("\t\t\tif (#{field.name}Element != null)\n");
                output.printf("\t\t\t\tthis._#{field.name}=#{field.java_type}.xmlRead(#{field.name}Element);\n");
              when :list, :container
                check = 1
                output.printf("\t\t\t@SuppressWarnings(\"unchecked\")\n");
                if field.attribute == :container
                  output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.element(\"#{field.name}\").elements(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n")
                else
                  output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
                end
                output.printf("\t\t\tthis._#{field.name}=new java.util.ArrayList<#{field.java_type}>(tmp.size());\n");
                output.printf("\t\t\tfor (Element xmlElement: tmp) {\n");
                output.printf("\t\t\t\tthis._#{field.name}.add(#{field.java_type}.xmlRead(xmlElement));\n");
                output.printf("\t\t\t}\n");
              else raise("Unsupported data qty for #{entry.name}.#{field.name}") if field.attribute != :container
              end
            else
              raise("Unsupported data category for #{entry.name}.#{field.name}");
            end
          else
            raise("Unsupported data attribute for #{entry.name}.#{field.name}");
          end
          raise("#{entry.name}.#{field.name} is not manage from java XML reader [qty:#{field.qty},category:#{field.category};attribute:#{field.attribute}]") if (check == 0)
          output.printf("\t\t}\n");
          output.printf("\t\tcatch(Exception ex) {}\n");
        }

        entry.fields.each() {|field|
          case field.attribute
          when :sort
            output.printf("\t\tthis.sort_#{field.name}_by_#{field.sort_key}();\n");
          end
        }

        output.puts("\t\tCleanup#{params[:uppercase_libname]}ObjectVisitor.instance.visit(this);\n");
        output.puts("\t}\n\n");
        #
        # generation of createFromXML methods
        #
        output.puts("
    /**
     * Handler called by XML parser.
     * Create a new #{params[:class]}
     */
    public static #{params[:class]} createFromXML(XMLParser parser, org.xml.sax.Attributes attributes) {
        #{params[:class]} ret = new #{params[:class]}();
        for (int i = attributes.getLength(); i-->0;) {
");
        entry.fields.each() {|field|
          case field.attribute
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :single
                output.printf("\t\t\t/** Reading #{field.name} */\n");
                output.printf("\t\t\tString _#{field.name}_tmp = attributes.getValue(\"#{field.name}\");\n");
                output.printf("\t\t\tif (_#{field.name}_tmp != null) {\n");
                if field.category == :enum then
                  output.printf("\t\t\t\tfor (#{field.java_type} tmp#{field.java_type}: #{field.java_type}.values()) {\n");
                  output.printf("\t\t\t\t\tif (_#{field.name}_tmp.equals(tmp#{field.java_type}.toString())) {\n");
                  output.printf("\t\t\t\t\t\tret._#{field.name} = tmp#{field.java_type};\n");
                  output.printf("\t\t\t\t\t\tbreak;\n");
                  output.printf("\t\t\t\t\t}\n");
                  output.printf("\t\t\t\t}\n");
                else
                  case field.java_type
                  when "String"
                    output.printf("\t\t\t\tret._#{field.name}=_#{field.name}_tmp.intern();\n")
                  when "int"
                    output.printf("\t\t\t\tret._#{field.name}=Integer.parseInt(_#{field.name}_tmp);\n")
                  when "double"
                    output.printf("\t\t\t\tret._#{field.name}=Double.parseDouble(_#{field.name}_tmp);\n")
                  when "byte"
                    output.printf("\t\t\t\tret._#{field.name}=Byte.parseByte(_#{field.name}_tmp);\n")
                  when "short"
                    output.printf("\t\t\t\tret._#{field.name}=Short.parseShort(_#{field.name}_tmp);\n")
                  when "char"
                    output.printf("\t\t\t\tret._#{field.name}=_#{field.name}_tmp.charAt(0);\n")
                  when "float"
                    output.printf("\t\t\t\tret._#{field.name}=Float.parseFloat(_#{field.name}_tmp);\n")
                  when "long"
                    output.printf("\t\t\t\tret._#{field.name}=Long.parseLong(_#{field.name}_tmp);\n")
                  else
                    raise("Unsupported java-type for #{entry.name}.#{field.name}");
                  end
                end
                output.printf("\t\t\t}\n");
              end
            end
          end
        }

        output.puts("\t\t\t}\n");
        output.puts("\t\tparser.push(ret);\n");
        output.puts("\t\treturn ret;\n");
        output.puts("\t}\n\n\n");

        #
        # generation of endElement method
        #
        output.puts("
    /**
     * handler called by XML parser, when this object has been completely read
     */
    public void endElement(XMLParser parser, String qName) {
        if (\"#{params[:name]}\".equals(qName)) {
            parser.endElement();
");
        entry.fields.each() {|field|
          case field.attribute
          when :sort
            output.printf("\t\t\tthis.sort_#{field.name}_by_#{field.sort_key}();\n");
          end
        }
        output.puts("\t\t\tCleanup#{params[:uppercase_libname]}ObjectVisitor.instance.visit(this);
        }
    }
");

        #
        # generation of createArrays method
        #
        output.puts("
    /**
     * handler called by XML parser, when this object has been completely read
     */
    public void createArraysCallback(java.util.Map<String, java.util.List<String>> map) {
");
        entry.fields.each() {|field|
          case field.attribute
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :list
                check = 1
                output.printf("\t\t\tjava.util.List<String> tmp_#{field.name} = map.get(\"#{field.name}\");\n");
                output.printf("\t\t\tif (tmp_#{field.name} == null) tmp_#{field.name} = java.util.Collections.emptyList();\n");
                output.printf("\t\t\tthis._#{field.name} = new #{field.java_type}[tmp_#{field.name}.size()];\n");
                output.printf("\t\t\tint count_#{field.name} = 0;\n");
                output.printf("\t\t\tfor (String #{field.name}String: tmp_#{field.name}) {\n");
                case field.java_type
                when "String"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=#{field.name}String.intern();\n")
                when "int"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Integer.parseInt(#{field.name}String);\n")
                when "double"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Double.parseDouble(#{field.name}String);\n")
                when "byte"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Byte.parseByte(#{field.name}String);\n")
                when "short"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Short.parseShort(#{field.name}String);\n")
                when "char"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=#{field.name}String.charAt(0);\n")
                when "float"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Float.parseFloat(#{field.name}String);\n")
                when "long"
                  output.printf("\t\t\t\tthis._#{field.name}[count_#{field.name}++]=Long.parseLong(#{field.name}String);\n")
                else
                  raise("Unsupported java-type for #{entry.name}.#{field.name}");
                end
                output.printf("\t\t\t}\n");
              end
            end
          end
        }

        output.puts("
    }
");

        #
        # generation of characters method
        #
        output.puts("
    /**
     * handler called by XML parser, to parse sub elements
     */
    public void startElement(XMLParser parser, String qName, org.xml.sax.Attributes attributes) {
");
        entry.fields.each() {|field|
          case field.attribute
          when :sort
            check = 1
          when :meta
            check = 1
          when :container,:none
            case field.category
            when :simple, :enum, :string,:id, :idref
              case field.qty
              when :single
                check = 1
              when :list
                check = 1
                #output.printf("\t\t\t@SuppressWarnings(\"unchecked\")\n");
                #output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.elements(\"#{field.name}\");\n")
                #output.printf("\t\t\tthis._#{field.name}=new #{field.java_type}[tmp.size()];\n");
                #output.printf("\t\t\tint count = 0;\n");
                #output.printf("\t\t\tfor (Element #{field.name}Element: tmp) {\n");
                #output.printf("\t\t\t\tString #{field.name}String = #{field.name}Element.getTextTrim();\n");
                case field.java_type
                when "String"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=#{field.name}String.intern();\n")
                when "int"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Integer.parseInt(#{field.name}String);\n")
                when "double"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Double.parseDouble(#{field.name}String);\n")
                when "byte"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Byte.parseByte(#{field.name}String);\n")
                when "short"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Short.parseShort(#{field.name}String);\n")
                when "char"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=#{field.name}String.charAt(0);\n")
                when "float"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Float.parseFloat(#{field.name}String);\n")
                when "long"
                  #output.printf("\t\t\t\tthis._#{field.name}[count++]=Long.parseLong(#{field.name}String);\n")
                else
                  raise("Unsupported java-type for #{entry.name}.#{field.name}");
                end
                #output.printf("\t\t\t}\n");
              else
                raise("Unsupported data qty for #{entry.name}.#{field.name}");
              end
            when :intern
              case field.qty
              when :single
                check = 1
                output.printf("
        if (\"#{field.name}\".equals(qName)) {
            #{field.java_type} obj = #{field.java_type}.createFromXML(parser, attributes);
            return;
        }
");
              when :list, :container
                check = 1
                output.printf("\t\tif (\"#{field.name}\".equals(qName)) {\n");
                output.printf("\t\t\tif (_#{field.name} == null) _#{field.name} = new ArrayList<#{field.java_type}>();\n");
                if field.attribute == :container
                  # do nothing for now
                  output.printf("\t\t\tparser.waitForElement(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n");
                  #output.printf("\t\t\tjava.util.List<Element> tmp=(java.util.List<Element>)el.element(\"#{field.name}\").elements(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\");\n")
                else
                  output.printf("\t\t\t#{field.java_type} obj = #{field.java_type}.createFromXML(parser, attributes);\n");
                  output.printf("\t\t\t_#{field.name}.add(obj);\n");
                end
                output.printf("\t\t\treturn;\n");
                output.printf("\t\t}\n");

                if field.attribute == :container
                  output.printf("\t\tif (\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\".equals(qName) && parser.isWaitingFor(\"#{field.java_type.slice(0,1).downcase}#{field.java_type.slice(1..-1)}\")) {\n");
                  output.printf("\t\t\t#{field.java_type} obj = #{field.java_type}.createFromXML(parser, attributes);\n");
                  output.printf("\t\t\t_#{field.name}.add(obj);\n");
                  output.printf("\t\t\treturn;\n");
                  output.printf("\t\t}\n");
                end

              else raise("Unsupported data qty for #{entry.name}.#{field.name}") if field.attribute != :container
              end
            else
              raise("Unsupported data category for #{entry.name}.#{field.name}");
            end
          else
            raise("Unsupported data attribute for #{entry.name}.#{field.name}");
          end
          raise("#{entry.name}.#{field.name} is not manage from java XML reader [qty:#{field.qty},category:#{field.category};attribute:#{field.attribute}]") if (check == 0)
        }
        output.puts("\t}\n\n");

      end #def write(output, libName, entry, pahole, params)
      module_function :write

      private
    end
  end
end
