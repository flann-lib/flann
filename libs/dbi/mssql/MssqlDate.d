/**
 * Authors: The D DBI project
 *
 * Version: 0.2.5
 *
 * Copyright: BSD license
 */
module dbi.mssql.MssqlDate;

version (Phobos) {
	private import std.string : toDString = toString, toCString = toStringz;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
	private import tango.text.convert.Integer : toDString = toUtf8;;
}
private import dbi.DBIException;
private import dbi.mssql.imp;

class MssqlDate {
	public:
	this () {
	}

	this (CS_DATETIME dt) {
		this.dr = convert(dt);
	}

	this (CS_DATETIME4 dt4) {
		this.dr = convert(dt4);
	}

	char[] getString () {
		char[] pad(char[] orig) {
			if (orig.length == 1)
				orig = "0" ~ orig;
			return orig;
		}

		return toDString(dr.dateyear) ~ "-" ~ pad(toDString(dr.datemonth)) ~ "-" ~ pad(toDString(dr.datedmonth)) ~ " " ~ pad(toDString(dr.datehour)) ~ ":" ~ pad(toDString(dr.dateminute)) ~ ":" ~ pad(toDString(dr.datesecond));
	}

	private:
	CS_DATEREC dr;

	int dt_days;
	uint dt_time;

	int years, months, days, ydays, wday, hours, mins, secs, ms;
	int l, n, i, j;

	CS_DATEREC convert(CS_DATETIME dt) {
		dt_time = dt.dttime;
		ms = ((dt_time % 300) * 1000 + 150) / 300;
		dt_time = dt_time / 300;
		secs = dt_time % 60;
		dt_time = dt_time / 60;
		dt_days = dt.dtdays;

		return convert2();
	}

	CS_DATEREC convert(CS_DATETIME4 dt4) {
		secs = 0;
		ms = 0;
		dt_days = dt4.days;
		dt_time = dt4.minutes;

		return convert2();
	}

	CS_DATEREC convert2() {
		/*
		 * -53690 is minimun	(1753-1-1) (Gregorian calendar start in 1732)
		 * 2958463 is maximun (9999-12-31)
		 */
		l = dt_days + 146038;
		wday = (l + 4) % 7;
		n = (4 * l) / 146097;   /* n century */
		l = l - (146097 * n + 3) / 4;   /* days from xx00-02-28 (y-m-d) */
		i = (4000 * (l + 1)) / 1461001; /* years from xx00-02-28 */
		l = l - (1461 * i) / 4; /* year days from xx00-02-28 */
		ydays = l >= 306 ? l - 305 : l + 60;
		l += 31;
		j = (80 * l) / 2447;
		days = l - (2447 * j) / 80;
		l = j / 11;
		months = (j + 1 - 12 * l) + 1;
		years = 100 * (n + 15) + i + l;
		if (l == 0 && (years & 3) == 0 && (years % 100 != 0 || years % 400 == 0))
			++ydays;

		hours = dt_time / 60;
		mins = dt_time % 60;

		dr.dateyear = years;
		dr.datemonth = months;
		dr.datedmonth = days;
		dr.datedyear = ydays;
		dr.datedweek = wday;
		dr.datehour = hours;
		dr.dateminute = mins;
		dr.datesecond = secs;
		dr.datemsecond = ms;

		return dr;
	}
}