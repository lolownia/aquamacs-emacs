package jde.wizards;

import java.lang.reflect.Method;
import java.util.Hashtable;
import java.util.Enumeration;

/**
 * Defines a factory for creating  skeleton implementations of 
 * Java interfaces. The factory can be invoked from the command line
 * or from another program. The factory can generate implementations for
 * multiple interfaces when invoked from the command line.
 *
 * Copyright (C) 1998-2004 Eric D. Friedman . All Rights Reserved.
 * Copyright (C) 1998-2002 Paul Kinnucan . All Rights Reserved.
 *
 * $Date: 2006/12/02 00:47:29 $ 
 *
 * InterfaceFactory is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2, or (at
 * your option) any later version.
 *
 * InterfaceFactory is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * To obtain a copy of the GNU General Public License write to the
 * Free Software Foundation, Inc.,  59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.  
 *
 * @author Eric D. Friedman
 * @author Paul Kinnucan
 * @version $Revision: 1.1 $
 */
public class MethodFactory implements ClassRegistry {

  /** Unique storage of the classes to import */
  protected Hashtable imports = new Hashtable();

  /** A factory for generating parameter names */
  protected NameFactory namefactory = null;
  
  /**
   * Constructs a default method factory.
   */
  public MethodFactory() {
    this(new DefaultNameFactory());
  }

  /** 
   * Creates a method factory that uses the specified NameFactory
   * for generating parameter names 
   *
   * @param factory Factory for generating parameter names
   */
  public MethodFactory(NameFactory factory) {
    namefactory = factory;
  }

  /** 
   * Sets the factory for generating parameter names.
   *
   * @param factory Factory for generating parameter names.
   */
  public void setNameFactory(NameFactory factory) {
    namefactory = factory;
  }

  /** 
   * Gets the factory used to generating parameter names for 
   * methods generated by this interface factory.
   *
   * @return Name factory
   */
  public NameFactory getNameFactory() {
    return namefactory;
  }

  /** 
   * Gets a table containing the classes that must be imported to
   * implement an interface generated by this factory.
   *
   * @return Classes required to implement the current interface.
   */
  public Hashtable getImports() {
    return imports;
  }

  /**
   * Return the fully qualified names of classes that
   * need to be imported to compile this interface
   * implementation.
   *
   * @return Class names as elisp list of strings.
   */
  public String getImportsAsList() {
    StringBuffer res = new StringBuffer ("(list ");
    Enumeration i = imports.keys();
    while (i.hasMoreElements()) {
      Class c = (Class) i.nextElement();
      String className = c.getName();
      
      // The class to be imported may be an inner
      // class. The interface implementation qualifies
      // the inner class name with the outer class name.
      // Thus the import statement need only reference the
      // outer class. Therefore remove the inner class
      // name, which is separated from the outer class name
      // by a $.
      int idx = className.indexOf('$');
      if (idx > -1) {
        className = className.substring(0, idx);
      }
      
      res.append ("\"" + className + "\" ");
    }
    res.append (")");
    return res.toString();
  }

  /** 
   * Registers a class that needs to be imported by the interface 
   * implementation generated by this factory. Store the class in the 
   * import hashtable if it passes the shouldImport test.  
   * Arrays have to be handled differently here. 
   *
   * @param register Imported class candidate
   */
  public void registerImport(Class register) {
    if (register.isArray()) {
      try {
        Class cl = register;
        
        while (cl.isArray()) {
          cl = cl.getComponentType();
        }
        
        register = cl;
      } catch (Throwable t) {
        throw new RuntimeException("Caught error walking up an Array object: "
                                   + t);
      }
    }
    
    if (shouldImport(register)) {
      imports.put(register, "");
    }
  }

  /**
   * Tests whether a specified class needs to be imported by the interface
   * implementation generated by this factory.
   * We don't import primitives.
   * 
   * @param c the <code>Class</code> object to be tested
   * @return <code>true</code> if the class should be imported
   */
  private final boolean shouldImport(Class c) {        
    return ! c.isPrimitive();                // import everything else
  }


  /**
   * Array of <code>String</> names of numeric types.
   *
   */
  private String[] numericTypesArray = {"char", "byte",
                                        "short", "int", "long",
                                        "float", "double"};
  
  /**
   * List of names of numeric types.
   *
   */
  private java.util.List numericTypesList =
    java.util.Arrays.asList(numericTypesArray);

  /**
   * Return a default body for the implementation of the method described
   * by <code>sig</code>.
   *
   * @param sig a <code>Signature</code> value
   * @return a <code>String</code> value
   */
  protected String getDefaultBody (Signature sig) {
    Method m = sig.getMethod();
    Class cl = m.getReturnType();
    if (numericTypesList.contains(cl.getName())) {
      return "return 0;";
    } else if (cl.getName().equals("boolean")) {
      return "return false;";
    } else if (!cl.getName().equals("void")) {
      return "return null;";
    }
    return "";
  }

  /**
   * Get a Lisp form that generates a skeleton
   * implementation of a specified method. The
   * List form is of the form
   *
   *   <code>(jde-wiz-gen-method ... )</code>
   *
   * where <code>jde-wiz-gen-method</code> is a
   * function defined by the JDEE's jde-wiz package.
   *
   * @param sig a <code>Signature</code> value
   * @return a <code>String</code> value
   */
  public String getMethodSkeletonExpression (Signature sig)  {
    StringBuffer res = new StringBuffer();

    res.append ("(jde-wiz-gen-method");
    res.append (" \"" + sig.getModifiers() + "\"");
    res.append (" \"" + sig.getReturnBaseType() + "\"");
    res.append (" \"" + sig.getMethod().getName() + "\"");
    res.append (" \"" + sig.getParameters() + "\"");
    res.append (" \"" + sig.getExceptionList() + "\"");
    res.append (" \"" + getDefaultBody (sig) + "\")\n");
    return res.toString();
  }

  /** 
   * Clears the import hashtables for this factory so it
   * can be re-used to process a new set of methods.
   */
  public void flush() {
    imports.clear();
  }

  /**
   * Print a string and flush the output buffer to
   * ensure that the string reaches Emacs immediately.
   *
   * @param s a <code>String</code> value
   */
  public static void println(String s) {
    System.out.print(s + "\n");
    System.out.flush();
  }


} // MethodFactory

/*
 * $Log: MethodFactory.java,v $
 * Revision 1.1  2006/12/02 00:47:29  davidswelt
 * JDE
 *
 * Revision 1.9  2004/10/18 05:11:17  paulk
 * Update copyright.
 *
 * Revision 1.8  2003/09/07 05:29:12  paulk
 * Check for duplicate methods defined by different classes or interfaces.
 * Thanks to Martin Schwamberg.
 *
 * Revision 1.7  2002/12/04 07:16:37  paulk
 * Cosmetic changes.
 *
 * Revision 1.6  2002/12/04 07:06:47  paulk
 * Updated to handle implementation of interfaces that reference inner classes.
 *
 * Revision 1.5  2002/05/14 06:38:44  paulk
 * Enhances code generation wizards for implementing interfaces, abstract
 * classes, etc., to use customizable templates to generate skeleton methods
 * instead of hard-wired skeletons. Thanks to "Dr. Michael Lipp" <lipp@danet.de>
 * for proposing and implementing this improvement.
 *
 * Revision 1.4  2001/08/04 03:24:12  paulk
 * DefaultNameFactory.java
 *
 * Revision 1.3  2001/06/13 04:04:43  paulk
 * Now returns a valid return value for methods that return a value. 
 * Thanks to "Craig McGeachie" <craig@rhe.com.au>.
 *
 */

// End of MethodFactory.java