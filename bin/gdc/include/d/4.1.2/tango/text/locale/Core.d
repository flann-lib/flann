/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: 2005

        author:         John Chapman

        Contains classes that provide information about locales, such as 
        the language and calendars, as well as cultural conventions used 
        for formatting dates, currency and numbers. Use these classes when 
        writing applications for an international audience.

******************************************************************************/

/**
 * $(MEMBERTABLE
 * $(TR
 * $(TH Interface)
 * $(TH Description)
 * )
 * $(TR
 * $(TD $(LINK2 #IFormatService, IFormatService))
 * $(TD Retrieves an object to control formatting.)
 * )
 * )
 *
 * $(MEMBERTABLE
 * $(TR
 * $(TH Class)
 * $(TH Description)
 * )
 * $(TR
 * $(TD $(LINK2 #Calendar, Calendar))
 * $(TD Represents time in week, month and year divisions.)
 * )
 * $(TR
 * $(TD $(LINK2 #Culture, Culture))
 * $(TD Provides information about a culture, such as its name, calendar and date and number format patterns.)
 * )
 * $(TR
 * $(TD $(LINK2 #DateTimeFormat, DateTimeFormat))
 * $(TD Determines how $(LINK2 #Time, Time) values are formatted, depending on the culture.)
 * )
 * $(TR
 * $(TD $(LINK2 #DaylightSavingTime, DaylightSavingTime))
 * $(TD Represents a period of daylight-saving time.)
 * )
 * $(TR
 * $(TD $(LINK2 #Gregorian, Gregorian))
 * $(TD Represents the Gregorian calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #Hebrew, Hebrew))
 * $(TD Represents the Hebrew calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #Hijri, Hijri))
 * $(TD Represents the Hijri calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #Japanese, Japanese))
 * $(TD Represents the Japanese calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #Korean, Korean))
 * $(TD Represents the Korean calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #NumberFormat, NumberFormat))
 * $(TD Determines how numbers are formatted, according to the current culture.)
 * )
 * $(TR
 * $(TD $(LINK2 #Region, Region))
 * $(TD Provides information about a region.)
 * )
 * $(TR
 * $(TD $(LINK2 #Taiwan, Taiwan))
 * $(TD Represents the Taiwan calendar.)
 * )
 * $(TR
 * $(TD $(LINK2 #ThaiBuddhist, ThaiBuddhist))
 * $(TD Represents the Thai Buddhist calendar.)
 * )
 * )
 *
 * $(MEMBERTABLE
 * $(TR
 * $(TH Struct)
 * $(TH Description)
 * )
 * $(TR
 * $(TD $(LINK2 #Time, Time))
 * $(TD Represents time expressed as a date and time of day.)
 * )
 * $(TR
 * $(TD $(LINK2 #TimeSpan, TimeSpan))
 * $(TD Represents a time interval.)
 * )
 * )
 */

module tango.text.locale.Core;

private import  tango.core.Exception;

private import  tango.text.locale.Data;

private import  tango.time.Time;

private import  tango.time.chrono.Hijri,
                tango.time.chrono.Korean,
                tango.time.chrono.Taiwan,
                tango.time.chrono.Hebrew,
                tango.time.chrono.Calendar,
                tango.time.chrono.Japanese,
                tango.time.chrono.Gregorian,
                tango.time.chrono.ThaiBuddhist;
        
version (Windows)
         private import tango.text.locale.Win32;

version (Posix)
         private import tango.text.locale.Posix;


// Initializes an array.
private template arrayOf(T) {
  private T[] arrayOf(T[] params ...) {
    return params.dup;
  }
}


/**
 * Defines the types of cultures that can be retrieved from Culture.getCultures.
 */
public enum CultureTypes {
  Neutral = 1,             /// Refers to cultures that are associated with a language but not specific to a country or region.
  Specific = 2,            /// Refers to cultures that are specific to a country or region.
  All = Neutral | Specific /// Refers to all cultures.
}


/**
 * $(ANCHOR _IFormatService)
 * Retrieves an object to control formatting.
 * 
 * A class implements $(LINK2 #IFormatService_getFormat, getFormat) to retrieve an object that provides format information for the implementing type.
 * Remarks: IFormatService is implemented by $(LINK2 #Culture, Culture), $(LINK2 #NumberFormat, NumberFormat) and $(LINK2 #DateTimeFormat, DateTimeFormat) to provide locale-specific formatting of
 * numbers and date and time values.
 */
public interface IFormatService {

  /**
   * $(ANCHOR IFormatService_getFormat)
   * Retrieves an object that supports formatting for the specified _type.
   * Returns: The current instance if type is the same _type as the current instance; otherwise, null.
   * Params: type = An object that specifies the _type of formatting to retrieve.
   */
  Object getFormat(TypeInfo type);

}

/**
 * $(ANCHOR _Culture)
 * Provides information about a culture, such as its name, calendar and date and number format patterns.
 * Remarks: tango.text.locale adopts the RFC 1766 standard for culture names in the format &lt;language&gt;"-"&lt;region&gt;. 
 * &lt;language&gt; is a lower-case two-letter code defined by ISO 639-1. &lt;region&gt; is an upper-case 
 * two-letter code defined by ISO 3166. For example, "en-GB" is UK English.
 * $(BR)$(BR)There are three types of culture: invariant, neutral and specific. The invariant culture is not tied to
 * any specific region, although it is associated with the English language. A neutral culture is associated with
 * a language, but not with a region. A specific culture is associated with a language and a region. "es" is a neutral 
 * culture. "es-MX" is a specific culture.
 * $(BR)$(BR)Instances of $(LINK2 #DateTimeFormat, DateTimeFormat) and $(LINK2 #NumberFormat, NumberFormat) cannot be created for neutral cultures.
 * Examples:
 * ---
 * import tango.io.Stdout, tango.text.locale.Core;
 *
 * void main() {
 *   Culture culture = new Culture("it-IT");
 *
 *   Stdout.formatln("englishName: {}", culture.englishName);
 *   Stdout.formatln("nativeName: {}", culture.nativeName);
 *   Stdout.formatln("name: {}", culture.name);
 *   Stdout.formatln("parent: {}", culture.parent.name);
 *   Stdout.formatln("isNeutral: {}", culture.isNeutral);
 * }
 *
 * // Produces the following output:
 * // englishName: Italian (Italy)
 * // nativeName: italiano (Italia)
 * // name: it-IT
 * // parent: it
 * // isNeutral: false
 * ---
 */
public class Culture : IFormatService {

  private const int LCID_INVARIANT = 0x007F;

  private static Culture[char[]] namedCultures;
  private static Culture[int] idCultures;
  private static Culture[char[]] ietfCultures;

  private static Culture currentCulture_;
  private static Culture userDefaultCulture_; // The user's default culture (GetUserDefaultLCID).
  private static Culture invariantCulture_; // The invariant culture is associated with the English language.
  private Calendar calendar_;
  private Culture parent_;
  private CultureData* cultureData_;
  private bool isReadOnly_;
  private NumberFormat numberFormat_;
  private DateTimeFormat dateTimeFormat_;

  static this() {
    invariantCulture_ = new Culture(LCID_INVARIANT);
    invariantCulture_.isReadOnly_ = true;

    userDefaultCulture_ = new Culture(nativeMethods.getUserCulture());
    if (userDefaultCulture_ is null)
      // Fallback
      userDefaultCulture_ = invariantCulture;
    else
      userDefaultCulture_.isReadOnly_ = true;
  }

  static ~this() {
    namedCultures = null;
    idCultures = null;
    ietfCultures = null;
  }

  /**
   * Initializes a new Culture instance from the supplied name.
   * Params: cultureName = The name of the Culture.
   */
  public this(char[] cultureName) {
    cultureData_ = CultureData.getDataFromCultureName(cultureName);
  }

  /**
   * Initializes a new Culture instance from the supplied culture identifier.
   * Params: cultureID = The identifer (LCID) of the Culture.
   * Remarks: Culture identifiers correspond to a Windows LCID.
   */
  public this(int cultureID) {
    cultureData_ = CultureData.getDataFromCultureID(cultureID);
  }

  /**
   * Retrieves an object defining how to format the specified type.
   * Params: type = The TypeInfo of the resulting formatting object.
   * Returns: If type is typeid($(LINK2 #NumberFormat, NumberFormat)), the value of the $(LINK2 #Culture_numberFormat, numberFormat) property. If type is typeid($(LINK2 #DateTimeFormat, DateTimeFormat)), the
   * value of the $(LINK2 #Culture_dateTimeFormat, dateTimeFormat) property. Otherwise, null.
   * Remarks: Implements $(LINK2 #IFormatService_getFormat, IFormatService.getFormat).
   */
  public Object getFormat(TypeInfo type) {
    if (type is typeid(NumberFormat))
      return numberFormat;
    else if (type is typeid(DateTimeFormat))
      return dateTimeFormat;
    return null;
  }

version (Clone)
{
  /**
   * Copies the current Culture instance.
   * Returns: A copy of the current Culture instance.
   * Remarks: The values of the $(LINK2 #Culture_numberFormat, numberFormat), $(LINK2 #Culture_dateTimeFormat, dateTimeFormat) and $(LINK2 #Culture_calendar, calendar) properties are copied also.
   */
  public Object clone() {
    Culture culture = cast(Culture)cloneObject(this);
    if (!culture.isNeutral) {
      if (dateTimeFormat_ !is null)
        culture.dateTimeFormat_ = cast(DateTimeFormat)dateTimeFormat_.clone();
      if (numberFormat_ !is null)
        culture.numberFormat_ = cast(NumberFormat)numberFormat_.clone();
    }
    if (calendar_ !is null)
      culture.calendar_ = cast(Calendar)calendar_.clone();
    return culture;
  }
}

