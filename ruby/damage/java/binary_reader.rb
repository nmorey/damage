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
                output.printf("#{indent}if (!pOpts._all) fc.position(#{offset});\n\n") if offset != nil

                output.printf("#{indent}do {\n");
                output.printf("#{indent}\tnbytes = fc.read(#{name});\n")
                output.printf("#{indent}} while(nbytes != -1 && #{name}.hasRemaining());\n\n")
                output.printf("#{indent}if(nbytes == -1 && #{name}.hasRemaining())\n");
                output.printf("#{indent}\tthrow new EOFException(\"Unexpected EOF at offset \" + fc.position());\n")
            end
            module_function :ByteBuffer

            def ParseString(output, indent, dest)
                output.printf("#{indent}{\n")
                output.printf("#{indent}\tByteBuffer str;\n")
                ByteBuffer(output, "str", "#{indent}\t", "4", nil)
                output.printf("#{indent}\tint strLen = str.getInt(0);\n")
                output.printf("#{indent}\tif(strLen > 1){\n")
                output.printf("#{indent}\t\tbyte[] strCopy = new byte[strLen - 1];\n")
                ByteBuffer(output, "str", "#{indent}\t\t", "strLen", nil)
                output.printf("#{indent}\t\tstr.position(0);\n")
                output.printf("#{indent}\t\tstr.get(strCopy);\n")
                output.printf("#{indent}\t\t#{dest} = new String(strCopy, Charset.forName(\"UTF-8\"));\n")
                output.printf("#{indent}\t} else if (strLen == 1) {\n")
                output.printf("#{indent}\t\t#{dest} = \"\";\n")
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
	 */
	public static #{retType} loadFromBinary(FileChannel fc, int offset) throws IOException {
		ParserOptions pOpts = new ParserOptions(true);
		return loadFromBinaryPartial(fc, offset, pOpts);
	}
