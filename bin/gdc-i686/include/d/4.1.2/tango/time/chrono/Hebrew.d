/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris, snoyberg

******************************************************************************/

module tango.time.chrono.Hebrew;

private import tango.core.Exception;

private import tango.time.chrono.Calendar;



/**
 * $(ANCHOR _Hebrew)
 * Represents the Hebrew calendar.
 */
public class Hebrew : Calendar {

  private const uint[14][7] MonthDays = [
    // month                                                    // year type
    [ 0, 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0  ], 
    [ 0, 30, 29, 29, 29, 30, 29, 0,  30, 29, 30, 29, 30, 29 ],  // 1
    [ 0, 30, 29, 30, 29, 30, 29, 0,  30, 29, 30, 29, 30, 29 ],  // 2
    [ 0, 30, 30, 30, 29, 30, 29, 0,  30, 29, 30, 29, 30, 29 ],  // 3
    [ 0, 30, 29, 29, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 4
    [ 0, 30, 29, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ],  // 5
    [ 0, 30, 30, 30, 29, 30, 30, 29, 30, 29, 30, 29, 30, 29 ]   // 6
  ];

  private const uint YearOfOneAD = 3760;
  private const uint DaysToOneAD = cast(int)(YearOfOneAD * 365.2735);

  private const uint PartsPerHour = 1080;
  private const uint PartsPerDay = 24 * PartsPerHour;
  private const uint DaysPerMonth = 29;
  private const uint DaysPerMonthFraction = 12 * PartsPerHour + 793;
  private const uint PartsPerMonth = DaysPerMonth * PartsPerDay + DaysPerMonthFraction;
  private const uint FirstNewMoon = 11 * PartsPerHour + 204;

  private uint minYear_ = YearOfOneAD + 1583;
  private uint maxYear_ = YearOfOneAD + 2240;

  /**
   * Represents the current era.
   */
  public const uint HEBREW_ERA = 1;

  /**
   * Overridden. Returns a Time value set to the specified date and time in the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   day = An integer representing the _day.
   *   hour = An integer representing the _hour.
   *   minute = An integer representing the _minute.
   *   second = An integer representing the _second.
   *   millisecond = An integer representing the _millisecond.
   *   era = An integer representing the _era.
   * Returns: A Time set to the specified date and time.
   */
  public override Time toTime(uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond, uint era) {
    checkYear(year, era);
    return getGregorianTime(year, month, day, hour, minute, second, millisecond);
  }

  /**
   * Overridden. Returns the day of the week in the specified Time.
   * Params: time = A Time value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(Time time) {
    return cast(DayOfWeek) cast(uint) ((time.ticks / TimeSpan.TicksPerDay + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the day of the month of time.
   */
  public override uint getDayOfMonth(Time time) {
    auto year = getYear(time);
    auto yearType = getYearType(year);
    auto days = getStartOfYear(year) - DaysToOneAD;
    auto day = cast(int)(time.ticks / TimeSpan.TicksPerDay) - days;
    uint n;
    while (n < 12 && day >= MonthDays[yearType][n + 1]) {
      day -= MonthDays[yearType][n + 1];
      n++;
    }
    return day + 1;
  }

  /**
   * Overridden. Returns the day of the year in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the day of the year of time.
   */
  public override uint getDayOfYear(Time time) {
    auto year = getYear(time);
    auto days = getStartOfYear(year) - DaysToOneAD;
    return (cast(uint)(time.ticks / TimeSpan.TicksPerDay) - days) + 1;
  }

  /**
   * Overridden. Returns the month in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the month in time.
   */
  public override uint getMonth(Time time) {
    auto year = getYear(time);
    auto yearType = getYearType(year);
    auto days = getStartOfYear(year) - DaysToOneAD;
    auto day = cast(int)(time.ticks / TimeSpan.TicksPerDay) - days;
    uint n;
    while (n < 12 && day >= MonthDays[yearType][n + 1]) {
      day -= MonthDays[yearType][n + 1];
      n++;
    }
    return n + 1;
  }

  /**
   * Overridden. Returns the year in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the year in time.
   */
  public override uint getYear(Time time) {
    auto day = cast(uint)(time.ticks / TimeSpan.TicksPerDay) + DaysToOneAD;
    auto low = minYear_, high = maxYear_;
    // Perform a binary search.
    while (low <= high) {
      auto mid = low + (high - low) / 2;
      auto startDay = getStartOfYear(mid);
      if (day < startDay)
        high = mid - 1;
      else if (day >= startDay && day < getStartOfYear(mid + 1))
        return mid;
      else
        low = mid + 1;
    }
    return low;
  }

  /**
   * Overridden. Returns the era in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the ear in time.
   */
  public override uint getEra(Time time) {
    return HEBREW_ERA;
  }

  /**
   * Overridden. Returns the number of days in the specified _year and _month of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   month = An integer representing the _month.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year and _month of the specified _era.
   */
  public override uint getDaysInMonth(uint year, uint month, uint era) {
    checkYear(year, era);
    return MonthDays[getYearType(year)][month];
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override uint getDaysInYear(uint year, uint era) {
    return getStartOfYear(year + 1) - getStartOfYear(year);
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override uint getMonthsInYear(uint year, uint era) {
    return isLeapYear(year, era) ? 13 : 12;
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(uint year, uint era) {
    checkYear(year, era);
    // true if year % 19 == 0, 3, 6, 8, 11, 14, 17
    return ((7 * year + 1) % 19) < 7;
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override uint[] eras() {
        auto tmp = [HEBREW_ERA];
        return tmp.dup;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override uint id() {
    return HEBREW;
  }

  private void checkYear(uint year, uint era) {
    if ((era != CURRENT_ERA && era != HEBREW_ERA) || (year > maxYear_ || year < minYear_))
      throw new IllegalArgumentException("Value was out of range.");
  }

  private uint getYearType(uint year) {
    int yearLength = getStartOfYear(year + 1) - getStartOfYear(year);
    if (yearLength > 380)
      yearLength -= 30;
    switch (yearLength) {
      case 353:
        // "deficient"
        return 1;
      case 383:
        // "deficient" leap
        return 4;
      case 354:
        // "normal"
        return 2;
      case 384:
        // "normal" leap
        return 5;
      case 355:
        // "complete"
        return 3;
      case 385:
        // "complete" leap
        return 6;
      default:
        break;
    }
    // Satisfies -w
    throw new IllegalArgumentException("Value was not valid.");
  }

  private uint getStartOfYear(uint year) {
    auto months = (235 * year - 234) / 19;
    auto fraction = months * DaysPerMonthFraction + FirstNewMoon;
    auto day = months * 29 + (fraction / PartsPerDay);
    fraction %= PartsPerDay;

    auto dayOfWeek = day % 7;
    if (dayOfWeek == 2 || dayOfWeek == 4 || dayOfWeek == 6) {
      day++;
      dayOfWeek = day % 7;
    }
    if (dayOfWeek == 1 && fraction > 15 * PartsPerHour + 204 && !isLeapYear(year, CURRENT_ERA))
      day += 2;
    else if (dayOfWeek == 0 && fraction > 21 * PartsPerHour + 589 && isLeapYear(year, CURRENT_ERA))
      day++;
    return day;
  }

  private Time getGregorianTime(uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond) {
    auto yearType = getYearType(year);
    auto days = getStartOfYear(year) - DaysToOneAD + day - 1;
    for (int i = 1; i <= month; i++)
      days += MonthDays[yearType][i - 1];
    return Time((days * TimeSpan.TicksPerDay) + getTimeTicks(hour, minute, second)) + TimeSpan.millis(millisecond);
  }

}

