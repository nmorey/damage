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
        module BinaryReader
            
            def ByteBuffer(output, name, indent, size, offset)
                output.printf("#{indent}#{name} = ByteBuffer.allocate(#{size});\n")
                output.printf("#{indent}#{name}.order(ByteOrder.LITTLE_ENDIAN);\n")
                output.printf("#{indent}fc.position(#{offset});\n\n")

                output.printf("#{indent}do {\n");
                output.printf("#{indent}\tnbytes = fc.read(#{name});\n")
                output.printf("#{indent}} while(nbytes != -1 && #{name}.hasRemaining());\n\n")
                output.printf("#{indent}if(nbytes == -1 && #{name}.hasRemaining())\n");
                output.printf("#{indent}\tthrow new IOException(\"Unexpected EOF at offset \" + #{offset});\n")
            end
            module_function :ByteBuffer

            def ParseString(output, indent, input, offset, dest)
                output.printf("#{indent}{\n")
                output.printf("#{indent}\tint strPos = #{input}.getInt(#{offset});\n")
                output.printf("#{indent}\tif(strPos != 0){\n")
                output.printf("#{indent}\t\tint strLen;\n")
                output.printf("#{indent}\t\tbyte[] strCopy;\n")
                output.printf("#{indent}\t\tByteBuffer str;\n")
                ByteBuffer(output, "str", "#{indent}\t\t", "4", "strPos")
                output.printf("#{indent}\t\tstrLen = str.getInt(0);\n")
                output.printf("#{indent}\t\tstrCopy = new byte[strLen];\n")
                ByteBuffer(output, "str", "#{indent}\t\t", "strLen", "strPos+4")
                output.printf("#{indent}\t\tstr.position(0);\n")
                output.printf("#{indent}\t\tstr.get(strCopy);\n")
                output.printf("#{indent}\t\t#{dest} = new String(strCopy, Charset.forName(\"UTF-8\"));\n")
                output.printf("#{indent}\t} else {\n")
                output.printf("#{indent}\t\t#{dest} = null;\n")
                output.printf("#{indent}\t}\n")
                output.printf("#{indent}}\n")
            end
            module_function :ParseString


            def write(output, libName, entry, pahole, params)
                output.printf("\tpublic static #{params[:class]} loadFromBinary(FileChannel fc, int offset) throws IOException {\n")
                output.printf("\t\t#{params[:class]} obj;\n")
                output.printf("\t\tByteBuffer in;\n");
                output.printf("\t\tint nbytes;\n");

                indent="\t\t"
                target="obj"
                if (entry.attribute == :listable) then
                    output.printf("\t\t#{params[:class]} first=null, prev=null;\n\n")
                    output.printf("\t\tdo {\n")
                    indent="\t\t\t"
                end