");

                output.puts("
	/**
	 * Internal: Read a partial ##{retType} class and its children in binary form from an open file.
	 */
	public static #{retType} loadFromBinaryPartial(FileChannel fc, int offset, ParserOptions pOpts) throws IOException {
		int nbytes;
		ByteBuffer in;
");

                indent="\t\t"
                if (entry.attribute == :listable) then
                    output.printf("\t\tjava.util.List<#{params[:class]}> list = new java.util.ArrayList<#{params[:class]}>();\n")
                    output.printf("\t\tdo {\n")
                    indent="\t\t\t"
                end
                output.printf("#{indent}#{params[:class]} obj = new #{params[:class]}();\n")

                ByteBuffer(output, "in", indent, pahole[:size], "offset")

                entry.fields.each() { |field|
                    next if field.target != :both

                    output.printf("\n#{indent}/* Parsing #{field.name} */\n")
                    
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
                            ParseString(output, indent, "obj._#{field.name}")
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
                            output.printf("#{indent}\t\tByteBuffer array;\n")
                            ByteBuffer(output, "array", "#{indent}\t\t", "_len * #{field.type_size}", nil)

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
                            output.printf("#{indent}\t\tfor(int i = 0; i < _len; i++){\n")
                            ParseString(output, "#{indent}\t\t\t", "obj._#{field.name}[i]")
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
                
              entry.fields.each() { |field|
                case field.attribute
                  when :sort
                    output.printf("\t\tobj.sort_#{field.name}_by_#{field.sort_key}();\n")
                  end
                }
		uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
		output.printf("\t\t\tCleanup#{uppercaseLibName}ObjectVisitor.instance.visit(obj);\n");

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
	 * Internal: Read a ##{retType} class and its children in binary form from an open zip file.
	 */
	public static #{retType} loadFromZip(GZIPInputStream zip) throws IOException {
");
                indent="\t\t"
                if (entry.attribute == :listable) then
                    output.printf("\t\tint offset;\n")
                    output.printf("\t\tjava.util.List<#{params[:class]}> list = new java.util.ArrayList<#{params[:class]}>();\n")
                    output.printf("\t\tdo {\n")
                    indent="\t\t\t"
                end
                output.printf("#{indent}#{params[:class]} obj = new #{params[:class]}();\n")
		output.printf("#{indent}ByteBuffer in = null;\n");
		output.printf("#{indent}try {\n");
		output.printf("#{indent}\tin = fillByteBuffer(zip, new byte[#{pahole[:size]}]);\n");
		output.printf("#{indent}} catch (EOFException ex) {\n");
		output.printf("#{indent}\tthrow new EOFException(\"Unexpected EOF while reading #{params[:class]}\");\n");
		output.printf("#{indent}}\n");

                entry.fields.each() { |field|
                    next if field.target != :both

                    output.printf("\n#{indent}/* Parsing #{field.name} */\n")
                    
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
                            output.printf("#{indent}obj._#{field.name} = readString(zip);\n")
                        when :intern
                            output.printf("#{indent}obj._#{field.name}_offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}if(obj._#{field.name}_offset != 0)\n")
                            output.printf("#{indent}\tobj._#{field.name} = #{field.java_type}.loadFromZip(zip);\n")
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
                            output.printf("#{indent}\t\tByteBuffer array = null;\n")
                            output.printf("#{indent}\t\ttry {\n")
                            output.printf("#{indent}\t\t\tarray = fillByteBuffer(zip, new byte[_len*#{field.type_size}]);\n")
                            output.printf("#{indent}\t\t} catch (EOFException ex) {\n")
                            output.printf("#{indent}\t\t\tthrow new EOFException(\"Unexpected EOF while reading #{params[:class]}\");\n")
                            output.printf("#{indent}\t\t}\n")
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
                            output.printf("#{indent}\t\tfor(int i = 0; i < _len; i++){\n")
                            output.printf("#{indent}\t\t\tobj._#{field.name}[i] = readString(zip);\n");
                            output.printf("#{indent}\t\t}\n")
                            output.printf("#{indent}\t} else {\n")
                            output.printf("#{indent}\t\tobj._#{field.name} = null;\n")
                            output.printf("#{indent}\t}\n")
                            output.printf("#{indent}}\n")

                        when :intern
                            output.printf("#{indent}obj._#{field.name}_offset = in.getInt(#{pahole[field.name][:offset]});\n")
                            output.printf("#{indent}if (obj._#{field.name}_offset != 0) {\n")
                            output.printf("#{indent}\tobj._#{field.name} = #{field.java_type}.loadFromZip(zip);\n")
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
                
              entry.fields.each() { |field|
                case field.attribute
                  when :sort
                    output.printf("\t\tobj.sort_#{field.name}_by_#{field.sort_key}();\n")
                  end
                }
		uppercaseLibName = libName.slice(0,1).upcase + libName.slice(1..-1)
		output.printf("\t\t\tCleanup#{uppercaseLibName}ObjectVisitor.instance.visit(obj);\n");

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
                output.printf("\t\tbyte[] header_dVersion = new byte[40];\n")
                output.printf("\t\tByteBuffer in; int nbytes;\n");
                output.printf("\t\tint val;\n\n");
                
                output.printf("\t\tfChanLock.lock(0, Long.MAX_VALUE, readOnly);\n\n");
                ByteBuffer(output, "in", "\t\t", "#{params[:bin_header][:size]}", "0")
                output.printf("\n\t\tval = in.getInt(#{params[:bin_header]["version"][:offset]});\n")
                output.printf("\t\tif(val  != #{params[:version]})\n");
                output.printf("\t\t\tthrow new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format\");\n\n")
                output.printf("\t\tin.position(#{params[:bin_header]["damage_version[41]"][:offset]});\n")
                output.printf("\t\tin.get(header_dVersion);\n")
                output.printf("\t\tString damage_versionStr = new String(header_dVersion, Charset.forName(\"UTF-8\"));\n")

                output.printf("\t\tif(!DAMAGE_VERSION.equals(damage_versionStr))\n")
                output.printf("\t\t\tthrow new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format\");\n\n")

                output.printf("\t\tval = in.getInt(#{params[:bin_header]["length"][:offset]});\n")
                output.printf("\t\tif(val  != file.length())\n");
                output.printf("\t\t\tthrow new IOException(\"Corrupted file. Size does not match header\");\n\n")

                output.printf("\t\t#{retType} obj = loadFromBinaryPartial(fc, #{params[:bin_header][:size]}, pOpts) ;\n")
                output.printf("\t\tfc.close();\n\n");

                output.printf("\t\tif(readOnly){\n");
                output.printf("\t\t\tfChanLock.close();\n");
                output.printf("\t\t\tfileLock.delete();\n");
                output.printf("\t\t}\n")
                output.printf("\t\treturn obj;\n")
                output.printf("\t}\n\n")




                output.puts("
	/**
	 * Read a complete ##{retType} class and its children in binary form from a zip file.
	 */
	public static #{retType} createFromZip(String filename) throws IOException {
		java.io.File file = new java.io.File(filename);
		GZIPInputStream zip = new GZIPInputStream(new FileInputStream(file));
		java.io.File fileLock = new java.io.File(filename + \".lock\");
		FileChannel fChanLock = new RandomAccessFile( fileLock, \"rws\").getChannel();
		byte[] header_dVersion = new byte[40];
		int val;

		fChanLock.lock(0, Long.MAX_VALUE, true);
		ByteBuffer in = null;
		try {
			in = fillByteBuffer(zip, new byte[#{params[:bin_header][:size]}]);
		} catch (EOFException ex) {
			throw new EOFException(\"Unexpected EOF while reading #{retType}\");
		}
		val = in.getInt(#{params[:bin_header]["version"][:offset]});
		if(val  != #{params[:version]})
			throw new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format\");
		in.position(#{params[:bin_header]["damage_version[41]"][:offset]});
		in.get(header_dVersion);
		String damage_versionStr = new String(header_dVersion, Charset.forName(\"UTF-8\"));

		if(!DAMAGE_VERSION.equals(damage_versionStr))
			throw new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format\");

		val = in.getInt(#{params[:bin_header]["length"][:offset]});
		//deactivate this check for zip file - how to resolve it ?
		//if(val  != file.length())
		//	throw new IOException(\"Corrupted file. Size does not match header\");

		#{retType} obj = loadFromZip(zip) ;

		fChanLock.close();
		fileLock.delete();
		return obj;
	}"
);




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
