/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.time.chrono.GregorianBased;

private import tango.core.Exception;

private import tango.time.Time;

private import tango.time.chrono.Gregorian;



private class GregorianBased : Gregorian {

  private EraRange[] eraRanges_;
  private int maxYear_, minYear_;
  private int currentEra_ = -1;

  this() 
  {
    eraRanges_ = EraRange.getEraRanges(id);
    maxYear_ = eraRanges_[0].maxEraYear;
    minYear_ = eraRanges_[0].minEraYear;
  }

  public override Time toTime(uint year, uint month, uint day, uint hour, uint minute, uint second, uint millisecond, uint era) {
    year = getGregorianYear(year, era);
    return super.toTime(year, month, day, hour, minute, second, millisecond, era);
  }
  public override uint getYear(Time time) {
    auto ticks = time.ticks;
    auto year = extractPart(time.ticks, DatePart.Year);
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return year - eraRange.yearOffset;
    }
    throw new IllegalArgumentException("Value was out of range.");
  }

  public override uint getEra(Time time) {
    auto ticks = time.ticks;
    foreach (EraRange eraRange; eraRanges_) {
      if (ticks >= eraRange.ticks)
        return eraRange.era;
    }
    throw new IllegalArgumentException("Value was out of range.");
  }

  public override uint[] eras() {
    uint[] result;
    foreach (EraRange eraRange; eraRanges_)
      result ~= eraRange.era;
    return result;
  }

  private uint getGregorianYear(uint year, uint era) {
    if (era == 0)
      era = currentEra;
    foreach (EraRange eraRange; eraRanges_) {
      if (era == eraRange.era) {
        if (year >= eraRange.minEraYear && year <= eraRange.maxEraYear)
          return eraRange.yearOffset + year;
        throw new IllegalArgumentException("Value was out of range.");
      }
    }
    throw new IllegalArgumentException("Era value was not valid.");
  }

  protected uint currentEra() {
    if (currentEra_ == -1)
      currentEra_ = EraRange.getCurrentEra(id);
    return currentEra_;
  }
}



package struct EraRange {

  private static EraRange[][uint] eraRanges;
  private static uint[uint] currentEras;
  private static bool initialized_;

  package uint era;
  package long ticks;
  package uint yearOffset;
  package uint minEraYear;
  package uint maxEraYear;

  private static void initialize() {
    if (!initialized_) {
      long getTicks(uint year, uint month, uint day)
      {
        return Gregorian.generic.getDateTicks(year, month, day, Gregorian.AD_ERA);
      }
      eraRanges[Gregorian.JAPAN] ~= EraRange(4, getTicks(1989, 1, 8), 1988, 1, Gregorian.MAX_YEAR);
      eraRanges[Gregorian.JAPAN] ~= EraRange(3, getTicks(1926, 12, 25), 1925, 1, 1989);
      eraRanges[Gregorian.JAPAN] ~= EraRange(2, getTicks(1912, 7, 30), 1911, 1, 1926);
      eraRanges[Gregorian.JAPAN] ~= EraRange(1, getTicks(1868, 9, 8), 1867, 1, 1912);
      eraRanges[Gregorian.TAIWAN] ~= EraRange(1, getTicks(1912, 1, 1), 1911, 1, Gregorian.MAX_YEAR);
      eraRanges[Gregorian.KOREA] ~= EraRange(1, getTicks(1, 1, 1), -2333, 2334, Gregorian.MAX_YEAR);
      eraRanges[Gregorian.THAI] ~= EraRange(1, getTicks(1, 1, 1), -543, 544, Gregorian.MAX_YEAR);
      currentEras[Gregorian.JAPAN] = 4;
      currentEras[Gregorian.TAIWAN] = 1;
      currentEras[Gregorian.KOREA] = 1;
      currentEras[Gregorian.THAI] = 1;
      initialized_ = true;
    }
  }

  package static EraRange[] getEraRanges(uint calID) {
    if (!initialized_)
      initialize();
    return eraRanges[calID];
  }

  package static uint getCurrentEra(uint calID) {
    if (!initialized_)
      initialize();
    return currentEras[calID];
  }

  private static EraRange opCall(uint era, long ticks, uint yearOffset, uint minEraYear, uint prevEraYear) {
    EraRange eraRange;
    eraRange.era = era;
    eraRange.ticks = ticks;
    eraRange.yearOffset = yearOffset;
    eraRange.minEraYear = minEraYear;
    eraRange.maxEraYear = prevEraYear - yearOffset;
    return eraRange;
  }

}