  /**
   * Returns a read-only instance of a culture using the specified culture identifier.
   * Params: cultureID = The identifier of the culture.
   * Returns: A read-only culture instance.
   * Remarks: Instances returned by this method are cached.
   */
  public static Culture getCulture(int cultureID) {
    Culture culture = getCultureInternal(cultureID, null);
    if (culture is null)
      error("Culture is not supported.");
    return culture;
  }

  /**
   * Returns a read-only instance of a culture using the specified culture name.
   * Params: cultureName = The name of the culture.
   * Returns: A read-only culture instance.
   * Remarks: Instances returned by this method are cached.
   */
  public static Culture getCulture(char[] cultureName) {
    if (cultureName == null)
       error("Value cannot be null.");
    Culture culture = getCultureInternal(0, cultureName);
    if (culture is null)
      error("Culture name " ~ cultureName ~ " is not supported.");
    return culture;
  }

  /**
    * Returns a read-only instance using the specified name, as defined by the RFC 3066 standard and maintained by the IETF.
    * Params: name = The name of the language.
    * Returns: A read-only culture instance.
    */
  public static Culture getCultureFromIetfLanguageTag(char[] name) {
    if (name == null)
      error("Value cannot be null.");
    Culture culture = getCultureInternal(-1, name);
    if (culture is null)
      error("Culture IETF name " ~ name ~ " is not a known IETF name.");
    return culture;
  }

  private static Culture getCultureInternal(int cultureID, char[] name) {
    // If cultureID is - 1, name is an IETF name; if it's 0, name is a culture name; otherwise, it's a valid LCID.

    // Look up tables first.
    if (cultureID == 0) {
      if (Culture* culture = name in namedCultures)
        return *culture;
    }
    else if (cultureID > 0) {
      if (Culture* culture = cultureID in idCultures)
        return *culture;
    }
    else if (cultureID == -1) {
      if (Culture* culture = name in ietfCultures)
        return *culture;
    }

    // Nothing found, create a new instance.
    Culture culture;

    try {
      if (cultureID == -1) {
        name = CultureData.getCultureNameFromIetfName(name);
        if (name == null)
          return null;
      }
      else if (cultureID == 0)
        culture = new Culture(name);
      else if (userDefaultCulture_ !is null && userDefaultCulture_.id == cultureID) {
        culture = userDefaultCulture_;
      }
      else
        culture = new Culture(cultureID);
    }
    catch (LocaleException) {
      return null;
    }

    culture.isReadOnly_ = true;

    // Now cache the new instance in all tables.
    ietfCultures[culture.ietfLanguageTag] = culture;
    namedCultures[culture.name] = culture;
    idCultures[culture.id] = culture;

    return culture;
  }

  /**
   * Returns a list of cultures filtered by the specified $(LINK2 constants.html#CultureTypes, CultureTypes).
   * Params: types = A combination of CultureTypes.
   * Returns: An array of Culture instances containing cultures specified by types.
   */
  public static Culture[] getCultures(CultureTypes types) {
    bool includeSpecific = (types & CultureTypes.Specific) != 0;
    bool includeNeutral = (types & CultureTypes.Neutral) != 0;

    int[] cultures;
    for (int i = 0; i < CultureData.cultureDataTable.length; i++) {
      if ((CultureData.cultureDataTable[i].isNeutral && includeNeutral) || (!CultureData.cultureDataTable[i].isNeutral && includeSpecific))
        cultures ~= CultureData.cultureDataTable[i].lcid;
    }

    Culture[] result = new Culture[cultures.length];
    foreach (int i, int cultureID; cultures)
      result[i] = new Culture(cultureID);
    return result;
  }

  /**
   * Returns the name of the Culture.
   * Returns: A string containing the name of the Culture in the format &lt;language&gt;"-"&lt;region&gt;.
   */
  public override char[] toString() {
    return cultureData_.name;
  }

  public override int opEquals(Object obj) {
    if (obj is this)
      return true;
    Culture other = cast(Culture)obj;
    if (other is null)
      return false;
    return other.name == name; // This needs to be changed so it's culturally aware.
  }

  /**
   * $(ANCHOR Culture_current)
   * $(I Property.) Retrieves the culture of the current user.
   * Returns: The Culture instance representing the user's current culture.
   */
  public static Culture current() {
    if (currentCulture_ !is null)
      return currentCulture_;

    if (userDefaultCulture_ !is null) {
      // If the user has changed their locale settings since last we checked, invalidate our data.
      if (userDefaultCulture_.id != nativeMethods.getUserCulture())
        userDefaultCulture_ = null;
    }
    if (userDefaultCulture_ is null) {
      userDefaultCulture_ = new Culture(nativeMethods.getUserCulture());
      if (userDefaultCulture_ is null)
        userDefaultCulture_ = invariantCulture;
      else
        userDefaultCulture_.isReadOnly_ = true;
    }

    return userDefaultCulture_;
  }
  /**
   * $(I Property.) Assigns the culture of the _current user.
   * Params: value = The Culture instance representing the user's _current culture.
   * Examples:
   * The following examples shows how to change the _current culture.
   * ---
   * import tango.io.Print, tango.text.locale.Common;
   *
   * void main() {
   *   // Displays the name of the current culture.
   *   Println("The current culture is %s.", Culture.current.englishName);
   *
   *   // Changes the current culture to el-GR.
   *   Culture.current = new Culture("el-GR");
   *   Println("The current culture is now %s.", Culture.current.englishName);
   * }
   *
   * // Produces the following output:
   * // The current culture is English (United Kingdom).
   * // The current culture is now Greek (Greece).
   * ---
   */
  public static void current(Culture value) {
    checkNeutral(value);
    nativeMethods.setUserCulture(value.id);
    currentCulture_ = value;
  }

  /**
   * $(I Property.) Retrieves the invariant Culture.
   * Returns: The Culture instance that is invariant.
   * Remarks: The invariant culture is culture-independent. It is not tied to any specific region, but is associated
   * with the English language.
   */
  public static Culture invariantCulture() {
    return invariantCulture_;
  }

  /**
   * $(I Property.) Retrieves the identifier of the Culture.
   * Returns: The culture identifier of the current instance.
   * Remarks: The culture identifier corresponds to the Windows locale identifier (LCID). It can therefore be used when 
   * interfacing with the Windows NLS functions.
   */
  public int id() {
    return cultureData_.lcid;
  }

  /**
   * $(ANCHOR Culture_name)
   * $(I Property.) Retrieves the name of the Culture in the format &lt;language&gt;"-"&lt;region&gt;.
   * Returns: The name of the current instance. For example, the name of the UK English culture is "en-GB".
   */
  public char[] name() {
    return cultureData_.name;
  }

  /**
   * $(I Property.) Retrieves the name of the Culture in the format &lt;languagename&gt; (&lt;regionname&gt;) in English.
   * Returns: The name of the current instance in English. For example, the englishName of the UK English culture 
   * is "English (United Kingdom)".
   */
  public char[] englishName() {
    return cultureData_.englishName;
  }

  /**
   * $(I Property.) Retrieves the name of the Culture in the format &lt;languagename&gt; (&lt;regionname&gt;) in its native language.
   * Returns: The name of the current instance in its native language. For example, if Culture.name is "de-DE", nativeName is 
   * "Deutsch (Deutschland)".
   */
  public char[] nativeName() {
    return cultureData_.nativeName;
  }

  /**
   * $(I Property.) Retrieves the two-letter language code of the culture.
   * Returns: The two-letter language code of the Culture instance. For example, the twoLetterLanguageName for English is "en".
   */
  public char[] twoLetterLanguageName() {
    return cultureData_.isoLangName;
  }

  /**
   * $(I Property.) Retrieves the three-letter language code of the culture.
   * Returns: The three-letter language code of the Culture instance. For example, the threeLetterLanguageName for English is "eng".
   */
  public char[] threeLetterLanguageName() {
    return cultureData_.isoLangName2;
  }

  /**
   * $(I Property.) Retrieves the RFC 3066 identification for a language.
   * Returns: A string representing the RFC 3066 language identification.
   */
  public final char[] ietfLanguageTag() {
    return cultureData_.ietfTag;
  }

