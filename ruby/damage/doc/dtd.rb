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
    module Doc
        module DTD


            def write(description)
                output = Damage::Files.createAndOpen("gen/#{description.config.libname}/doc/", "#{description.config.libname}.dtd")
                genDTD(output, description)
                output.close()
            end
            module_function :write

            private
            def genDTD(output, description)

                containers={}
                simpleList={}
                description.entries.each() {|name, entry|

                    strList=[]
                    output.printf("<!ELEMENT #{entry.name} ");
                    if entry.children.length > 0 then
                        output.printf("(");
                        comma=""
                        entry.fields.each() {|field|
                            case field.qty
                            when :single,:container
                                maxOccurs = "?"
                                maxOccurs = "" if field.required == true
                            when :list
                                maxOccurs = "*"
                                maxOccurs = "+" if field.required == true
                            end
                            if ( field.target != :mem && field.is_attribute != true) then
                                if field.attribute == :container || field.category == :simple || field.category == :string then
                                    output.printf("#{comma}#{field.name}#{maxOccurs}")
                                    if (field.category == :simple || field.category == :string) && simpleList[field.name] == nil
                                        strList << "<!ELEMENT #{field.name} (#PCDATA)>\n"
                                    end
                                    simpleList[field.name] = true
                                else
                                    output.printf("#{comma}#{field.data_type}#{maxOccurs}")
                                end
                                comma=", "
                            end
                        } 
                        output.printf(")");
                    else
                        output.printf("EMPTY");
                    end
                    output.printf(">\n", entry.name);


                    entry.fields.each() {|field|
                        required= "#IMPLIED"
                        required= "#REQUIRED" if field.required == true
                        xmlType = "CDATA"
                        xmlType = field.enumList if field.enumList != nil
                        xmlType = "ID" if (field.category == :id)
                        xmlType = "IDREF" if (field.category == :idref)
                        if ( field.target != :mem && field.is_attribute == true) then
                            output.printf("<!ATTLIST #{entry.name} #{field.name} #{xmlType} #{required}>\n")
                        end
                    }
                    if entry.attribute == :top
                        output.printf("<!ATTLIST #{entry.name} xsi:noNamespaceSchemaLocation CDATA #IMPLIED>\n");
                        output.printf("<!ATTLIST #{entry.name} xmlns:xsi CDATA #IMPLIED>\n");
                    end
                    strList.each() { |strEntry|
                        output.printf(strEntry)
                    }
                    output.printf("\n");
                }
                description.containers.each() { |name, type|
                    output.printf("<!ELEMENT #{name} (#{type}*)>\n");
                }

            end
            module_function :genDTD
        end
    end
end
