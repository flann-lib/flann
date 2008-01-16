/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

******************************************************************************/

module tango.text.locale.Collation;

private import tango.text.locale.Core;

version (Windows)
  private import tango.text.locale.Win32;
else version (Posix)
  private import tango.text.locale.Posix;

  /**
  Compares strings using the specified case and cultural comparision rules.
 */
public class StringComparer {

  private static StringComparer invariant_;
  private static StringComparer invariantIgnoreCase_;
  private Culture culture_;
  private bool ignoreCase_;

  static this() {
    invariant_ = new StringComparer(Culture.invariantCulture, false);
    invariantIgnoreCase_ = new StringComparer(Culture.invariantCulture, true);
  }

  /**
    Creates an instance that compares strings using the rules of the specified culture.
    Params:
      culture = A Culture instance whose rules are used to compare strings.
      ignoreCase = true to perform case-insensitive comparisons; false to perform case-sensitive comparisions.
  */
  public this(Culture culture, bool ignoreCase) {
    culture_ = culture;
    ignoreCase_ = ignoreCase;
  }

  /**
    Compares two strings and returns the sort order.
    Returns:
      -1 is strA is less than strB; 0 if strA is equal to strB; 1 if strA is greater than strB.
    Params:
      strA = A string to compare to strB.
      strB = A string to compare to strA.
  */
  public int compare(char[] strA, char[] strB) {
    return nativeMethods.compareString(culture_.id, strA, 0, strA.length, strB, 0, strB.length, ignoreCase_);
  }

  /**
    Indicates whether the two strings are equal.
    Returns:
      true if strA and strB are equal; otherwise, false.
    Params:
      strA = A string to compare to strB.
      strB = A string to compare to strA.
  */
  public bool equals(char[] strA, char[] strB) {
    return (compare(strA, strB) == 0);
  }

  /**
    $(I Property.) Retrieves an instance that performs case-sensitive comparisons using the rules of the current culture.
    Returns:
      A new StringComparer instance.
  */
  public static StringComparer currentCulture() {
    return new StringComparer(Culture.current, false);
  }

  /**
    $(I Property.) Retrieves an instance that performs case-insensitive comparisons using the rules of the current culture.
    Returns:
      A new StringComparer instance.
  */
  public static StringComparer currentCultureIgnoreCase() {
    return new StringComparer(Culture.current, true);
  }

  /**
    $(I Property.) Retrieves an instance that performs case-sensitive comparisons using the rules of the invariant culture.
    Returns:
      A new StringComparer instance.
  */
  public static StringComparer invariantCulture() {
    return invariant_;
  }

  /**
    $(I Property.) Retrieves an instance that performs case-insensitive comparisons using the rules of the invariant culture.
    Returns:
      A new StringComparer instance.
  */
  public static StringComparer invariantCultureIgnoreCase() {
    return invariantIgnoreCase_;
  }

}

/**
  $(I Delegate.) Represents the method that will handle the string comparison.
  Remarks:
    The delegate has the signature $(I int delegate(char[], char[])).
 */
alias int delegate(char[], char[]) StringComparison;

/**
  Sorts strings according to the rules of the specified culture.
 */
public class StringSorter {

  private static StringSorter invariant_;
  private static StringSorter invariantIgnoreCase_;
  private Culture culture_;
  private StringComparison comparison_;

  static this() {
    invariant_ = new StringSorter(StringComparer.invariantCulture);
    invariantIgnoreCase_ = new StringSorter(StringComparer.invariantCultureIgnoreCase);
  }

  /**
    Creates an instance using the specified StringComparer.
    Params:
      comparer = The StringComparer to use when comparing strings. $(I Optional.)
  */
  public this(StringComparer comparer = null) {
    if (comparer is null)
      comparer = StringComparer.currentCulture;
    comparison_ = &comparer.compare;
  }

  /**
    Creates an instance using the specified delegate.
    Params:
      comparison = The delegate to use when comparing strings.
    Remarks:
      The comparison parameter must have the same signature as StringComparison.
  */
  public this(StringComparison comparison) {
    comparison_ = comparison;
  }

  /**
    Sorts all the elements in an array.
    Params:
      array = The array of strings to _sort.
  */
  public void sort(inout char[][] array) {
    sort(array, 0, array.length);
  }

  /**
    Sorts a range of the elements in an array.
    Params:
      array = The array of strings to _sort.
      index = The starting index of the range.
      count = The number of elements in the range.
  */
  public void sort(inout char[][] array, int index, int count) {

    void qsort(int left, int right) {
      do {
        int i = left, j = right;
        char[] pivot = array[left + ((right - left) >> 1)];

        do {
          while (comparison_(array[i], pivot) < 0)
            i++;
          while (comparison_(pivot, array[j]) < 0)
            j--;

          if (i > j)
            break;
          else if (i < j) {
            char[] temp = array[i];
            array[i] = array[j];
            array[j] = temp;
          }

          i++;
          j--;
        } while (i <= j);

        if (j - left <= right - i) {
          if (left < j)
            qsort(left, j);
          left = i;
        }
        else {
          if (i < right)
            qsort(i, right);
          right = j;
        }
      } while (left < right);
    }

    qsort(index, index + (count - 1));
  }

  /**
    $(I Property.) Retrieves an instance that performs a case-sensitive sort using the rules of the current culture.
    Returns: A StringSorter instance.
  */
  public static StringSorter currentCulture() {
    return new StringSorter(StringComparer.currentCulture);
  }

  /**
    $(I Property.) Retrieves an instance that performs a case-insensitive sort using the rules of the current culture.
    Returns: A StringSorter instance.
  */
  public static StringSorter currentCultureIgnoreCase() {
    return new StringSorter(StringComparer.currentCultureIgnoreCase);
  }

  /**
    $(I Property.) Retrieves an instance that performs a case-sensitive sort using the rules of the invariant culture.
    Returns: A StringSorter instance.
  */
  public static StringSorter invariantCulture() {
    return invariant_;
  }

  /**
    $(I Property.) Retrieves an instance that performs a case-insensitive sort using the rules of the invariant culture.
    Returns: A StringSorter instance.
  */
  public static StringSorter invariantCultureIgnoreCase() {
    return invariantIgnoreCase_;
  }

}