  /**
   * $(I Property.) Retrieves the Culture representing the parent of the current instance.
   * Returns: The Culture representing the parent of the current instance.
   */
  public Culture parent() {
    if (parent_ is null) {
      try {
        int parentCulture = cultureData_.parent;
        if (parentCulture == LCID_INVARIANT)
          parent_ = invariantCulture;
        else
          parent_ = new Culture(parentCulture);
      }
      catch {
        parent_ = invariantCulture;
      }
    }
    return parent_;
  }

  /**
   * $(I Property.) Retrieves a value indicating whether the current instance is a neutral culture.
   * Returns: true is the current Culture represents a neutral culture; otherwise, false.
   * Examples:
   * The following example displays which cultures using Chinese are neutral.
   * ---
   * import tango.io.Print, tango.text.locale.Common;
   *
   * void main() {
   *   foreach (c; Culture.getCultures(CultureTypes.All)) {
   *     if (c.twoLetterLanguageName == "zh") {
   *       Print(c.englishName);
   *       if (c.isNeutral)
   *         Println("neutral");
   *       else
   *         Println("specific");
   *     }
   *   }
   * }
   *
   * // Produces the following output:
   * // Chinese (Simplified) - neutral
   * // Chinese (Taiwan) - specific
   * // Chinese (People's Republic of China) - specific
   * // Chinese (Hong Kong S.A.R.) - specific
   * // Chinese (Singapore) - specific
   * // Chinese (Macao S.A.R.) - specific
   * // Chinese (Traditional) - neutral
   * ---
   */
  public bool isNeutral() {
    return cultureData_.isNeutral;
  }

  /**
   * $(I Property.) Retrieves a value indicating whether the instance is read-only.
   * Returns: true if the instance is read-only; otherwise, false.
   * Remarks: If the culture is read-only, the $(LINK2 #Culture_dateTimeFormat, dateTimeFormat) and $(LINK2 #Culture_numberFormat, numberFormat) properties return 
   * read-only instances.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * $(ANCHOR Culture_calendar)
   * $(I Property.) Retrieves the calendar used by the culture.
   * Returns: A Calendar instance respresenting the calendar used by the culture.
   */
  public Calendar calendar() {
    if (calendar_ is null) {
      calendar_ = getCalendarInstance(cultureData_.calendarType, isReadOnly_);
    }
    return calendar_;
  }

  /**
   * $(I Property.) Retrieves the list of calendars that can be used by the culture.
   * Returns: An array of type Calendar representing the calendars that can be used by the culture.
   */
  public Calendar[] optionalCalendars() {
    Calendar[] cals = new Calendar[cultureData_.optionalCalendars.length];
    foreach (int i, int calID; cultureData_.optionalCalendars)
      cals[i] = getCalendarInstance(calID);
    return cals;
  }

  /**
   * $(ANCHOR Culture_numberFormat)
   * $(I Property.) Retrieves a NumberFormat defining the culturally appropriate format for displaying numbers and currency.
   * Returns: A NumberFormat defining the culturally appropriate format for displaying numbers and currency.
  */
  public NumberFormat numberFormat() {
    checkNeutral(this);
    if (numberFormat_ is null) {
      numberFormat_ = new NumberFormat(cultureData_);
      numberFormat_.isReadOnly_ = isReadOnly_;
    }
    return numberFormat_;
  }
  /**
   * $(I Property.) Assigns a NumberFormat defining the culturally appropriate format for displaying numbers and currency.
   * Params: values = A NumberFormat defining the culturally appropriate format for displaying numbers and currency.
   */
  public void numberFormat(NumberFormat value) {
    checkReadOnly();
    numberFormat_ = value;
  }

  /**
   * $(ANCHOR Culture_dateTimeFormat)
   * $(I Property.) Retrieves a DateTimeFormat defining the culturally appropriate format for displaying dates and times.
   * Returns: A DateTimeFormat defining the culturally appropriate format for displaying dates and times.
   */
  public DateTimeFormat dateTimeFormat() {
    checkNeutral(this);
    if (dateTimeFormat_ is null) {
      dateTimeFormat_ = new DateTimeFormat(cultureData_, calendar);
      dateTimeFormat_.isReadOnly_ = isReadOnly_;
    }
    return dateTimeFormat_;
  }
  /**
   * $(I Property.) Assigns a DateTimeFormat defining the culturally appropriate format for displaying dates and times.
   * Params: values = A DateTimeFormat defining the culturally appropriate format for displaying dates and times.
   */
  public void dateTimeFormat(DateTimeFormat value) {
    checkReadOnly();
    dateTimeFormat_ = value;
  }

  private static void checkNeutral(Culture culture) {
    if (culture.isNeutral)
      error("Culture '" ~ culture.name ~ "' is a neutral culture. It cannot be used in formatting and therefore cannot be set as the current culture.");
  }

  private void checkReadOnly() {
    if (isReadOnly_)
      error("Instance is read-only.");
  }

  private static Calendar getCalendarInstance(int calendarType, bool readOnly=false) {
    switch (calendarType) {
      case Calendar.JAPAN:
        return new Japanese();
      case Calendar.TAIWAN:
        return new Taiwan();
      case Calendar.KOREA:
        return new Korean();
      case Calendar.HIJRI:
        return new Hijri();
      case Calendar.THAI:
        return new ThaiBuddhist();
      case Calendar.HEBREW:
        return new Hebrew;
      case Calendar.GREGORIAN_US:
      case Calendar.GREGORIAN_ME_FRENCH:
      case Calendar.GREGORIAN_ARABIC:
      case Calendar.GREGORIAN_XLIT_ENGLISH:
      case Calendar.GREGORIAN_XLIT_FRENCH:
        return new Gregorian(cast(Gregorian.Type) calendarType);
      default:
        break;
    }
    return new Gregorian();
  }

}

/**
 * $(ANCHOR _Region)
 * Provides information about a region.
 * Remarks: Region does not represent user preferences. It does not depend on the user's language or culture.
 * Examples:
 * The following example displays some of the properties of the Region class:
 * ---
 * import tango.io.Print, tango.text.locale.Common;
 *
 * void main() {
 *   Region region = new Region("en-GB");
 *   Println("name:              %s", region.name);
 *   Println("englishName:       %s", region.englishName);
 *   Println("isMetric:          %s", region.isMetric);
 *   Println("currencySymbol:    %s", region.currencySymbol);
 *   Println("isoCurrencySymbol: %s", region.isoCurrencySymbol);
 * }
 *
 * // Produces the following output.
 * // name:              en-GB
 * // englishName:       United Kingdom
 * // isMetric:          true
 * // currencySymbol:    £
 * // isoCurrencySymbol: GBP
 * ---
 */
public class Region {

  private CultureData* cultureData_;
  private static Region currentRegion_;
  private char[] name_;

  /**
   * Initializes a new Region instance based on the region associated with the specified culture identifier.
   * Params: cultureID = A culture indentifier.
   * Remarks: The name of the Region instance is set to the ISO 3166 two-letter code for that region.
   */
  public this(int cultureID) {
    cultureData_ = CultureData.getDataFromCultureID(cultureID);
    if (cultureData_.isNeutral)
        error ("Cannot use a neutral culture to create a region.");
    name_ = cultureData_.regionName;
  }

  /**
   * $(ANCHOR Region_ctor_name)
   * Initializes a new Region instance based on the region specified by name.
   * Params: name = A two-letter ISO 3166 code for the region. Or, a culture $(LINK2 #Culture_name, _name) consisting of the language and region.
   */
  public this(char[] name) {
    cultureData_ = CultureData.getDataFromRegionName(name);
    name_ = name;
    if (cultureData_.isNeutral)
        error ("The region name " ~ name ~ " corresponds to a neutral culture and cannot be used to create a region.");
  }

  package this(CultureData* cultureData) {
    cultureData_ = cultureData;
    name_ = cultureData.regionName;
  }

  /**
   * $(I Property.) Retrieves the Region used by the current $(LINK2 #Culture, Culture).
   * Returns: The Region instance associated with the current Culture.
   */
  public static Region current() {
    if (currentRegion_ is null)
      currentRegion_ = new Region(Culture.current.cultureData_);
    return currentRegion_;
  }

  /**
   * $(I Property.) Retrieves a unique identifier for the geographical location of the region.
   * Returns: An $(B int) uniquely identifying the geographical location.
   */
  public int geoID() {
    return cultureData_.geoId;
  }

  /**
   * $(ANCHOR Region_name)
   * $(I Property.) Retrieves the ISO 3166 code, or the name, of the current Region.
   * Returns: The value specified by the name parameter of the $(LINK2 #Region_ctor_name, Region(char[])) constructor.
   */
  public char[] name() {
    return name_;
  }

  /**
   * $(I Property.) Retrieves the full name of the region in English.
   * Returns: The full name of the region in English.
   */
  public char[] englishName() {
    return cultureData_.englishCountry;
  }

  /**
   * $(I Property.) Retrieves the full name of the region in its native language.
   * Returns: The full name of the region in the language associated with the region code.
   */
  public char[] nativeName() {
    return cultureData_.nativeCountry;
  }

