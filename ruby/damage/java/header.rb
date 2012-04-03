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
      module Header
        def write(output, libName, entry, pahole, params)
         output.puts("
package #{params[:package]};
          
import java.io.Writer;
import java.io.BufferedInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.zip.GZIPInputStream;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.dom.DOMElement;
import org.dom4j.io.SAXReader;

/** Class #{params[:class]}: #{entry.description} */
public class #{params[:class]} extends #{params[:uppercase_libname]}Object {

")
            entry.fields.each() {|field|
                case field.attribute
                when :sort
                    output.printf("\t/** Map of \"#{field.sort_field}\" by #{field.sort_key} */\n")
                    output.printf("\tpublic java.util.HashMap<Integer, #{field.java_type}> _#{field.name}_by_#{field.sort_key};\n")
                when :meta,:container,:none
                    case field.category
                    when :simple, :enum, :string
                        case field.qty
                        when :single
                            if field.category == :enum then
                                output.puts("\t/** Enum for the #{field.name} field of a #{params[:class]} class */");
                                output.printf("\tpublic enum #{field.java_type} {\n");
                                output.printf("\t\tN_A (\"N/A\")/** Undefined */")
                                count = 1;
                                field.enum.each() { |val|
                                    output.printf(",\n\t\t#{val[:label]} (\"#{val[:str]}\")")
                                    count+=1
                                }
                                output.printf(";\n");
                                output.printf("\t\tprivate final String stringValue;\n");
                                output.printf("\t\t#{field.java_type}(String val) {\n");
                                output.printf("\t\t\tthis.stringValue = val;\n");
                                output.printf("\t\t}\n\n");
                                output.printf("\t\t@Override\n");
                                output.printf("\t\tpublic String toString() {\n");
                                output.printf("\t\t\treturn this.stringValue;\n");
                                output.printf("\t\t}\n");
                                output.printf("\n\t}\n\n");
                            end
                            output.printf("\t/** #{field.description} */\n") if field.description != nil
                            output.printf("\t/** Field is an enum of type #{field.name.slice(0,1).upcase}#{field.name.slice(1..-1)}*/\n") if field.category == :enum
                            output.printf("\tpublic %s _%s;\n", field.java_type, field.name)
                        when :list
                            output.printf("\t/** Array of elements #{field.description} */\n")
                            output.printf("\tpublic #{field.java_type}[] _#{field.name};\n")
                        end
                    when :intern
                        output.printf("\t/** #{field.description} */\n") if field.description != nil
                        if field.qty == :single
                            output.printf("\tpublic #{field.java_type} _#{field.name};\n")
                        else
                            output.printf("\tpublic java.util.List<#{field.java_type}> _#{field.name};\n")
                        end
                    else
                        raise("Unsupported data category for #{entry.name}.#{field.name}");
                    end
                else
                    raise("Unsupported data attribute for #{entry.name}.#{field.name}");
                end
            }
            output.printf("\tpublic int __binary_offset;\n");
          output.puts("\n\n");
        end
        module_function :write
        
        private
    end
  end
end