#                output.printf("System.out.println(\"Parsing a #{params[:class]} @ \" + offset);\n");
                output.printf("#{indent}obj = new #{params[:class]}();\n")

                output.printf("\t\t\tif(prev != null){\n\t\t\t\tprev._next = obj;\n\t\t\t} else {\n\t\t\t\tfirst = obj;\n\t\t\t}\n") if entry.attribute == :listable

                ByteBuffer(output, "in", indent, pahole[:size], "offset")

                entry.fields.each() { |field|
                    next if field.target != :both

                    output.printf("\n#{indent}/* Parsing #{field.name} */\n")
#                    output.printf("#{indent}System.out.println(\"Parsing a #{params[:class]}.#{field.name} @ \" + offset + \":#{pahole[field.name][:offset]}\");\n");
                    
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                            case field.java_type
                                when "int"
                                output.printf("#{indent}obj._#{field.name} = in.getInt(#{pahole[field.name][:offset]});\n")
                                when "long"
                                output.printf("#{indent}obj._#{field.name} = in.getLong(#{pahole[field.name][:offset]});\n")
                                when "double"
                                output.printf("#{indent}obj._#{field.name} = in.getDouble(#{pahole[field.name][:offset]});\n")
                            end
                        when :enum
                            output.printf("#{indent}{\n")
                            output.printf("#{indent}\tint _val = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\tobj._#{field.name} = idTo#{field.java_type}(_val);\n")
                            output.printf("#{indent}}\n")

                        when :string
                            ParseString(output, indent, "in", pahole[field.name][:offset], "obj._#{field.name}")
                        when :intern
                            output.printf("#{indent}{\n")
                            output.printf("#{indent}\tint _offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\tif(_offset != 0)\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = #{field.java_type}.loadFromBinary(fc, _offset);\n")
                            output.printf("#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("#{indent}obj._#{field.name}Len = in.getInt(#{pahole[field.name + "Len"][:offset]});\n")
                            output.printf("#{indent}if(obj._#{field.name}Len != 0){\n")
                            output.printf("#{indent}\tobj._#{field.name} = new #{field.java_type}[obj._#{field.name}Len];\n")
                            output.printf("#{indent}\tint arPos = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\tByteBuffer array;\n")
                            ByteBuffer(output, "array", "#{indent}\t", "obj._#{field.name}Len * #{field.type_size}", "arPos")

                            output.printf("#{indent}\tfor(int i = 0; i < obj._#{field.name}Len * #{field.type_size}; i+= #{field.type_size}){\n")
                            case field.java_type
                                when "int"
                                output.printf("#{indent}\t\tobj._#{field.name}[i] = array.getInt(i);\n")
                                when "long"
                                output.printf("#{indent}\t\tobj._#{field.name}[i] = array.getLong(i);\n")
                                when "double"
                                output.printf("#{indent}\t\tobj._#{field.name}[i] = array.getDouble(i);\n")
                            end
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}} else {\n")
                            output.printf("#{indent}\tobj._#{field.name} = new #{field.java_type}[obj._#{field.name}Len];\n")
                            output.printf("#{indent}}\n")


                        when :string
                            output.printf("#{indent}obj._#{field.name}Len = in.getInt(#{pahole[field.name + "Len"][:offset]});\n")
                            output.printf("#{indent}if(obj._#{field.name}Len != 0){\n")
                            output.printf("#{indent}\tobj._#{field.name} = new #{field.java_type}[obj._#{field.name}Len];\n")
                            output.printf("#{indent}\tint arPos = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\tByteBuffer array;\n")
                            ByteBuffer(output, "array", "#{indent}\t", "obj._#{field.name}Len * 4", "arPos")
                            output.printf("#{indent}\tfor(int i = 0; i < obj._#{field.name}Len; i++){\n")
                            ParseString(output, "#{indent}\t\t", "array", "i * 4", "obj._#{field.name}[i]")
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}} else {\n")
                            output.printf("#{indent}\tobj._#{field.name} = null;\n")
                            output.printf("#{indent}}\n")

                        when :intern
                            output.printf("#{indent}{\n")
                            output.printf("#{indent}\tint _offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\tif(_offset != 0)\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = #{field.java_type}.loadFromBinary(fc, _offset);\n")
                            output.printf("#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }

                if entry.attribute == :listable
                    output.printf("#{indent}obj._next = null;\n")
                    output.printf("#{indent}prev = obj;\n") 
                    output.printf("#{indent}offset = in.getInt(#{pahole["next"][:offset]});\n");
                    output.printf("\t\t} while (offset != 0);\n") 
                    
                    output.printf("\t\treturn first;\n")
                else
                    output.printf("\t\treturn obj;\n")
                end
                output.printf("\t}\n\n")
                output.printf("\tpublic static #{params[:class]} createFromBinary(String filename) throws IOException {\n")
                output.printf("\t\tRandomAccessFile file = new RandomAccessFile( new java.io.File(filename), \"r\");\n")
                output.printf("\t\treturn loadFromBinary(file.getChannel(), 4) ;\n")
                output.printf("\t}\n\n")

                output.printf("
\tpublic static void main(String[] args){ 
\t\ttry { 
\t\t\tcreateFromBinary(args[0]);
\t\t} catch (IOException x) {
\t\t\tSystem.out.println(\"I/O Exception: \");
\t\t\tx.printStackTrace();
\t\t}
\t}\n\n")
            end


            module_function :write
        end
    end
end