  /**
   * $(I Property.) Retrieves the two-letter ISO 3166 code of the region.
   * Returns: The two-letter ISO 3166 code of the region.
   */
  public char[] twoLetterRegionName() {
    return cultureData_.regionName;
  }

  /**
   * $(I Property.) Retrieves the three-letter ISO 3166 code of the region.
   * Returns: The three-letter ISO 3166 code of the region.
   */
  public char[] threeLetterRegionName() {
    return cultureData_.isoRegionName;
  }

  /**
   * $(I Property.) Retrieves the currency symbol of the region.
   * Returns: The currency symbol of the region.
   */
  public char[] currencySymbol() {
    return cultureData_.currency;
  }

  /**
   * $(I Property.) Retrieves the three-character currency symbol of the region.
   * Returns: The three-character currency symbol of the region.
   */
  public char[] isoCurrencySymbol() {
    return cultureData_.intlSymbol;
  }

  /**
   * $(I Property.) Retrieves the name in English of the currency used in the region.
   * Returns: The name in English of the currency used in the region.
   */
  public char[] currencyEnglishName() {
    return cultureData_.englishCurrency;
  }

  /**
   * $(I Property.) Retrieves the name in the native language of the region of the currency used in the region.
   * Returns: The name in the native language of the region of the currency used in the region.
   */
  public char[] currencyNativeName() {
    return cultureData_.nativeCurrency;
  }

  /**
   * $(I Property.) Retrieves a value indicating whether the region uses the metric system for measurements.
   * Returns: true is the region uses the metric system; otherwise, false.
   */
  public bool isMetric() {
    return cultureData_.isMetric;
  }

  /**
   * Returns a string containing the ISO 3166 code, or the $(LINK2 #Region_name, name), of the current Region.
   * Returns: A string containing the ISO 3166 code, or the name, of the current Region.
   */
  public override char[] toString() {
    return name_;
  }

}

/**
 * $(ANCHOR _NumberFormat)
 * Determines how numbers are formatted, according to the current culture.
 * Remarks: Numbers are formatted using format patterns retrieved from a NumberFormat instance.
 * This class implements $(LINK2 #IFormatService_getFormat, IFormatService.getFormat).
 * Examples:
 * The following example shows how to retrieve an instance of NumberFormat for a Culture
 * and use it to display number formatting information.
 * ---
 * import tango.io.Print, tango.text.locale.Common;
 *
 * void main(char[][] args) {
 *   foreach (c; Culture.getCultures(CultureTypes.Specific)) {
 *     if (c.twoLetterLanguageName == "en") {
 *       NumberFormat fmt = c.numberFormat;
 *       Println("The currency symbol for %s is '%s'", 
 *         c.englishName, 
 *         fmt.currencySymbol);
 *     }
 *   }
 * }
 *
 * // Produces the following output:
 * // The currency symbol for English (United States) is '$'
 * // The currency symbol for English (United Kingdom) is '£'
 * // The currency symbol for English (Australia) is '$'
 * // The currency symbol for English (Canada) is '$'
 * // The currency symbol for English (New Zealand) is '$'
 * // The currency symbol for English (Ireland) is '€'
 * // The currency symbol for English (South Africa) is 'R'
 * // The currency symbol for English (Jamaica) is 'J$'
 * // The currency symbol for English (Caribbean) is '$'
 * // The currency symbol for English (Belize) is 'BZ$'
 * // The currency symbol for English (Trinidad and Tobago) is 'TT$'
 * // The currency symbol for English (Zimbabwe) is 'Z$'
 * // The currency symbol for English (Republic of the Philippines) is 'Php'
 *---
 */
public class NumberFormat : IFormatService {

  package bool isReadOnly_;
  private static NumberFormat invariantFormat_;

  private int numberDecimalDigits_;
  private int numberNegativePattern_;
  private int currencyDecimalDigits_;
  private int currencyNegativePattern_;
  private int currencyPositivePattern_;
  private int[] numberGroupSizes_;
  private int[] currencyGroupSizes_;
  private char[] numberGroupSeparator_;
  private char[] numberDecimalSeparator_;
  private char[] currencyGroupSeparator_;
  private char[] currencyDecimalSeparator_;
  private char[] currencySymbol_;
  private char[] negativeSign_;
  private char[] positiveSign_;
  private char[] nanSymbol_;
  private char[] negativeInfinitySymbol_;
  private char[] positiveInfinitySymbol_;
  private char[][] nativeDigits_;

  /**
   * Initializes a new, culturally independent instance.
   *
   * Remarks: Modify the properties of the new instance to define custom formatting.
   */
  public this() {
    this(null);
  }

  package this(CultureData* cultureData) {
    // Initialize invariant data.
    numberDecimalDigits_ = 2;
    numberNegativePattern_ = 1;
    currencyDecimalDigits_ = 2;
    numberGroupSizes_ = arrayOf!(int)(3);
    currencyGroupSizes_ = arrayOf!(int)(3);
    numberGroupSeparator_ = ",";
    numberDecimalSeparator_ = ".";
    currencyGroupSeparator_ = ",";
    currencyDecimalSeparator_ = ".";
    currencySymbol_ = "\u00A4";
    negativeSign_ = "-";
    positiveSign_ = "+";
    nanSymbol_ = "NaN";
    negativeInfinitySymbol_ = "-Infinity";
    positiveInfinitySymbol_ = "Infinity";
    nativeDigits_ = arrayOf!(char[])("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");

    if (cultureData !is null && cultureData.lcid != Culture.LCID_INVARIANT) {
      // Initialize culture-specific data.
      numberDecimalDigits_ = cultureData.digits;
      numberNegativePattern_ = cultureData.negativeNumber;
      currencyDecimalDigits_ = cultureData.currencyDigits;
      currencyNegativePattern_ = cultureData.negativeCurrency;
      currencyPositivePattern_ = cultureData.positiveCurrency;
      numberGroupSizes_ = cultureData.grouping;
      currencyGroupSizes_ = cultureData.monetaryGrouping;
      numberGroupSeparator_ = cultureData.thousand;
      numberDecimalSeparator_ = cultureData.decimal;
      currencyGroupSeparator_ = cultureData.monetaryThousand;
      currencyDecimalSeparator_ = cultureData.monetaryDecimal;
      currencySymbol_ = cultureData.currency;
      negativeSign_ = cultureData.negativeSign;
      positiveSign_ = cultureData.positiveSign;
      nanSymbol_ = cultureData.nan;
      negativeInfinitySymbol_ = cultureData.negInfinity;
      positiveInfinitySymbol_ = cultureData.posInfinity;
      nativeDigits_ = cultureData.nativeDigits;
    }
  }

  /**
   * Retrieves an object defining how to format the specified type.
   * Params: type = The TypeInfo of the resulting formatting object.
   * Returns: If type is typeid($(LINK2 #NumberFormat, NumberFormat)), the current NumberFormat instance. Otherwise, null.
   * Remarks: Implements $(LINK2 #IFormatService_getFormat, IFormatService.getFormat).
   */
  public Object getFormat(TypeInfo type) {
    return (type is typeid(NumberFormat)) ? this : null;
  }

version (Clone)
{
  /**
   * Creates a copy of the instance.
   */
  public Object clone() {
    NumberFormat copy = cast(NumberFormat)cloneObject(this);
    copy.isReadOnly_ = false;
    return copy;
  }
}

  /**
   * Retrieves the NumberFormat for the specified $(LINK2 #IFormatService, IFormatService).
   * Params: formatService = The IFormatService used to retrieve NumberFormat.
   * Returns: The NumberFormat for the specified IFormatService.
   * Remarks: The method calls $(LINK2 #IFormatService_getFormat, IFormatService.getFormat) with typeof(NumberFormat). If formatService is null,
   * then the value of the current property is returned.
   */
  public static NumberFormat getInstance(IFormatService formatService) {
    Culture culture = cast(Culture)formatService;
    if (culture !is null) {
      if (culture.numberFormat_ !is null)
        return culture.numberFormat_;
      return culture.numberFormat;
    }
    if (NumberFormat numberFormat = cast(NumberFormat)formatService)
      return numberFormat;
    if (formatService !is null) {
      if (NumberFormat numberFormat = cast(NumberFormat)(formatService.getFormat(typeid(NumberFormat))))
        return numberFormat;
    }
    return current;
  }

  /**
   * $(I Property.) Retrieves a read-only NumberFormat instance from the current culture.
   * Returns: A read-only NumberFormat instance from the current culture.
   */
  public static NumberFormat current() {
    return Culture.current.numberFormat;
  }

