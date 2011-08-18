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
        require File.dirname(__FILE__) + '/java/header'
        require File.dirname(__FILE__) + '/java/enum'
        require File.dirname(__FILE__) + '/java/alloc'
        require File.dirname(__FILE__) + '/java/binary_reader'
        require File.dirname(__FILE__) + '/java/dump'
        require File.dirname(__FILE__) + '/java/parser_options'
        
        def generate(description, pahole)
            libName = description.config.libname
            outdir = "gen/#{libName}/java/src/"
            description.config.package.split(".").each() { |dir|
                outdir += dir + "/"
            }
            outdir += libName + "/"
            ivisitorOutput = Damage::Files.createAndOpen(outdir, "ISigmaCObjectVisitor.java") 
            ivisitorOutput.puts("package eu.kalray.sigmacDB;
          
/**
 * Visitor (see http://en.wikipedia.org/wiki/Visitor_pattern)
 * @author xraynaud@kalray.eu
 *
 */
public interface ISigmaCObjectVisitor {
  ");
            
            visitorOutput = Damage::Files.createAndOpen(outdir, "DefaultSigmaCObjectVisitor.java")
            visitorOutput.puts("package eu.kalray.sigmacDB;
            
  /**
   * Default Visitor implementation (see http://en.wikipedia.org/wiki/Visitor_pattern)
   * @author xraynaud@kalray.eu
   *
   */
  public class DefaultSigmaCObjectVisitor implements ISigmaCObjectVisitor {
    ");

            description.entries.each(){ |name, entry|
                raise("Missing size info") if pahole.entries[name] == nil
                params = nameToParams(description, name)
                output = Damage::Files.createAndOpen(outdir, "#{params[:class]}.java") 
                Header::write(output, libName, entry, pahole.entries[name], params)
                Enum::write(output, libName, entry, pahole.entries[name], params)
                Alloc::write(output, libName, entry, pahole.entries[name], params)
                BinaryReader::write(output, libName, entry, pahole.entries[name], params)
                Dump::write(output, libName, entry, pahole.entries[name], params)

                ParserOptions::write(description)
                output.puts("\n}\n\n")
                output.close()
                ivisitorOutput.printf("\tpublic void visit(%s obj);\n\n", "#{params[:class]}")
                visitorOutput.printf("\t@Override\n")
                visitorOutput.printf("\tpublic void visit(%s obj) {}\n\n", "#{params[:class]}")
            }
            output = Damage::Files.createAndOpen(outdir, "SigmaCObject.java") 
            output.puts("package eu.kalray.sigmacDB;

import java.util.HashMap;

public abstract class SigmaCObject {

  /**
   * Annotations
   * Developer can put any Object in this map.
   */
  private HashMap<String, Object> m_annotations;

  /**
   * Constructor
   */
  public SigmaCObject() {
  }


  /**
   * Gets the annotation fir the given key.
   */
  public Object getAnnotation(String key) {
    if (m_annotations != null) {
      return m_annotations.get(key);
    }
    return null;
  }

  /**
   * Set an annotation to this SigmaCObject
   * @return the previous one, if any.
   */
  public Object setAnnotation(String key, Object object) {
    if (m_annotations == null) {
      m_annotations = new HashMap<String, Object>();
    }
    return m_annotations.put(key, object);
  }


  /**
   * Each SigmaCObject must implement this method
   */
  public abstract void visit(ISigmaCObjectVisitor v);


}");
 
            output.close();

            ivisitorOutput.puts("}\n");
            visitorOutput.puts("}\n");
            ivisitorOutput.close();
            visitorOutput.close();
            
        end
        module_function :generate

        def nameToParams(description, name)
            params={}
            params[:package] = description.config.package + "." + description.config.libname
            params[:version] = description.config.version
            params[:class] = name.slice(0,1).upcase + name.slice(1..-1)
            return params
        end
        module_function :nameToParams
    end
end
