/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.Hijri;

private import tango.time.chrono.Calendar;


/**
 * $(ANCHOR _Hijri)
 * Represents the Hijri calendar.
 */
public class Hijri : Calendar {

  private static const uint[] DAYS_TO_MONTH = [ 0, 30, 59, 89, 118, 148, 177, 207, 236, 266, 295, 325, 355 ];

  /**
   * Represents the current era.
   */
  public const uint HIJRI_ERA = 1;

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
    return Time((daysSinceJan1(year, month, day) - 1) * TimeSpan.TicksPerDay + getTimeTicks(hour, minute, second)) + TimeSpan.millis(millisecond);
  }

  /**
   * Overridden. Returns the day of the week in the specified Time.
   * Params: time = A Time value.
   * Returns: A DayOfWeek value representing the day of the week of time.
   */
  public override DayOfWeek getDayOfWeek(Time time) {
    return cast(DayOfWeek) (cast(uint) (time.ticks / TimeSpan.TicksPerDay + 1) % 7);
  }

  /**
   * Overridden. Returns the day of the month in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the day of the month of time.
   */
  public override uint getDayOfMonth(Time time) {
    return extractPart(time.ticks, DatePart.Day);
  }

  /**
   * Overridden. Returns the day of the year in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the day of the year of time.
   */
  public override uint getDayOfYear(Time time) {
    return extractPart(time.ticks, DatePart.DayOfYear);
  }

  /**
   * Overridden. Returns the day of the year in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the day of the year of time.
   */
  public override uint getMonth(Time time) {
    return extractPart(time.ticks, DatePart.Month);
  }

  /**
   * Overridden. Returns the year in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the year in time.
   */
  public override uint getYear(Time time) {
    return extractPart(time.ticks, DatePart.Year);
  }

  /**
   * Overridden. Returns the era in the specified Time.
   * Params: time = A Time value.
   * Returns: An integer representing the ear in time.
   */
  public override uint getEra(Time time) {
    return HIJRI_ERA;
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
    if (month == 12)
      return isLeapYear(year, CURRENT_ERA) ? 30 : 29;
    return (month % 2 == 1) ? 30 : 29;
  }

  /**
   * Overridden. Returns the number of days in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of days in the specified _year in the specified _era.
   */
  public override uint getDaysInYear(uint year, uint era) {
    return isLeapYear(year, era) ? 355 : 354;
  }

  /**
   * Overridden. Returns the number of months in the specified _year of the specified _era.
   * Params:
   *   year = An integer representing the _year.
   *   era = An integer representing the _era.
   * Returns: The number of months in the specified _year in the specified _era.
   */
  public override uint getMonthsInYear(uint year, uint era) {
    return 12;
  }

  /**
   * Overridden. Indicates whether the specified _year in the specified _era is a leap _year.
   * Params: year = An integer representing the _year.
   * Params: era = An integer representing the _era.
   * Returns: true is the specified _year is a leap _year; otherwise, false.
   */
  public override bool isLeapYear(uint year, uint era) {
    return (14 + 11 * year) % 30 < 11;
  }

  /**
   * $(I Property.) Overridden. Retrieves the list of eras in the current calendar.
   * Returns: An integer array representing the eras in the current calendar.
   */
  public override uint[] eras() {
    auto tmp = [HIJRI_ERA];
    return tmp.dup;
  }

  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override uint id() {
    return HIJRI;
  }

  private long daysToYear(uint year) {
    int cycle = ((year - 1) / 30) * 30;
    int remaining = year - cycle - 1;
    long days = ((cycle * 10631L) / 30L) + 227013L;
    while (remaining > 0) {
      days += 354 + (isLeapYear(remaining, CURRENT_ERA) ? 1 : 0);
      remaining--;
    }
    return days;
  }

  private long daysSinceJan1(uint year, uint month, uint day) {
    return cast(long)(daysToYear(year) + DAYS_TO_MONTH[month - 1] + day);
  }

  private int extractPart(long ticks, DatePart part) {
    long days = TimeSpan(ticks).days + 1;
    int year = cast(int)(((days - 227013) * 30) / 10631) + 1;
    long daysUpToYear = daysToYear(year);
    long daysInYear = getDaysInYear(year, CURRENT_ERA);
    if (days < daysUpToYear) {
      daysUpToYear -= daysInYear;
      year--;
    }
    else if (days == daysUpToYear) {
      year--;
      daysUpToYear -= getDaysInYear(year, CURRENT_ERA);
    }
    else if (days > daysUpToYear + daysInYear) {
      daysUpToYear += daysInYear;
      year++;
    }

    if (part == DatePart.Year)
      return year;

    days -= daysUpToYear;
    if (part == DatePart.DayOfYear)
      return cast(int)days;

    int month = 1;
    while (month <= 12 && days > DAYS_TO_MONTH[month - 1])
      month++;
    month--;
    if (part == DatePart.Month)
      return month;

    return cast(int)(days - DAYS_TO_MONTH[month - 1]);
  }

}