  /**
   * $(ANCHOR NumberFormat_invariantFormat)
   * $(I Property.) Retrieves the read-only, culturally independent NumberFormat instance.
   * Returns: The read-only, culturally independent NumberFormat instance.
   */
  public static NumberFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new NumberFormat;
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  /**
   * $(I Property.) Retrieves a value indicating whether the instance is read-only.
   * Returns: true if the instance is read-only; otherwise, false.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * $(I Property.) Retrieves the number of decimal places used for numbers.
   * Returns: The number of decimal places used for numbers. For $(LINK2 #NumberFormat_invariantFormat, invariantFormat), the default is 2.
   */
  public final int numberDecimalDigits() {
    return numberDecimalDigits_;
  }
  /**
   * Assigns the number of decimal digits used for numbers.
   * Params: value = The number of decimal places used for numbers.
   * Throws: Exception if the property is being set and the instance is read-only.
   * Examples:
   * The following example shows the effect of changing numberDecimalDigits.
   * ---
   * import tango.io.Print, tango.text.locale.Common;
   *
   * void main() {
   *   // Get the NumberFormat from the en-GB culture.
   *   NumberFormat fmt = (new Culture("en-GB")).numberFormat;
   *
   *   // Display a value with the default number of decimal digits.
   *   int n = 5678;
   *   Println(Formatter.format(fmt, "{0:N}", n));
   *
   *   // Display the value with six decimal digits.
   *   fmt.numberDecimalDigits = 6;
   *   Println(Formatter.format(fmt, "{0:N}", n));
   * }
   *
   * // Produces the following output:
   * // 5,678.00
   * // 5,678.000000
   * ---
   */
  public final void numberDecimalDigits(int value) {
    checkReadOnly();
    numberDecimalDigits_ = value;
  }

  /**
   * $(I Property.) Retrieves the format pattern for negative numbers.
   * Returns: The format pattern for negative numbers. For invariantFormat, the default is 1 (representing "-n").
   * Remarks: The following table shows valid values for this property.
   *
   * <table class="definitionTable">
   * <tr><th>Value</th><th>Pattern</th></tr>
   * <tr><td>0</td><td>(n)</td></tr>
   * <tr><td>1</td><td>-n</td></tr>
   * <tr><td>2</td><td>- n</td></tr>
   * <tr><td>3</td><td>n-</td></tr>
   * <tr><td>4</td><td>n -</td></tr>
   * </table>
   */
  public final int numberNegativePattern() {
    return numberNegativePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for negative numbers.
   * Params: value = The format pattern for negative numbers.
   * Examples:
   * The following example shows the effect of the different patterns.
   * ---
   * import tango.io.Print, tango.text.locale.Common;
   *
   * void main() {
   *   NumberFormat fmt = new NumberFormat;
   *   int n = -5678;
   *
   *   // Display the default pattern.
   *   Println(Formatter.format(fmt, "{0:N}", n));
   *
   *   // Display all patterns.
   *   for (int i = 0; i <= 4; i++) {
   *     fmt.numberNegativePattern = i;
   *     Println(Formatter.format(fmt, "{0:N}", n));
   *   }
   * }
   *
   * // Produces the following output:
   * // (5,678.00)
   * // (5,678.00)
   * // -5,678.00
   * // - 5,678.00
   * // 5,678.00-
   * // 5,678.00 -
   * ---
   */
  public final void numberNegativePattern(int value) {
    checkReadOnly();
    numberNegativePattern_ = value;
  }

  /**
   * $(I Property.) Retrieves the number of decimal places to use in currency values.
   * Returns: The number of decimal digits to use in currency values.
   */
  public final int currencyDecimalDigits() {
    return currencyDecimalDigits_;
  }
  /**
   * $(I Property.) Assigns the number of decimal places to use in currency values.
   * Params: value = The number of decimal digits to use in currency values.
   */
  public final void currencyDecimalDigits(int value) {
    checkReadOnly();
    currencyDecimalDigits_ = value;
  }

  /**
   * $(I Property.) Retrieves the formal pattern to use for negative currency values.
   * Returns: The format pattern to use for negative currency values.
   */
  public final int currencyNegativePattern() {
    return currencyNegativePattern_;
  }
  /**
   * $(I Property.) Assigns the formal pattern to use for negative currency values.
   * Params: value = The format pattern to use for negative currency values.
   */
  public final void currencyNegativePattern(int value) {
    checkReadOnly();
    currencyNegativePattern_ = value;
  }

  /**
   * $(I Property.) Retrieves the formal pattern to use for positive currency values.
   * Returns: The format pattern to use for positive currency values.
   */
  public final int currencyPositivePattern() {
    return currencyPositivePattern_;
  }
  /**
   * $(I Property.) Assigns the formal pattern to use for positive currency values.
   * Returns: The format pattern to use for positive currency values.
   */
  public final void currencyPositivePattern(int value) {
    checkReadOnly();
    currencyPositivePattern_ = value;
  }

  /**
   * $(I Property.) Retrieves the number of digits int each group to the left of the decimal place in numbers.
   * Returns: The number of digits int each group to the left of the decimal place in numbers.
   */
  public final int[] numberGroupSizes() {
    return numberGroupSizes_;
  }
  /**
   * $(I Property.) Assigns the number of digits int each group to the left of the decimal place in numbers.
   * Params: value = The number of digits int each group to the left of the decimal place in numbers.
   */
  public final void numberGroupSizes(int[] value) {
    checkReadOnly();
    numberGroupSizes_ = value;
  }

  /**
   * $(I Property.) Retrieves the number of digits int each group to the left of the decimal place in currency values.
   * Returns: The number of digits int each group to the left of the decimal place in currency values.
   */
  public final int[] currencyGroupSizes() {
    return currencyGroupSizes_;
  }
  /**
   * $(I Property.) Assigns the number of digits int each group to the left of the decimal place in currency values.
   * Params: value = The number of digits int each group to the left of the decimal place in currency values.
   */
  public final void currencyGroupSizes(int[] value) {
    checkReadOnly();
    currencyGroupSizes_ = value;
  }

  /**
   * $(I Property.) Retrieves the string separating groups of digits to the left of the decimal place in numbers.
   * Returns: The string separating groups of digits to the left of the decimal place in numbers. For example, ",".
   */
  public final char[] numberGroupSeparator() {
    return numberGroupSeparator_;
  }
  /**
   * $(I Property.) Assigns the string separating groups of digits to the left of the decimal place in numbers.
   * Params: value = The string separating groups of digits to the left of the decimal place in numbers.
   */
  public final void numberGroupSeparator(char[] value) {
    checkReadOnly();
    numberGroupSeparator_ = value;
  }

  /**
   * $(I Property.) Retrieves the string used as the decimal separator in numbers.
   * Returns: The string used as the decimal separator in numbers. For example, ".".
   */
  public final char[] numberDecimalSeparator() {
    return numberDecimalSeparator_;
  }
  /**
   * $(I Property.) Assigns the string used as the decimal separator in numbers.
   * Params: value = The string used as the decimal separator in numbers.
   */
  public final void numberDecimalSeparator(char[] value) {
    checkReadOnly();
    numberDecimalSeparator_ = value;
  }

  /**
   * $(I Property.) Retrieves the string separating groups of digits to the left of the decimal place in currency values.
   * Returns: The string separating groups of digits to the left of the decimal place in currency values. For example, ",".
   */
  public final char[] currencyGroupSeparator() {
    return currencyGroupSeparator_;
  }
  /**
   * $(I Property.) Assigns the string separating groups of digits to the left of the decimal place in currency values.
   * Params: value = The string separating groups of digits to the left of the decimal place in currency values.
   */
  public final void currencyGroupSeparator(char[] value) {
    checkReadOnly();
    currencyGroupSeparator_ = value;
  }

  /**
   * $(I Property.) Retrieves the string used as the decimal separator in currency values.
   * Returns: The string used as the decimal separator in currency values. For example, ".".
   */
  public final char[] currencyDecimalSeparator() {
    return currencyDecimalSeparator_;
  }
  /**
   * $(I Property.) Assigns the string used as the decimal separator in currency values.
   * Params: value = The string used as the decimal separator in currency values.
   */
  public final void currencyDecimalSeparator(char[] value) {
    checkReadOnly();
    currencyDecimalSeparator_ = value;
  }

  /**
   * $(I Property.) Retrieves the string used as the currency symbol.
   * Returns: The string used as the currency symbol. For example, "£".
   */
  public final char[] currencySymbol() {
    return currencySymbol_;
  }
  /**
   * $(I Property.) Assigns the string used as the currency symbol.
   * Params: value = The string used as the currency symbol.
   */
  public final void currencySymbol(char[] value) {
    checkReadOnly();
    currencySymbol_ = value;
  }

  /**
   * $(I Property.) Retrieves the string denoting that a number is negative.
   * Returns: The string denoting that a number is negative. For example, "-".
   */
  public final char[] negativeSign() {
    return negativeSign_;
  }
  /**
   * $(I Property.) Assigns the string denoting that a number is negative.
   * Params: value = The string denoting that a number is negative.
   */
  public final void negativeSign(char[] value) {
    checkReadOnly();
    negativeSign_ = value;
  }

  /**
   * $(I Property.) Retrieves the string denoting that a number is positive.
   * Returns: The string denoting that a number is positive. For example, "+".
   */
  public final char[] positiveSign() {
    return positiveSign_;
  }
  /**
   * $(I Property.) Assigns the string denoting that a number is positive.
   * Params: value = The string denoting that a number is positive.
   */
  public final void positiveSign(char[] value) {
    checkReadOnly();
    positiveSign_ = value;
  }

  /**
   * $(I Property.) Retrieves the string representing the NaN (not a number) value.
   * Returns: The string representing the NaN value. For example, "NaN".
   */
  public final char[] nanSymbol() {
    return nanSymbol_;
  }
  /**
   * $(I Property.) Assigns the string representing the NaN (not a number) value.
   * Params: value = The string representing the NaN value.
   */
  public final void nanSymbol(char[] value) {
    checkReadOnly();
    nanSymbol_ = value;
  }

  /**
   * $(I Property.) Retrieves the string representing negative infinity.
   * Returns: The string representing negative infinity. For example, "-Infinity".
   */
  public final char[] negativeInfinitySymbol() {
    return negativeInfinitySymbol_;
  }
  /**
   * $(I Property.) Assigns the string representing negative infinity.
   * Params: value = The string representing negative infinity.
   */
  public final void negativeInfinitySymbol(char[] value) {
    checkReadOnly();
    negativeInfinitySymbol_ = value;
  }

  /**
   * $(I Property.) Retrieves the string representing positive infinity.
   * Returns: The string representing positive infinity. For example, "Infinity".
   */
  public final char[] positiveInfinitySymbol() {
    return positiveInfinitySymbol_;
  }
  /**
   * $(I Property.) Assigns the string representing positive infinity.
   * Params: value = The string representing positive infinity.
   */
  public final void positiveInfinitySymbol(char[] value) {
    checkReadOnly();
    positiveInfinitySymbol_ = value;
  }

  /**
   * $(I Property.) Retrieves a string array of native equivalents of the digits 0 to 9.
   * Returns: A string array of native equivalents of the digits 0 to 9.
   */
  public final char[][] nativeDigits() {
    return nativeDigits_;
  }
  /**
   * $(I Property.) Assigns a string array of native equivalents of the digits 0 to 9.
   * Params: value = A string array of native equivalents of the digits 0 to 9.
   */
  public final void nativeDigits(char[][] value) {
    checkReadOnly();
    nativeDigits_ = value;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
        error("NumberFormat instance is read-only.");
  }

}

/**
 * $(ANCHOR _DateTimeFormat)
 * Determines how $(LINK2 #Time, Time) values are formatted, depending on the culture.
 * Remarks: To create a DateTimeFormat for a specific culture, create a $(LINK2 #Culture, Culture) for that culture and
 * retrieve its $(LINK2 #Culture_dateTimeFormat, dateTimeFormat) property. To create a DateTimeFormat for the user's current 
 * culture, use the $(LINK2 #Culture_current, current) property.
 */
public class DateTimeFormat : IFormatService {

