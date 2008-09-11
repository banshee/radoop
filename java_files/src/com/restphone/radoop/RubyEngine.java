package com.restphone.radoop;

import java.io.FileNotFoundException;
import java.io.FileReader;

import javax.script.Invocable;
import javax.script.ScriptException;

import org.jruby.RubyArray;
import org.jruby.exceptions.RaiseException;

import com.sun.script.jruby.JRubyScriptEngine;

/**
 * A wrapper around a com.sun.script.jruby.JRubyScriptEngine that provides
 * methods to call Ruby methods.
 * 
 * @author james
 */
public class RubyEngine {
	JRubyScriptEngine rubyEngine;
	Invocable rubyEngineAsInvokable;

	public RubyEngine() throws FileNotFoundException, ScriptException,
			NoSuchMethodException {
		setupRubyEnvironment();
	}

	/**
	 * Sends a message to a Ruby object.
	 * 
	 * @param rubyObject
	 *            The target object
	 * @param message
	 *            The message
	 * @param methodArgs
	 *            Message arguments
	 * @return The result returned from the message
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	public Object send(final Object rubyObject, final String message,
			final Object... methodArgs) throws FileNotFoundException,
			NoSuchMethodException, ScriptException {
		return doBlockWithRubyExceptionWrapper(new RubyBlock() {
			public Object yield() throws FileNotFoundException,
					ScriptException, NoSuchMethodException {
				return rubyEngineAsInvokable.invokeMethod(rubyObject, message,
						methodArgs);
			}
		});
	}

	/**
	 * Calls a Ruby function.
	 * 
	 * Normally this is only used to call methods on Object. There's no way,
	 * using ScriptEngine, to do something like: <code>
	 *   SomeObject.new(:some_key => 'a value)
	 * </code>
	 * <p>
	 * Instead, define a top-level method in Ruby and call that with
	 * callFunction:
	 * <p>
	 * <code>
	 *   def some_convience_method(k, v)
	 *     SomeObject.new(k => v)
	 *   end
	 * </code>
	 * 
	 * @param methodName
	 *            The name of the method
	 * @param methodArgs
	 *            Arguments to the method
	 * @return The result from the Ruby method
	 * @throws FileNotFoundException
	 * @throws ScriptException
	 * @throws NoSuchMethodException
	 */
	public Object callFunction(final String methodName,
			final Object... methodArgs) throws FileNotFoundException,
			ScriptException, NoSuchMethodException {

		return doBlockWithRubyExceptionWrapper(new RubyBlock() {
			public Object yield() throws FileNotFoundException,
					ScriptException, NoSuchMethodException {
				return rubyEngineAsInvokable.invokeFunction(methodName,
						methodArgs);
			}
		});
	}

	/**
	 * Eval a string containing Ruby code.
	 * 
	 * @param s
	 *            The code to eval
	 * @return The result of the code
	 * @throws ScriptException
	 * @throws NoSuchMethodException
	 * @throws FileNotFoundException
	 */
	public Object eval(final String s) throws ScriptException {
		Object result = null;
		try {
			result = doBlockWithRubyExceptionWrapper("eval script " + s,
					new RubyBlock() {
						public Object yield() throws FileNotFoundException,
								ScriptException, NoSuchMethodException {
							return rubyEngine.eval(s);
						}
					});
			// In this case, eval only actually throws ScriptException,
			// we can ignore the other two.
		} catch (FileNotFoundException e) {
		} catch (NoSuchMethodException e) {
		}
		return result;
	}

