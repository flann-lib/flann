module meta.Util;



template itoa(int i) {
	static if (i < 0) {
		static const char[] itoa = "-" ~ itoa!(-i);
	}
	else {
		static if (i / 10 > 0) {
			static const char[] itoa = itoa(i / 10) ~ "0123456789"[i % 10];
		} else {
			static const char[] itoa = "0123456789"[i % 10 .. i % 10 + 1];
		}
	}
}