  private const char[] rfc1123Pattern_ = "ddd, dd MMM yyyy HH':'mm':'ss 'GMT'";
  private const char[] sortableDateTimePattern_ = "yyyy'-'MM'-'dd'T'HH':'mm':'ss";
  private const char[] universalSortableDateTimePattern_ = "yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'";
  private const char[] allStandardFormats = [ 'd', 'D', 'f', 'F', 'g', 'G', 'm', 'M', 'r', 'R', 's', 't', 'T', 'u', 'U', 'y', 'Y' ];


  package bool isReadOnly_;
  private static DateTimeFormat invariantFormat_;
  private CultureData* cultureData_;

  private Calendar calendar_;
  private int[] optionalCalendars_;
  private int firstDayOfWeek_ = -1;
  private int calendarWeekRule_ = -1;
  private char[] dateSeparator_;
  private char[] timeSeparator_;
  private char[] amDesignator_;
  private char[] pmDesignator_;
  private char[] shortDatePattern_;
  private char[] shortTimePattern_;
  private char[] longDatePattern_;
  private char[] longTimePattern_;
  private char[] monthDayPattern_;
  private char[] yearMonthPattern_;
  private char[][] abbreviatedDayNames_;
  private char[][] dayNames_;
  private char[][] abbreviatedMonthNames_;
  private char[][] monthNames_;

  private char[] fullDateTimePattern_;
  private char[] generalShortTimePattern_;
  private char[] generalLongTimePattern_;

  private char[][] shortTimePatterns_;
  private char[][] shortDatePatterns_;
  private char[][] longTimePatterns_;
  private char[][] longDatePatterns_;
  private char[][] yearMonthPatterns_;

  /**
   * $(ANCHOR DateTimeFormat_ctor)
   * Initializes an instance that is writable and culture-independent.
   */
  public this() {
    // This ctor is used by invariantFormat so we can't set the calendar property.
    cultureData_ = Culture.invariantCulture.cultureData_;
    calendar_ = Gregorian.generic;
    initialize();
  }

  package this(CultureData* cultureData, Calendar calendar) {
    cultureData_ = cultureData;
    this.calendar = calendar;
  }

  /**
   * $(ANCHOR DateTimeFormat_getFormat)
   * Retrieves an object defining how to format the specified type.
   * Params: type = The TypeInfo of the resulting formatting object.
   * Returns: If type is typeid(DateTimeFormat), the current DateTimeFormat instance. Otherwise, null.
   * Remarks: Implements $(LINK2 #IFormatService_getFormat, IFormatService.getFormat).
   */
  public Object getFormat(TypeInfo type) {
    return (type is typeid(DateTimeFormat)) ? this : null;
  }

version(Clone)
{
  /**
   */
  public Object clone() {
    DateTimeFormat other = cast(DateTimeFormat)cloneObject(this);
    other.calendar_ = cast(Calendar)calendar.clone();
    other.isReadOnly_ = false;
    return other;
  }
}

  package char[][] shortTimePatterns() {
    if (shortTimePatterns_ == null)
      shortTimePatterns_ = cultureData_.shortTimes;
    return shortTimePatterns_.dup;
  }

  package char[][] shortDatePatterns() {
    if (shortDatePatterns_ == null)
      shortDatePatterns_ = cultureData_.shortDates;
    return shortDatePatterns_.dup;
  }

  package char[][] longTimePatterns() {
    if (longTimePatterns_ == null)
      longTimePatterns_ = cultureData_.longTimes;
    return longTimePatterns_.dup;
  }

  package char[][] longDatePatterns() {
    if (longDatePatterns_ == null)
      longDatePatterns_ = cultureData_.longDates;
    return longDatePatterns_.dup;
  }

  package char[][] yearMonthPatterns() {
    if (yearMonthPatterns_ == null)
      yearMonthPatterns_ = cultureData_.yearMonths;
    return yearMonthPatterns_;
  }

  /**
   * $(ANCHOR DateTimeFormat_getAllDateTimePatterns)
   * Retrieves the standard patterns in which Time values can be formatted.
   * Returns: An array of strings containing the standard patterns in which Time values can be formatted.
   */
  public final char[][] getAllDateTimePatterns() {
    char[][] result;
    foreach (char format; DateTimeFormat.allStandardFormats)
      result ~= getAllDateTimePatterns(format);
    return result;
  }

  /**
   * $(ANCHOR DateTimeFormat_getAllDateTimePatterns_char)
   * Retrieves the standard patterns in which Time values can be formatted using the specified format character.
   * Returns: An array of strings containing the standard patterns in which Time values can be formatted using the specified format character.
   */
  public final char[][] getAllDateTimePatterns(char format) {

    char[][] combinePatterns(char[][] patterns1, char[][] patterns2) {
      char[][] result = new char[][patterns1.length * patterns2.length];
      for (int i = 0; i < patterns1.length; i++) {
        for (int j = 0; j < patterns2.length; j++)
          result[i * patterns2.length + j] = patterns1[i] ~ " " ~ patterns2[j];
      }
      return result;
    }

    // format must be one of allStandardFormats.
    char[][] result;
    switch (format) {
      case 'd':
        result ~= shortDatePatterns;
        break;
      case 'D':
        result ~= longDatePatterns;
        break;
      case 'f':
        result ~= combinePatterns(longDatePatterns, shortTimePatterns);
        break;
      case 'F':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'g':
        result ~= combinePatterns(shortDatePatterns, shortTimePatterns);
        break;
      case 'G':
        result ~= combinePatterns(shortDatePatterns, longTimePatterns);
        break;
      case 'm':
      case 'M':
        result ~= monthDayPattern;
        break;
      case 'r':
      case 'R':
        result ~= rfc1123Pattern_;
        break;
      case 's':
        result ~= sortableDateTimePattern_;
        break;
      case 't':
        result ~= shortTimePatterns;
        break;
      case 'T':
        result ~= longTimePatterns;
      case 'u':
        result ~= universalSortableDateTimePattern_;
        break;
      case 'U':
        result ~= combinePatterns(longDatePatterns, longTimePatterns);
        break;
      case 'y':
      case 'Y':
        result ~= yearMonthPatterns;
        break;
      default:
        error("The specified format was not valid.");
    }
    return result;
  }

  /**
   * $(ANCHOR DateTimeFormat_getAbbreviatedDayName)
   * Retrieves the abbreviated name of the specified day of the week based on the culture of the instance.
   * Params: dayOfWeek = A DayOfWeek value.
   * Returns: The abbreviated name of the day of the week represented by dayOfWeek.
   */
  public final char[] getAbbreviatedDayName(Calendar.DayOfWeek dayOfWeek) {
    return abbreviatedDayNames[cast(int)dayOfWeek];
  }

