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
        module ParserOptions
            

            def write(description)
                libName = description.config.libname
                outdir="gen/#{description.config.libname}/java/src/"
                description.config.package.split(".").each() { |dir|
                    outdir += dir + "/"
                }
                outdir += libName + "/"
                outputC = Damage::Files.createAndOpen(outdir, "ParserOptions.java")
                self.genC(outputC, description)
                outputC.close()

            end
            module_function :write


            private
            def genC(output, description)
                libName = description.config.libname
                params = Damage::Java::nameToParams(description, "dummy")
                output.puts("
package #{params[:package]};


/** Option for partial binary parser */
public class ParserOptions {
	/** parse all structures */
        public boolean _all;

")

                description.entries.each(){ |name, entry|
                    output.puts("\t/** Parse #{name} structures - if true, no need to seek when reading database*/");
                    output.puts("\tpublic boolean _#{name};\n");
                }
                output.puts("\n\n")

                description.entries.each(){ |name, entry|
                    params = Damage::Java::nameToParams(description, name)

                    output.printf("\t/** Configure the #ParserOption to parse ##{params[:class]} objects and all its children */\n")
                    output.printf("\tpublic void parseComplete#{params[:class]}(){\n")

                    output.printf("\t\tthis._#{entry.name} = true;\n")

                    entry.fields.each() { |field|
                        next if field.target != :both
                        next if field.category != :intern
                        nParams = Damage::Java::nameToParams(description, field.data_type)
                        output.printf("\t\tthis.parseComplete#{nParams[:class]}();\n");
                    }

                    output.printf("\t\treturn;\n")
                    output.printf("\t}\n\n")
                }
                output.printf("\t/** Default constructor. Parse Nothing. */\n")
                output.printf("\tpublic ParserOptions(){\n");
                output.printf("\t	this(false);\n");
                output.printf("\t}\n");



                output.printf("\t/** Constructor with default value. */\n")
                output.printf("\tpublic ParserOptions(boolean val){\n");
		output.printf("\t\t_all = val;\n");
                description.entries.each(){ |name, entry|
                    output.puts("\t\t_#{name} = val;\n");
                }
                output.printf("\t}\n\n")

                
                output.puts("
}
") 
            end
            module_function :genC
        end
    end
end
