# -*- coding: undecided -*-
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
                output.printf("#{indent}\t\tif(strLen > 1){\n")
                output.printf("#{indent}\t\t\tstrCopy = new byte[strLen - 1];\n")
                ByteBuffer(output, "str", "#{indent}\t\t\t", "strLen", "strPos+4")
                output.printf("#{indent}\t\t\tstr.position(0);\n")
                output.printf("#{indent}\t\t\tstr.get(strCopy);\n")
                output.printf("#{indent}\t\t\t#{dest} = new String(strCopy, Charset.forName(\"UTF-8\"));\n")
                output.printf("#{indent}\t\t} else {\n")
                output.printf("#{indent}\t\t\t#{dest} = new String(\"\");\n")
                output.printf("#{indent}\t\t}\n")
                output.printf("#{indent}\t} else {\n")
                output.printf("#{indent}\t\t#{dest} = null;\n")
                output.printf("#{indent}\t}\n")
                output.printf("#{indent}}\n")
            end
            module_function :ParseString


            def write(output, libName, entry, pahole, params)
                retType=params[:class]
                retType="java.util.List<#{retType}>" if entry.attribute == :listable 

               output.puts("
/**
 * Internal: Read a complete ##{retType} class and its children in binary form from an open file.
 */");
                output.printf("\tpublic static #{retType} loadFromBinary(FileChannel fc, int offset) throws IOException {\n")
                output.printf("\t\tParserOptions pOpts = new ParserOptions(true);\n")
                output.printf("\t\treturn loadFromBinaryPartial(fc, offset, pOpts);\n")
                output.printf("\t}\n\n");

                output.puts("
/**
 * Internal: Read a partial ##{retType} class and its children in binary form from an open file.
 */");
                output.printf("\tpublic static #{retType} loadFromBinaryPartial(FileChannel fc, int offset, ParserOptions pOpts) throws IOException {\n")

                output.printf("\t\t#{params[:class]} obj;\n")
                output.printf("\t\tByteBuffer in;\n");
                output.printf("\t\tint nbytes;\n");

                indent="\t\t"
                target="obj"
                if (entry.attribute == :listable) then
                    output.printf("\t\tjava.util.List<#{params[:class]}> list = new java.util.ArrayList<#{params[:class]}>();\n")
                    output.printf("\t\tdo {\n")
                    indent="\t\t\t"
                end
#                output.printf("System.out.println(\"Parsing a #{params[:class]} @ \" + offset);\n");
                output.printf("#{indent}obj = new #{params[:class]}();\n")

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
                            output.printf("#{indent}obj._#{field.name}_offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}if((pOpts._#{field.data_type} != false) && (obj._#{field.name}_offset != 0))\n")
                            output.printf("#{indent}\tobj._#{field.name} = #{field.java_type}.loadFromBinaryPartial(fc, obj._#{field.name}_offset, pOpts);\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("#{indent}{\n")
                            output.printf("#{indent}\tint _len = in.getInt(#{pahole[field.name + "Len"][:offset]});\n")
                            output.printf("#{indent}\tif(_len != 0){\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = new #{field.java_type}[_len];\n")
                            output.printf("#{indent}\t\tint arPos = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\t\tByteBuffer array;\n")
                            ByteBuffer(output, "array", "#{indent}\t\t", "_len * #{field.type_size}", "arPos")

                            output.printf("#{indent}\t\tfor(int i = 0; i < _len; i++){\n")
                            case field.java_type
                                when "int"
                                output.printf("#{indent}\t\t\tobj._#{field.name}[i] = array.getInt(i * #{field.type_size});\n")
                                when "long"
                                output.printf("#{indent}\t\t\tobj._#{field.name}[i] = array.getLong(i * #{field.type_size});\n")
                                when "double"
                                output.printf("#{indent}\t\t\tobj._#{field.name}[i] = array.getDouble(i * #{field.type_size});\n")
                            end
                            output.printf("#{indent}\t\t}\n")
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = null;\n")
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}}\n")


                        when :string
                            output.printf("#{indent}{\n")
                            output.printf("#{indent}\tint _len = in.getInt(#{pahole[field.name + "Len"][:offset]});\n")
                            output.printf("#{indent}\tif(_len != 0){\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = new #{field.java_type}[_len];\n")
                            output.printf("#{indent}\t\tint arPos = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}\t\tByteBuffer array;\n")
                            ByteBuffer(output, "array", "#{indent}\t\t", "_len * 4", "arPos")
                            output.printf("#{indent}\t\tfor(int i = 0; i < _len; i++){\n")
                            ParseString(output, "#{indent}\t\t\t", "array", "i * 4", "obj._#{field.name}[i]")
                            output.printf("#{indent}\t\t}\n")
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = null;\n")
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}}\n")

                        when :intern
                            output.printf("#{indent}obj._#{field.name}_offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}if((pOpts._#{field.data_type} != false) && (obj._#{field.name}_offset != 0)){\n")
                            output.printf("#{indent}\tobj._#{field.name} = #{field.java_type}.loadFromBinaryPartial(fc, obj._#{field.name}_offset, pOpts);\n")
                            output.printf("#{indent}} else {\n")
                            output.printf("#{indent}\tobj._#{field.name} = new java.util.ArrayList<#{field.java_type}>();\n")
                            output.printf("#{indent}}\n")
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }

                if entry.attribute == :listable
                    output.printf("#{indent}list.add(obj);\n") 
                    output.printf("#{indent}offset = in.getInt(#{pahole["next"][:offset]});\n");
                    output.printf("\t\t} while (offset != 0);\n") 
                    
                    output.printf("\t\treturn list;\n")
                else
                    output.printf("\t\treturn obj;\n")
                end
                output.printf("\t}\n\n")
                output.puts("
/**
 * Read a complete ##{retType} class and its children in binary form from a file.
 */");

                output.printf("\tpublic static #{retType} createFromBinary(String filename, boolean readOnly) throws IOException {\n")
                output.printf("\t\tParserOptions pOpts = new ParserOptions(true);\n")
                output.printf("\t\treturn createFromBinaryPartial(filename, readOnly, pOpts);\n")
 
                output.printf("\t}\n\n")



                output.puts("
/**
 * Read a partial ##{retType} class and its children in binary form from a file.
 */");

                output.printf("\tpublic static #{retType} createFromBinaryPartial(String filename, boolean readOnly, ParserOptions pOpts) throws IOException {\n")
                output.printf("\t\tRandomAccessFile file = new RandomAccessFile( new java.io.File(filename), \"r\");\n")
                output.printf("\t\tjava.io.File fileLock = new java.io.File(filename + \".lock\");\n")
                output.printf("\t\tFileChannel fc = file.getChannel();\n");
                output.printf("\t\tFileChannel fChanLock = new RandomAccessFile( fileLock, \"rws\").getChannel();\n");
                output.printf("\t\t#{retType} obj = null;\n")
                output.printf("\t\tByteBuffer in; int nbytes;\n");
                output.printf("\t\tint val;\n\n");
                
                output.printf("\t\tfChanLock.lock(0, Long.MAX_VALUE, readOnly);\n\n");
                ByteBuffer(output, "in", "\t\t", "2 * 4", "0")
                output.printf("\n\t\tval = in.getInt(0);\n")
                output.printf("\t\tif(val  != #{params[:version]})\n");
                output.printf("\t\t\tthrow new java.io.UnsupportedEncodingException(\"Incompatible sigmacDB format\");\n\n")

                output.printf("\t\tval = in.getInt(4);\n")
                output.printf("\t\tif(val  != file.length())\n");
                output.printf("\t\t\tthrow new IOException(\"Corrupted file. Size does not match header\");\n\n")

                output.printf("\t\tobj = loadFromBinaryPartial(fc, 8, pOpts) ;\n")
                output.printf("\t\tfc.close();\n\n");

                output.printf("\t\tif(readOnly){\n");
                output.printf("\t\t\tfChanLock.close();\n");
                output.printf("\t\t\tfileLock.delete();\n");
                output.printf("\t\t}\n")
                output.printf("\t\treturn obj;\n")
                output.printf("\t}\n\n")

                output.printf("
\tpublic static void main(String[] args){ 
\t\ttry { 
\t\t\t#{retType} obj = createFromBinary(args[0], true);
");
                if entry.attribute == :listable
                    output.printf("\t\t\tfor(#{params[:class]} el :  obj)\n");
                    output.printf("\t\t\t\tel.dump();\n");
                else
                    output.printf("\t\t\tobj.dump();\n");
                end
output.printf("
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
