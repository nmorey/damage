module Damage
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

      description.entries.each() {|name, entry|
        has_children = false
        entry.fields.each() {|field|
          has_children = true if  (field.target != :mem  && field.is_attribute != true)
          if (field.attribute == :container) then
            raise("At least two containers with name '#{field.name}' are defined and used differents types. Impossible to generate a DTD") if (containers[field.name] != nil && containers[field.name] != field.data_type)
            containers[field.name] = field.data_type
          end
        }
        strList=[]
        output.printf("<!ELEMENT #{entry.name} ");
        if has_children == true then
          output.printf("(");
          comma=""
          entry.fields.each() {|field|
            case field.qty
            when :single
              maxOccurs = "?"
            when :list
              maxOccurs = "*"
            end
            if ( field.target != :mem && field.is_attribute != true) then
              if field.attribute == :container || field.category == :simple then
                output.printf("#{comma}#{field.name}#{maxOccurs}")
                strList << "<!ELEMENT #{field.name} CDATA \"\">\n"
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
          if ( field.target != :mem && field.is_attribute == true) then
            output.printf("<!ATTLIST #{entry.name} #{field.name} CDATA  \"\">\n")
          end
        }
        if entry.attribute == :top
          output.printf("<!ATTLIST #{entry.name} xsi:noNamespaceSchemaLocation CDATA #IMPLIED>\n");
          output.printf("<!ATTLIST #{entry.name} xmlns:xsi CDATA #IMPLIED>\n");
        end
        output.printf("\n");
        strList.each() { |strEntry|
          output.printf(strEntry)
        }
      }
      containers.each() { |name, type|
        output.printf("<!ELEMENT #{name} (#{type}*)>\n");
      }

    end
    module_function :genDTD
  end
end