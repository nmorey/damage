# -*- coding: utf-8 -*-
# Copyright (C) 2012  Nicolas Morey-Chaisemartin <nicolas@morey-chaisemartin.com>
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
        module BinaryWriter
            

            def write(output, libName, entry, pahole, params)

                if entry.attribute == :listable then
                    output.puts("\tpublic void writeToBinary(DataOutputStream output) throws IOException {");
                    output.puts("\t\tthis.writeToBinary(output, 0);");
                    output.puts("\t}");
                    output.puts("\tpublic void writeToBinary(DataOutputStream output, int next) throws IOException {");
                else
                    output.puts("\tpublic void writeToBinary(DataOutputStream output) throws IOException {");
                end
output.puts("
        ByteBuffer struct = ByteBuffer.allocate(#{pahole[:size]});
        struct.order(ByteOrder.LITTLE_ENDIAN);
        int cur_offset = this.__binary_offset + #{pahole[:size]};
        struct.putLong(#{pahole["_private"][:offset]}, 0);
        struct.putLong(#{pahole["_rowip_pos"][:offset]}, this.__binary_offset);
");
                output.printf("\t\tstruct.putLong(#{pahole["next"][:offset]}, next);\n") if entry.attribute == :listable

                entry.fields.each() { |field|
                    next if field.target != :both
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                            case field.java_type
                            when "int"
                                output.printf("\t\tstruct.putInt(#{pahole[field.name][:offset]}, this._#{field.name});\n")
                            when "long"
                                output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, this._#{field.name});\n")
                            when "double"
                                output.printf("\t\tstruct.putDouble(#{pahole[field.name][:offset]}, this._#{field.name});\n")
                            end
                        when :enum, :genum
                            output.printf("\t\tstruct.putInt(#{pahole[field.name][:offset]}, this._#{field.name}.ordinal());\n")
                        when :string
                            output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, cur_offset);\n")
                            output.printf("\t\tcur_offset += computeStringLength(this._#{field.name});\n")
                       when :intern
                            output.printf("\t\tif(this._%s != null){\n", field.name)
                            output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, this._#{field.name}.__binary_offset);\n")
                            output.printf("\t\t} else {\n")
                            output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, 0);\n")
                            output.printf("\t\t}\n", field.name)
                        when :raw
                            #Ignore

                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end
                    when :list, :container
                        case field.category
                        when :simple

                            output.printf("\t\tstruct.putInt(#{pahole[field.name + "Len"][:offset]}, this._#{field.name}.length);\n")                         
                            output.printf("\t\tstruct.putInt(#{pahole[field.name][:offset]}, cur_offset);\n")
                            output.printf("\t\tif(this._%s != null){\n", field.name)
                            output.printf("\t\t\tcur_offset += (#{field.type_size} * this._%s.length);\n",
                                          field.name)
                            output.printf("\t\t}\n")

                        when :string
                            output.printf("\t\tstruct.putInt(#{pahole[field.name + "Len"][:offset]}, this._#{field.name}.length);\n")                          
                            output.printf("\t\tstruct.putInt(#{pahole[field.name][:offset]}, cur_offset);\n")
                            output.printf("\t\tcur_offset += computeStringArrayLength(this._#{field.name});\n")


                        when :intern
                            output.printf("\t\tif(this._%s != null && this._%s.size() != 0){\n", field.name, field.name)
                            output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, this._#{field.name}.get(0).__binary_offset);\n")
                            output.printf("\t\t} else {\n")
                            output.printf("\t\tstruct.putLong(#{pahole[field.name][:offset]}, 0);\n")
                            output.printf("\t\t}\n", field.name)
                        when :raw
                            #Ignore

                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
              }
                # Struct is now ready we can write it down ! 
                output.printf("\t\toutput.write(struct.array(), 0, #{pahole[:size]});\n")

                entry.fields.each() { |field|
                    next if field.target != :both
                    next if field.data_type == :intern
                    output.printf("\n\t\t/* Parsing #{field.name} */\n")
                    
                    case field.qty
                    when :single
                        case field.category
                        when :simple
                        when :enum, :genum
                            #Ignore was done inline
                        when :string
                            output.printf("\t\twriteStringToFile(output, this._#{field.name});\n")
                        when :intern
                            #Not possible
                        when :raw
                            #Ignore

                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name} ");
                        end
                    when :list, :container
                        case field.category
                        when :simple
                            output.printf("
        if(this._#{field.name} == null || this._#{field.name}.length == 0){
            output.writeInt(0);
            return;
        } else {
            ByteBuffer _struct =  ByteBuffer.allocate(4);
            struct.order(ByteOrder.LITTLE_ENDIAN);
            struct.putLong(0, this._#{field.name}.length);
            output.write(struct.array(), 0, 4);
            struct =  ByteBuffer.allocate(this._#{field.name}.length * #{field.type_size});
            int i; for(i = 0; i < this._#{field.name}.length; i++){
")
                            case field.java_type
                            when "int"
                                output.printf("\t\t\t\tstruct.putInt(i * #{field.type_size}, this._#{field.name}[i]);\n")
                            when "long"
                                output.printf("\t\t\t\tstruct.putLong(i * #{field.type_size}, this._#{field.name}[i]);\n")
                            when "double"
                                output.printf("\t\t\t\tstruct.putDouble(i * #{field.type_size}, this._#{field.name}[i]);\n")
                            end
                            output.printf("\t\t\t}\n")
                            output.printf("\t\t\t\toutput.write(struct.array(), 0, this._#{field.name}.length * #{field.type_size});\n")
                            output.printf("\t\t}\n")
                        when :string
                          output.printf("\t\twriteStringArrayToFile(output, this._#{field.name});\n")
                        when :raw
                            #Ignore

                        when :intern
                            #Cannot happen
                        else
                            raise("Unsupported data category for #{entry.name}.#{field.name}");
                        end                  
                    else
                        raise("Unsupported quantitiy for #{entry.name}.{field.name}")
                    end
                }
                

            entry.fields.each() { |field|
                next if field.target != :both
                next if field.data_type != :intern
                case field.qty
                when :single
                    output.printf("\t\tif(this._#{field.name}){")
                    output.printf("\t\t\tthis._#{field.name}.writeToBinary(output);")
                    output.printf("\t\t}")
                when :list, :container
                    output.printf("\t\tfor (#{field.java_type} i: _#{field.name}) {\n")
                    output.printf("\t\t\tthis._#{field.name}.writeToBinary(output);")
                    output.printf("\t\t}\n")
               end
            }


                output.printf("\t}\n")



            end

                # output.printf("\tpublic static #{retType} createFromBinaryPartial(String filename, boolean readOnly, ParserOptions pOpts) throws IOException {\n")
                # output.printf("\t\tRandomAccessFile file = new RandomAccessFile( new java.io.File(filename), \"r\");\n")
                # output.printf("\t\tFileChannel fc = file.getChannel();\n");
                # output.printf("\t\tbyte[] header_dVersion = new byte[40];\n")
                # output.printf("\t\tByteBuffer in; int nbytes;\n");
                # output.printf("\t\tint val;\n\n");
                
                # output.printf("\t\tfc.lock(0, Long.MAX_VALUE, readOnly);\n\n");
                # ByteBuffer(output, "in", "\t\t", "#{params[:bin_header][:size]}", "0")
                # output.printf("\n\t\tval = in.getInt(#{params[:bin_header]["version"][:offset]});\n")
                # output.printf("\t\tif(val  != #{params[:version]})\n");
                # output.printf("\t\t\tthrow new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format (got version \" + val + \", expecting #{params[:version]})\");\n\n")

                # output.printf("\t\tin.position(#{params[:bin_header]["damage_version[41]"][:offset]});\n")
                # output.printf("\t\tin.get(header_dVersion);\n")
                # output.printf("\t\tString damage_versionStr = new String(header_dVersion, UTF8_CHARSET);\n")

                # output.printf("\t\tif(!DAMAGE_VERSION.equals(damage_versionStr))\n")
                # output.printf("\t\t\tthrow new java.io.UnsupportedEncodingException(\"Incompatible #{libName} format (got damage_version \" + damage_versionStr + \", expecting \" + DAMAGE_VERSION);\n\n")

                # output.printf("\t\tval = in.getInt(#{params[:bin_header]["length"][:offset]});\n")
                # output.printf("\t\tif(val  != file.length())\n");
                # output.printf("\t\t\tthrow new IOException(\"Corrupted file. Size does not match header\");\n\n")

                # output.printf("\t\t#{retType} obj = loadFromBinaryPartial(fc, #{params[:bin_header][:size]}, pOpts) ;\n")
                # output.printf("\t\tfc.close();\n\n");
                # output.printf("\t\treturn obj;\n")
                # output.printf("\t}\n\n")

            module_function :write
        end
    end
end
