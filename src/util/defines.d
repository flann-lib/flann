module util.defines;

/**
 * It just seems nicer to write string than char[] when
 * working with strings.
 */
alias char[] string;


/**
 * Exception type used thoughout FANN library
 */ 
class FANNException : Exception
{
	this(char[] message) {
		super(message);
	}
}