  /**
   * $(ANCHOR DateTimeFormat_getDayName)
   * Retrieves the full name of the specified day of the week based on the culture of the instance.
   * Params: dayOfWeek = A DayOfWeek value.
   * Returns: The full name of the day of the week represented by dayOfWeek.
   */
  public final char[] getDayName(Calendar.DayOfWeek dayOfWeek) {
    return dayNames[cast(int)dayOfWeek];
  }

  /**
   * $(ANCHOR DateTimeFormat_getAbbreviatedMonthName)
   * Retrieves the abbreviated name of the specified month based on the culture of the instance.
   * Params: month = An integer between 1 and 13 indicating the name of the _month to return.
   * Returns: The abbreviated name of the _month represented by month.
   */
  public final char[] getAbbreviatedMonthName(int month) {
    return abbreviatedMonthNames[month - 1];
  }

  /**
   * $(ANCHOR DateTimeFormat_getMonthName)
   * Retrieves the full name of the specified month based on the culture of the instance.
   * Params: month = An integer between 1 and 13 indicating the name of the _month to return.
   * Returns: The full name of the _month represented by month.
   */
  public final char[] getMonthName(int month) {
    return monthNames[month - 1];
  }

  /**
   * $(ANCHOR DateTimeFormat_getInstance)
   * Retrieves the DateTimeFormat for the specified IFormatService.
   * Params: formatService = The IFormatService used to retrieve DateTimeFormat.
   * Returns: The DateTimeFormat for the specified IFormatService.
   * Remarks: The method calls $(LINK2 #IFormatService_getFormat, IFormatService.getFormat) with typeof(DateTimeFormat). If formatService is null,
   * then the value of the current property is returned.
   */
  public static DateTimeFormat getInstance(IFormatService formatService) {
    Culture culture = cast(Culture)formatService;
    if (culture !is null) {
      if (culture.dateTimeFormat_ !is null)
        return culture.dateTimeFormat_;
      return culture.dateTimeFormat;
    }
    if (DateTimeFormat dateTimeFormat = cast(DateTimeFormat)formatService)
      return dateTimeFormat;
    if (formatService !is null) {
      if (DateTimeFormat dateTimeFormat = cast(DateTimeFormat)(formatService.getFormat(typeid(DateTimeFormat))))
        return dateTimeFormat;
    }
    return current;
  }

  /**
   * $(ANCHOR DateTimeFormat_current)
   * $(I Property.) Retrieves a read-only DateTimeFormat instance from the current culture.
   * Returns: A read-only DateTimeFormat instance from the current culture.
   */
  public static DateTimeFormat current() {
    return Culture.current.dateTimeFormat;
  }

  /**
   * $(ANCHOR DateTimeFormat_invariantFormat)
   * $(I Property.) Retrieves a read-only DateTimeFormat instance that is culturally independent.
   * Returns: A read-only DateTimeFormat instance that is culturally independent.
   */
  public static DateTimeFormat invariantFormat() {
    if (invariantFormat_ is null) {
      invariantFormat_ = new DateTimeFormat;
      invariantFormat_.calendar = new Gregorian();
      invariantFormat_.isReadOnly_ = true;
    }
    return invariantFormat_;
  }

  /**
   * $(ANCHOR DateTimeFormat_isReadOnly)
   * $(I Property.) Retrieves a value indicating whether the instance is read-only.
   * Returns: true is the instance is read-only; otherwise, false.
   */
  public final bool isReadOnly() {
    return isReadOnly_;
  }

  /**
   * $(I Property.) Retrieves the calendar used by the current culture.
   * Returns: The Calendar determining the calendar used by the current culture. For example, the Gregorian.
   */
  public final Calendar calendar() {
    assert(calendar_ !is null);
    return calendar_;
  }
  /**
   * $(ANCHOR DateTimeFormat_calendar)
   * $(I Property.) Assigns the calendar to be used by the current culture.
   * Params: value = The Calendar determining the calendar to be used by the current culture.
   * Exceptions: If value is not valid for the current culture, an Exception is thrown.
   */
  public final void calendar(Calendar value) {
    checkReadOnly();
    if (value !is calendar_) {
      for (int i = 0; i < optionalCalendars.length; i++) {
        if (optionalCalendars[i] == value.id) {
          if (calendar_ !is null) {
            // Clear current properties.
            shortDatePattern_ = null;
            longDatePattern_ = null;
            shortTimePattern_ = null;
            yearMonthPattern_ = null;
            monthDayPattern_ = null;
            generalShortTimePattern_ = null;
            generalLongTimePattern_ = null;
            fullDateTimePattern_ = null;
            shortDatePatterns_ = null;
            longDatePatterns_ = null;
            yearMonthPatterns_ = null;
            abbreviatedDayNames_ = null;
            abbreviatedMonthNames_ = null;
            dayNames_ = null;
            monthNames_ = null;
          }
          calendar_ = value;
          initialize();
          return;
        }
      }
      error("Not a valid calendar for the culture.");
    }
  }

  /**
   * $(ANCHOR DateTimeFormat_firstDayOfWeek)
   * $(I Property.) Retrieves the first day of the week.
   * Returns: A DayOfWeek value indicating the first day of the week.
   */
  public final Calendar.DayOfWeek firstDayOfWeek() {
    return cast(Calendar.DayOfWeek)firstDayOfWeek_;
  }
  /**
   * $(I Property.) Assigns the first day of the week.
   * Params: valie = A DayOfWeek value indicating the first day of the week.
   */
  public final void firstDayOfWeek(Calendar.DayOfWeek value) {
    checkReadOnly();
    firstDayOfWeek_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_calendarWeekRule)
   * $(I Property.) Retrieves the _value indicating the rule used to determine the first week of the year.
   * Returns: A CalendarWeekRule _value determining the first week of the year.
   */
  public final Calendar.WeekRule calendarWeekRule() {
    return cast(Calendar.WeekRule) calendarWeekRule_;
  }
  /**
   * $(I Property.) Assigns the _value indicating the rule used to determine the first week of the year.
   * Params: value = A CalendarWeekRule _value determining the first week of the year.
   */
  public final void calendarWeekRule(Calendar.WeekRule value) {
    checkReadOnly();
    calendarWeekRule_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_nativeCalendarName)
   * $(I Property.) Retrieves the native name of the calendar associated with the current instance.
   * Returns: The native name of the calendar associated with the current instance.
   */
  public final char[] nativeCalendarName() {
    return cultureData_.nativeCalName;
  }