	/**
	 * Load a .rb file.
	 * 
	 * @param pathname
	 *            The path to the ruby file ("/foo/bar/my_file.rb")
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	public void loadRubyFile(String pathname) throws FileNotFoundException,
			NoSuchMethodException, ScriptException {
		final FileReader rubyFileReader = new FileReader(pathname);

		doBlockWithRubyExceptionWrapper("loading file " + pathname,
				new RubyBlock() {
					public Object yield() throws FileNotFoundException,
							ScriptException, NoSuchMethodException {
						return rubyEngine.eval(rubyFileReader);
					}
				});
	}

	/**
	 * Load multiple Ruby files.
	 * 
	 * @see #loadRubyFile(String pathname)
	 * @param pathnames
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	public void loadRubyFiles(String... pathnames)
			throws FileNotFoundException, NoSuchMethodException,
			ScriptException {
		for (String p : pathnames) {
			loadRubyFile(p);
		}
	}

	/**
	 * 
	 * @return
	 */
	JRubyScriptEngine buildJrubyScriptEngine() {
		JRubyScriptEngine e = new JRubyScriptEngine();
		if (e == null)
			throw new RubyError("new JRubyScriptEngine() failed");
		return e;
	}

	/**
	 * Call a RubyBlock, wrapped with the exception handlers that print out
	 * reasonable backtraces for Ruby exceptions.
	 * 
	 * @param rb
	 *            The block
	 * @return The result from the block
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	Object doBlockWithRubyExceptionWrapper(RubyBlock rb)
			throws FileNotFoundException, NoSuchMethodException,
			ScriptException {
		return doBlockWithRubyExceptionWrapper(null, rb);
	}

	/**
	 * Call a RubyBlock, wrapped with the exception handlers that print out
	 * reasonable backtraces for Ruby exceptions.
	 * 
	 * @param contextMessage
	 *            A message to print at the top of the backtrace
	 * @param rb
	 *            The block
	 * @return The result from the block
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 * @throws ScriptException
	 */
	Object doBlockWithRubyExceptionWrapper(String contextMessage, RubyBlock rb)
			throws FileNotFoundException, NoSuchMethodException,
			ScriptException {
		Object result = null;

		try {
			result = rb.yield();
		} catch (NoSuchMethodException e) {
			printRubyStacktrace(contextMessage, e);
			throw (e);
		} catch (ScriptException e) {
			printRubyStacktrace(contextMessage, e);
			throw (e);
		}

		return result;
	}

	/**
	 * Prints a Ruby backtrace.
	 * 
	 * @param contextMessage
	 *            String to print out before the trace.
	 * 
	 * @param e
	 *            The exception
	 * @return
	 */
	RaiseException printRubyStacktrace(String contextMessage, Exception e) {
		if (contextMessage != null)
			System.err.println("In Ruby context: " + contextMessage);
		return printRubyStacktrace(e);
	}

	/**
	 * Prints a Ruby backtrace.
	 * 
	 * @param e
	 *            The exception
	 * @return
	 */
	RaiseException printRubyStacktrace(Exception e) {
		RaiseException re = (RaiseException) e.getCause();
		return printRubyStacktrace(re);
	}

	/**
	 * Prints a Ruby backtrace.
	 * 
	 * @param re
	 *            The exception
	 * @return
	 */
	RaiseException printRubyStacktrace(RaiseException re) {
		System.err.println(re.getException().getMetaClass() + ":"
				+ re.getException().toString());
		RubyArray rubyStackTrace = (RubyArray) re.getException().backtrace();
		for (Object stackLine : rubyStackTrace) {
			System.err.println("\tat " + stackLine);
		}
		return re;
	}

	/**
	 * Build the JRuby script engine.
	 * 
	 * @throws ScriptException
	 * @throws FileNotFoundException
	 * @throws NoSuchMethodException
	 */
	void setupRubyEnvironment() throws ScriptException, FileNotFoundException,
			NoSuchMethodException {
		rubyEngine = buildJrubyScriptEngine();
		rubyEngineAsInvokable = (Invocable) rubyEngine;
	}

	/**
	 * Used by doBlock* methods.
	 * 
	 * @author james
	 * 
	 */
	interface RubyBlock {
		Object yield() throws FileNotFoundException, ScriptException,
				NoSuchMethodException;
	}
}
