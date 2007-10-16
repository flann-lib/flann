module dbi.mssql.imp;

version (Windows) {
	pragma (lib, "libct.lib");
} else version (linux) {
	pragma (lib, "libct.a");
} else version (Posix) {
	pragma (lib, "libct.a");
} else version (darwin) {
	pragma (lib, "libct.a");
} else {
	pragma (msg, "You will need to manually link in the mSQL library.");
}


extern (C) {
  int cs_ctx_alloc(int version_, void * * ctx);
  int ct_init(void * ctx, int version_);
  int ct_con_alloc(void * ctx, void * * con);
  int ct_con_props(void * con, int action, int property, void * buffer,
		   int buflen, int * out_len);
  int ct_connect(void * con, char * servername, int snamelen);

  int ct_cmd_alloc(void * con, void * * cmd);
  int ct_command(void * cmd, int type, void * buffer, int buflen, int option);
  int ct_send(void * cmd);

  int ct_results(void * cmd, int * result_type);
  int ct_res_info(void * cmd, int type, void * buffer, int buflen,
		  int * out_len);
  int ct_fetch(void * cmd, int type, int offset, int option, int * rows_read);
  int ct_describe(void * cmd, int item, _cs_datafmt * datafmt);
  int ct_bind(void * cmd, int item, _cs_datafmt * datafmt, void * buffer,
	      int * copied, short * indicator);

  int ct_close(void * con, int option);
}

alias void CS_CONTEXT;
alias void CS_CONNECTION;
alias void CS_COMMAND;

alias int CS_RETCODE;

alias _cs_datafmt CS_DATAFMT;
struct _cs_datafmt {
  char[132] name;
  int namelen;
  int datatype;
  int format;
  int maxlength;
  int scale;
  int precision;
  int status;
  int count;
  int usertype;
  void * locale;
}

const int CS_UNUSED = -99999;
const int CS_NULLTERM = -9;

const int CS_FAIL = 0;
const int CS_SUCCEED = 1;
const int CS_SET = 34;
const int CS_VERSION_100 = 112;
const int CS_LANG_CMD = 148;
const int CS_NUMDATA = 803;

const int CS_ROW_RESULT = 4040;

const int CS_END_RESULTS = -205;
const int CS_CMD_DONE = 4046;
const int CS_CMD_SUCCEED = 4047;
const int CS_CMD_FAIL = 4048;

const int CS_USERNAME = 9100;
const int CS_PASSWORD = 9101;
const int CS_SERVERADDR = 9206;

// data types
const int CS_CHAR_TYPE = 0;
const int CS_FLOAT_TYPE = 10;
const int CS_DATETIME_TYPE = 12;
const int CS_DATETIME4_TYPE = 13;
const int CS_MONEY_TYPE = 14;
const int CS_MONEY4_TYPE = 15;

alias double CS_FLOAT;
alias int CS_INT;

alias _cs_daterec CS_DATEREC;
struct _cs_daterec {
  int dateyear;
  int datemonth;
  int datedmonth;
  int datedyear;
  int datedweek;
  int datehour;
  int dateminute;
  int datesecond;
  int datemsecond;
  int datetzone;
}


alias _cs_datetime4 CS_DATETIME4;
struct _cs_datetime4 {
  ushort days;
  ushort minutes;
}

alias _cs_datetime CS_DATETIME;
struct _cs_datetime {
  int dtdays;
  int dttime;
}

alias _cs_money4 CS_MONEY4;
struct _cs_money4 {
  int mny4;
}

alias _cs_money CS_MONEY;
struct _cs_money {
  int mnyhigh;
  uint mnylow;
}