  /**
   * $(ANCHOR DateTimeFormat_dateSeparator)
   * $(I Property.) Retrieves the string separating date components.
   * Returns: The string separating date components.
   */
  public final char[] dateSeparator() {
    if (dateSeparator_ == null)
      dateSeparator_ = cultureData_.date;
    return dateSeparator_;
  }
  /**
   * $(I Property.) Assigns the string separating date components.
   * Params: value = The string separating date components.
   */
  public final void dateSeparator(char[] value) {
    checkReadOnly();
    dateSeparator_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_timeSeparator)
   * $(I Property.) Retrieves the string separating time components.
   * Returns: The string separating time components.
   */
  public final char[] timeSeparator() {
    if (timeSeparator_ == null)
      timeSeparator_ = cultureData_.time;
    return timeSeparator_;
  }
  /**
   * $(I Property.) Assigns the string separating time components.
   * Params: value = The string separating time components.
   */
  public final void timeSeparator(char[] value) {
    checkReadOnly();
    timeSeparator_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_amDesignator)
   * $(I Property.) Retrieves the string designator for hours before noon.
   * Returns: The string designator for hours before noon. For example, "AM".
   */
  public final char[] amDesignator() {
    assert(amDesignator_ != null);
    return amDesignator_;
  }
  /**
   * $(I Property.) Assigns the string designator for hours before noon.
   * Params: value = The string designator for hours before noon.
   */
  public final void amDesignator(char[] value) {
    checkReadOnly();
    amDesignator_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_pmDesignator)
   * $(I Property.) Retrieves the string designator for hours after noon.
   * Returns: The string designator for hours after noon. For example, "PM".
   */
  public final char[] pmDesignator() {
    assert(pmDesignator_ != null);
    return pmDesignator_;
  }
  /**
   * $(I Property.) Assigns the string designator for hours after noon.
   * Params: value = The string designator for hours after noon.
   */
  public final void pmDesignator(char[] value) {
    checkReadOnly();
    pmDesignator_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_shortDatePattern)
   * $(I Property.) Retrieves the format pattern for a short date value.
   * Returns: The format pattern for a short date value.
   */
  public final char[] shortDatePattern() {
    assert(shortDatePattern_ != null);
    return shortDatePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a short date _value.
   * Params: value = The format pattern for a short date _value.
   */
  public final void shortDatePattern(char[] value) {
    checkReadOnly();
    if (shortDatePatterns_ != null)
      shortDatePatterns_[0] = value;
    shortDatePattern_ = value;
    generalLongTimePattern_ = null;
    generalShortTimePattern_ = null;
  }

  /**
   * $(ANCHOR DateTimeFormat_shortTimePattern)
   * $(I Property.) Retrieves the format pattern for a short time value.
   * Returns: The format pattern for a short time value.
   */
  public final char[] shortTimePattern() {
    if (shortTimePattern_ == null)
      shortTimePattern_ = cultureData_.shortTime;
    return shortTimePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a short time _value.
   * Params: value = The format pattern for a short time _value.
   */
  public final void shortTimePattern(char[] value) {
    checkReadOnly();
    shortTimePattern_ = value;
    generalShortTimePattern_ = null;
  }

  /**
   * $(ANCHOR DateTimeFormat_longDatePattern)
   * $(I Property.) Retrieves the format pattern for a long date value.
   * Returns: The format pattern for a long date value.
   */
  public final char[] longDatePattern() {
    assert(longDatePattern_ != null);
    return longDatePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a long date _value.
   * Params: value = The format pattern for a long date _value.
   */
  public final void longDatePattern(char[] value) {
    checkReadOnly();
    if (longDatePatterns_ != null)
      longDatePatterns_[0] = value;
    longDatePattern_ = value;
    fullDateTimePattern_ = null;
  }

  /**
   * $(ANCHOR DateTimeFormat_longTimePattern)
   * $(I Property.) Retrieves the format pattern for a long time value.
   * Returns: The format pattern for a long time value.
   */
  public final char[] longTimePattern() {
    assert(longTimePattern_ != null);
    return longTimePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a long time _value.
   * Params: value = The format pattern for a long time _value.
   */
  public final void longTimePattern(char[] value) {
    checkReadOnly();
    longTimePattern_ = value;
    fullDateTimePattern_ = null;
  }

  /**
   * $(ANCHOR DateTimeFormat_monthDayPattern)
   * $(I Property.) Retrieves the format pattern for a month and day value.
   * Returns: The format pattern for a month and day value.
   */
  public final char[] monthDayPattern() {
    if (monthDayPattern_ == null)
      monthDayPattern_ = cultureData_.monthDay;
    return monthDayPattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a month and day _value.
   * Params: value = The format pattern for a month and day _value.
   */
  public final void monthDayPattern(char[] value) {
    checkReadOnly();
    monthDayPattern_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_yearMonthPattern)
   * $(I Property.) Retrieves the format pattern for a year and month value.
   * Returns: The format pattern for a year and month value.
   */
  public final char[] yearMonthPattern() {
    assert(yearMonthPattern_ != null);
    return yearMonthPattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a year and month _value.
   * Params: value = The format pattern for a year and month _value.
   */
  public final void yearMonthPattern(char[] value) {
    checkReadOnly();
    yearMonthPattern_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_abbreviatedDayNames)
   * $(I Property.) Retrieves a string array containing the abbreviated names of the days of the week.
   * Returns: A string array containing the abbreviated names of the days of the week. For $(LINK2 #DateTimeFormat_invariantFormat, invariantFormat),
   *   this contains "Sun", "Mon", "Tue", "Wed", "Thu", "Fri" and "Sat".
   */
  public final char[][] abbreviatedDayNames() {
    if (abbreviatedDayNames_ == null)
      abbreviatedDayNames_ = cultureData_.abbrevDayNames;
    return abbreviatedDayNames_.dup;
  }
  /**
   * $(I Property.) Assigns a string array containing the abbreviated names of the days of the week.
   * Params: value = A string array containing the abbreviated names of the days of the week.
   */
  public final void abbreviatedDayNames(char[][] value) {
    checkReadOnly();
    abbreviatedDayNames_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_dayNames)
   * $(I Property.) Retrieves a string array containing the full names of the days of the week.
   * Returns: A string array containing the full names of the days of the week. For $(LINK2 #DateTimeFormat_invariantFormat, invariantFormat),
   *   this contains "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday" and "Saturday".
   */
  public final char[][] dayNames() {
    if (dayNames_ == null)
      dayNames_ = cultureData_.dayNames;
    return dayNames_.dup;
  }
  /**
   * $(I Property.) Assigns a string array containing the full names of the days of the week.
   * Params: value = A string array containing the full names of the days of the week.
   */
  public final void dayNames(char[][] value) {
    checkReadOnly();
    dayNames_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_abbreviatedMonthNames)
   * $(I Property.) Retrieves a string array containing the abbreviated names of the months.
   * Returns: A string array containing the abbreviated names of the months. For $(LINK2 #DateTimeFormat_invariantFormat, invariantFormat),
   *   this contains "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" and "".
   */
  public final char[][] abbreviatedMonthNames() {
    if (abbreviatedMonthNames_ == null)
      abbreviatedMonthNames_ = cultureData_.abbrevMonthNames;
    return abbreviatedMonthNames_.dup;
  }
  /**
   * $(I Property.) Assigns a string array containing the abbreviated names of the months.
   * Params: value = A string array containing the abbreviated names of the months.
   */
  public final void abbreviatedMonthNames(char[][] value) {
    checkReadOnly();
    abbreviatedMonthNames_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_monthNames)
   * $(I Property.) Retrieves a string array containing the full names of the months.
   * Returns: A string array containing the full names of the months. For $(LINK2 #DateTimeFormat_invariantFormat, invariantFormat),
   *   this contains "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" and "".
   */
  public final char[][] monthNames() {
    if (monthNames_ == null)
      monthNames_ = cultureData_.monthNames;
    return monthNames_.dup;
  }
  /**
   * $(I Property.) Assigns a string array containing the full names of the months.
   * Params: value = A string array containing the full names of the months.
   */
  public final void monthNames(char[][] value) {
    checkReadOnly();
    monthNames_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_fullDateTimePattern)
   * $(I Property.) Retrieves the format pattern for a long date and a long time value.
   * Returns: The format pattern for a long date and a long time value.
   */
  public final char[] fullDateTimePattern() {
    if (fullDateTimePattern_ == null)
      fullDateTimePattern_ = longDatePattern ~ " " ~ longTimePattern;
    return fullDateTimePattern_;
  }
  /**
   * $(I Property.) Assigns the format pattern for a long date and a long time _value.
   * Params: value = The format pattern for a long date and a long time _value.
   */
  public final void fullDateTimePattern(char[] value) {
    checkReadOnly();
    fullDateTimePattern_ = value;
  }

  /**
   * $(ANCHOR DateTimeFormat_rfc1123Pattern)
   * $(I Property.) Retrieves the format pattern based on the IETF RFC 1123 specification, for a time value.
   * Returns: The format pattern based on the IETF RFC 1123 specification, for a time value.
   */
  public final char[] rfc1123Pattern() {
    return rfc1123Pattern_;
  }

  /**
   * $(ANCHOR DateTimeFormat_sortableDateTimePattern)
   * $(I Property.) Retrieves the format pattern for a sortable date and time value.
   * Returns: The format pattern for a sortable date and time value.
   */
  public final char[] sortableDateTimePattern() {
    return sortableDateTimePattern_;
  }

  /**
   * $(ANCHOR DateTimeFormat_universalSortableDateTimePattern)
   * $(I Property.) Retrieves the format pattern for a universal date and time value.
   * Returns: The format pattern for a universal date and time value.
   */
  public final char[] universalSortableDateTimePattern() {
    return universalSortableDateTimePattern_;
  }

  package char[] generalShortTimePattern() {
    if (generalShortTimePattern_ == null)
      generalShortTimePattern_ = shortDatePattern ~ " " ~ shortTimePattern;
    return generalShortTimePattern_;
  }

  package char[] generalLongTimePattern() {
    if (generalLongTimePattern_ == null)
      generalLongTimePattern_ = shortDatePattern ~ " " ~ longTimePattern;
    return generalLongTimePattern_;
  }

  private void checkReadOnly() {
    if (isReadOnly_)
        error("DateTimeFormat instance is read-only.");
  }

  private void initialize() {
    if (longTimePattern_ == null)
      longTimePattern_ = cultureData_.longTime;
    if (shortDatePattern_ == null)
      shortDatePattern_ = cultureData_.shortDate;
    if (longDatePattern_ == null)
      longDatePattern_ = cultureData_.longDate;
    if (yearMonthPattern_ == null)
      yearMonthPattern_ = cultureData_.yearMonth;
    if (amDesignator_ == null)
      amDesignator_ = cultureData_.am;
    if (pmDesignator_ == null)
      pmDesignator_ = cultureData_.pm;
    if (firstDayOfWeek_ == -1)
      firstDayOfWeek_ = cultureData_.firstDayOfWeek;
    if (calendarWeekRule_ == -1)
      calendarWeekRule_ = cultureData_.firstDayOfYear;
  }

  private int[] optionalCalendars() {
    if (optionalCalendars_ is null)
      optionalCalendars_ = cultureData_.optionalCalendars;
    return optionalCalendars_;
  }

  private void error(char[] msg) {
     throw new LocaleException (msg);
  }

}


