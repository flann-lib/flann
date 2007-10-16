module dbi.mysql.imp;

extern (C):

version (Windows) {
	pragma (lib, "libmysql.lib");
	extern (Windows):
} else version (linux) {
	pragma (lib, "libmysql.a");
} else version (Posix) {
	pragma (lib, "libmysql.a");
} else version (darwin) {
	pragma (lib, "libmysql.a");
} else {
	pragma (msg, "You will need to manually link in the MySQL library.");
}

alias ubyte __u_char;
alias ushort __u_short;
alias uint __u_int;
alias uint __u_long;


alias byte __int8_t;
alias ubyte __uint8_t;
alias short __int16_t;
alias ushort __uint16_t;
alias int __int32_t;
alias uint __uint32_t;




 alias long __int64_t;
 alias ulong __uint64_t;







 alias long __quad_t;
 alias ulong __u_quad_t;






 alias ulong __dev_t;
 alias uint __uid_t;
 alias uint __gid_t;
 alias uint __ino_t;
 alias ulong __ino64_t;
 alias uint __mode_t;
 alias uint __nlink_t;
 alias int __off_t;
 alias long __off64_t;
 alias int __pid_t;
 struct __fsid_t { int __val[2]; };

 alias int __clock_t;
 alias uint __rlim_t;
 alias ulong __rlim64_t;
 alias uint __id_t;
 alias int __time_t;
 alias uint __useconds_t;
 alias int __suseconds_t;

 alias int __daddr_t;
 alias int __swblk_t;
 alias int __key_t;


 alias int __clockid_t;


 alias int __timer_t;


 alias int __blksize_t;




 alias int __blkcnt_t;
 alias long __blkcnt64_t;


 alias uint __fsblkcnt_t;
 alias ulong __fsblkcnt64_t;


 alias uint __fsfilcnt_t;
 alias ulong __fsfilcnt64_t;

 alias int __ssize_t;



alias __off64_t __loff_t;
alias __quad_t *__qaddr_t;
alias char *__caddr_t;


 alias int __intptr_t;


 alias uint __socklen_t;



alias __u_char u_char;
alias __u_short u_short;
alias __u_int u_int;
alias __u_long u_long;
alias __quad_t quad_t;
alias __u_quad_t u_quad_t;
alias __fsid_t fsid_t;




alias __loff_t loff_t;



alias __ino_t ino_t;
alias __dev_t dev_t;




alias __gid_t gid_t;




alias __mode_t mode_t;




alias __nlink_t nlink_t;




alias __uid_t uid_t;





alias __off_t off_t;
alias __pid_t pid_t;




alias __id_t id_t;




alias __ssize_t ssize_t;





alias __daddr_t daddr_t;
alias __caddr_t caddr_t;





alias __key_t key_t;


alias __time_t time_t;



alias __clockid_t clockid_t;
alias __timer_t timer_t;






alias int int8_t ;
alias int int16_t ;
alias int int32_t ;
alias int int64_t ;


alias uint u_int8_t ;
alias uint u_int16_t ;
alias uint u_int32_t ;
alias uint u_int64_t ;

alias int register_t ;




alias int __sig_atomic_t;




struct __sigset_t {
    uint __val[(1024 / (8 * uint.sizeof))];
  };




alias __sigset_t sigset_t;





struct timespec {
    __time_t tv_sec;
    int tv_nsec;
  }

struct timeval {
    __time_t tv_sec;
    __suseconds_t tv_usec;
  }


alias __suseconds_t suseconds_t;





alias int __fd_mask;
struct fd_set {






    __fd_mask __fds_bits[1024 / (8 * __fd_mask.sizeof)];


  };







alias __fd_mask fd_mask;

extern int select (int __nfds, fd_set * __readfds,
                   fd_set * __writefds,
                   fd_set * __exceptfds,
                   timeval * __timeout);



alias __blkcnt_t blkcnt_t;



alias __fsblkcnt_t fsblkcnt_t;



alias __fsfilcnt_t fsfilcnt_t;
struct __sched_param {
    int __sched_priority;
  }

alias int __atomic_lock_t;


struct _pthread_fastlock {
  int __status;
  __atomic_lock_t __spinlock;

}



struct _pthread_descr_struct ;
alias _pthread_descr_struct *_pthread_descr;






struct __pthread_attr_s {
  int __detachstate;
  int __schedpolicy;
  __sched_param __schedparam;
  int __inheritsched;
  int __scope;
  size_t __guardsize;
  int __stackaddr_set;
  void *__stackaddr;
  size_t __stacksize;
};
alias __pthread_attr_s pthread_attr_t;






 alias long __pthread_cond_align_t;




struct pthread_cond_t {
  _pthread_fastlock __c_lock;
  _pthread_descr __c_waiting;
  char __padding[48 - _pthread_fastlock.sizeof
                 - _pthread_descr.sizeof - __pthread_cond_align_t.sizeof];
  __pthread_cond_align_t __align;
};




struct pthread_condattr_t {
  int __dummy;
};



alias uint pthread_key_t;





struct pthread_mutex_t {
  int __m_reserved;
  int __m_count;
  _pthread_descr __m_owner;
  int __m_kind;
  _pthread_fastlock __m_lock;
};




struct pthread_mutexattr_t {
  int __mutexkind;
};




alias int pthread_once_t;
alias uint pthread_t;






alias char my_bool;
alias char * gptr;





alias int my_socket;




enum enum_server_command
{
  COM_SLEEP, COM_QUIT, COM_INIT_DB, COM_QUERY, COM_FIELD_LIST,
  COM_CREATE_DB, COM_DROP_DB, COM_REFRESH, COM_SHUTDOWN, COM_STATISTICS,
  COM_PROCESS_INFO, COM_CONNECT, COM_PROCESS_KILL, COM_DEBUG, COM_PING,
  COM_TIME, COM_DELAYED_INSERT, COM_CHANGE_USER, COM_BINLOG_DUMP,
  COM_TABLE_DUMP, COM_CONNECT_OUT, COM_REGISTER_SLAVE,
  COM_PREPARE, COM_EXECUTE, COM_LONG_DATA, COM_CLOSE_STMT,
  COM_RESET_STMT, COM_SET_OPTION, COM_FETCH,



  COM_END
};
struct st_vio ;
alias st_vio Vio;

struct st_net {

  Vio* vio;
 // ubyte *buff,*buff_end,*write_pos,*read_pos;
  ubyte*  buff,buff_end,write_pos,read_pos;
  my_socket fd;
  uint max_packet,max_packet_size;
  uint pkt_nr,compress_pkt_nr;
  uint write_timeout, read_timeout, retry_count;
  int fcntl;
  my_bool compress;





  uint remain_in_buf,length, buf_length, where_b;
  uint *return_status;
  ubyte reading_or_writing;
  char save_char;
  my_bool no_send_ok;
  my_bool no_send_eof;




  my_bool no_send_error;





  char last_error[512];
  char sqlstate[5 +1];
  uint last_errno;
  ubyte error;
  gptr query_cache_query;
  my_bool report_error;
  my_bool return_errno;
};
alias st_net NET;




enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
                        MYSQL_TYPE_SHORT, MYSQL_TYPE_LONG,
                        MYSQL_TYPE_FLOAT, MYSQL_TYPE_DOUBLE,
                        MYSQL_TYPE_NULL, MYSQL_TYPE_TIMESTAMP,
                        MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
                        MYSQL_TYPE_DATE, MYSQL_TYPE_TIME,
                        MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
                        MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
                        MYSQL_TYPE_BIT,
                        MYSQL_TYPE_NEWDECIMAL=246,
                        MYSQL_TYPE_ENUM=247,
                        MYSQL_TYPE_SET=248,
                        MYSQL_TYPE_TINY_BLOB=249,
                        MYSQL_TYPE_MEDIUM_BLOB=250,
                        MYSQL_TYPE_LONG_BLOB=251,
                        MYSQL_TYPE_BLOB=252,
                        MYSQL_TYPE_VAR_STRING=253,
                        MYSQL_TYPE_STRING=254,
                        MYSQL_TYPE_GEOMETRY=255

};
enum mysql_enum_shutdown_level {





  SHUTDOWN_DEFAULT = 0,

  SHUTDOWN_WAIT_CONNECTIONS= cast(ubyte)(1 << 0),

  SHUTDOWN_WAIT_TRANSACTIONS= cast(ubyte)(1 << 1),

  SHUTDOWN_WAIT_UPDATES= cast(ubyte)(1 << 3),

  SHUTDOWN_WAIT_ALL_BUFFERS= (cast(ubyte)(1 << 3) << 1),

  SHUTDOWN_WAIT_CRITICAL_BUFFERS= (cast(ubyte)(1 << 3) << 1) + 1,




  KILL_CONNECTION= 255
};


enum enum_cursor_type
{
  CURSOR_TYPE_NO_CURSOR= 0,
  CURSOR_TYPE_READ_ONLY= 1,
  CURSOR_TYPE_FOR_UPDATE= 2,
  CURSOR_TYPE_SCROLLABLE= 4
};



enum enum_mysql_set_option
{
  MYSQL_OPTION_MULTI_STATEMENTS_ON,
  MYSQL_OPTION_MULTI_STATEMENTS_OFF
};







my_bool my_net_init(NET *net, Vio* vio);
void my_net_local_init(NET *net);
void net_end(NET *net);
void net_clear(NET *net);
my_bool net_realloc(NET *net, uint length);
my_bool net_flush(NET *net);
my_bool my_net_write(NET *net, char *packet,uint len);
my_bool net_write_command(NET *net,ubyte command,
                           char *header, uint head_len,
                           char *packet, uint len);
int net_real_write(NET *net, char *packet,uint len);
uint my_net_read(NET *net);





struct sockaddr;
int my_connect(my_socket s,  sockaddr *name, uint namelen,
               uint timeout);

struct rand_struct {
  uint seed1,seed2,max_value;
  double max_value_dbl;
}







enum Item_result {STRING_RESULT=0, REAL_RESULT, INT_RESULT, ROW_RESULT,
                  DECIMAL_RESULT};

struct st_udf_args {
  uint arg_count;
  Item_result *arg_type;
  char **args;
  uint *lengths;
  char *maybe_null;
  char **attributes;
  uint *attribute_lengths;
};
alias st_udf_args UDF_ARGS;




struct st_udf_init {
  my_bool maybe_null;
  uint decimals;
  uint max_length;
  char *ptr;
  my_bool const_item;
};
alias st_udf_init UDF_INIT;

void randominit(rand_struct *, uint seed1,
                uint seed2);
double my_rnd(rand_struct *);
void create_random_string(char *to, uint length, rand_struct *rand_st);

void hash_password(uint *to,  char *password, uint password_len);
void make_scrambled_password_323(char *to,  char *password);
void scramble_323(char *to,  char *message,  char *password);
my_bool check_scramble_323( char *,  char *message,
                           uint *salt);
void get_salt_from_password_323(uint *res,  char *password);
void make_password_from_salt_323(char *to,  uint *salt);

void make_scrambled_password(char *to,  char *password);
void scramble(char *to,  char *message,  char *password);
my_bool check_scramble( char *reply,  char *message,
                        ubyte *hash_stage2);
void get_salt_from_password(ubyte *res,  char *password);
void make_password_from_salt(char *to,  ubyte *hash_stage2);



char *get_tty_password(char *opt_message);
 char *mysql_errno_to_sqlstate(uint mysql_errno);



my_bool my_init();
int load_defaults( char *conf_file,  char **groups,
                  int *argc, char ***argv);
my_bool my_thread_init();
void my_thread_end();
enum enum_mysql_timestamp_type
{
  MYSQL_TIMESTAMP_NONE= -2, MYSQL_TIMESTAMP_ERROR= -1,
  MYSQL_TIMESTAMP_DATE= 0, MYSQL_TIMESTAMP_DATETIME= 1, MYSQL_TIMESTAMP_TIME= 2
};
struct st_mysql_time {
  uint year, month, day, hour, minute, second;
  uint second_part;
  my_bool neg;
  enum_mysql_timestamp_type time_type;
};
alias st_mysql_time MYSQL_TIME;

struct st_typelib {
  uint count;
  const char *name;
  const char **type_names;
  uint *type_lengths;
};
alias st_typelib TYPELIB;


extern int find_type(char *x,TYPELIB *typelib,uint full_name);
extern void make_type(char *to,uint nr,TYPELIB *typelib);
extern  char *get_type(TYPELIB *typelib,uint nr);

extern TYPELIB sql_protocol_typelib;

struct st_list {
  //st_list *prev,*next;
  alias st_list *prev;
  alias st_list *next;
  void *data;
};
alias st_list LIST;


alias int (*list_walk_action)(void *,void *);

extern LIST *list_add(LIST *root,LIST *element);
extern LIST *list_delete(LIST *root,LIST *element);
extern LIST *list_cons(void *data,LIST *root);
extern LIST *list_reverse(LIST *root);
extern void list_free(LIST *root,uint free_data);
extern uint list_length(LIST *);
extern int list_walk(LIST *,list_walk_action action,gptr argument);

extern uint mysql_port;
extern char *mysql_unix_port;
struct st_mysql_field {
  char *name;
  char *org_name;
  char *table;
  char *org_table;
  char *db;
  char *catalog;
  char *def;
  uint length;
  uint max_length;
  uint name_length;
  uint org_name_length;
  uint table_length;
  uint org_table_length;
  uint db_length;
  uint catalog_length;
  uint def_length;
  uint flags;
  uint decimals;
  uint charsetnr;
  enum_field_types type;
};
alias st_mysql_field MYSQL_FIELD;


alias char **MYSQL_ROW;
alias uint MYSQL_FIELD_OFFSET;







alias ulong my_ulonglong;





struct st_mysql_rows {
  st_mysql_rows *next;
  MYSQL_ROW data;
  uint length;
};
alias st_mysql_rows MYSQL_ROWS;


alias MYSQL_ROWS *MYSQL_ROW_OFFSET;

struct st_used_mem {
  st_used_mem *next;
  uint left;
  uint size;
};
alias st_used_mem USED_MEM;



struct st_mem_root {
  USED_MEM *free;
  USED_MEM *used;
  USED_MEM *pre_alloc;

  uint min_malloc;
  uint block_size;
  uint block_num;




  uint first_block_usage;

  void (*error_handler)();
};
alias st_mem_root MEM_ROOT;


struct st_mysql_data {
  my_ulonglong rows;
  uint fields;
  MYSQL_ROWS *data;
  MEM_ROOT alloc;

  MYSQL_ROWS **prev_ptr;

};
alias st_mysql_data MYSQL_DATA;


enum mysql_option
{
  MYSQL_OPT_CONNECT_TIMEOUT, MYSQL_OPT_COMPRESS, MYSQL_OPT_NAMED_PIPE,
  MYSQL_INIT_COMMAND, MYSQL_READ_DEFAULT_FILE, MYSQL_READ_DEFAULT_GROUP,
  MYSQL_SET_CHARSET_DIR, MYSQL_SET_CHARSET_NAME, MYSQL_OPT_LOCAL_INFILE,
  MYSQL_OPT_PROTOCOL, MYSQL_SHARED_MEMORY_BASE_NAME, MYSQL_OPT_READ_TIMEOUT,
  MYSQL_OPT_WRITE_TIMEOUT, MYSQL_OPT_USE_RESULT,
  MYSQL_OPT_USE_REMOTE_CONNECTION, MYSQL_OPT_USE_EMBEDDED_CONNECTION,
  MYSQL_OPT_GUESS_CONNECTION, MYSQL_SET_CLIENT_IP, MYSQL_SECURE_AUTH,
  MYSQL_REPORT_DATA_TRUNCATION
};

struct st_mysql_options {
  uint connect_timeout, read_timeout, write_timeout;
  uint port, protocol;
  uint client_flag;
  //char *host,*user,*password,*unix_socket,*db;
  char* host,user,password,unix_socket,db;
  //struct {st_dynamic_array *init_commands;};
  //char *my_cnf_file,*my_cnf_group, *charset_dir, *charset_name;
  char*  my_cnf_file,my_cnf_group, charset_dir, charset_name;
  char *ssl_key;
  char *ssl_cert;
  char *ssl_ca;
  char *ssl_capath;
  char *ssl_cipher;
  char *shared_memory_base_name;
  uint max_allowed_packet;
  my_bool use_ssl;
  my_bool compress,named_pipe;




  my_bool rpl_probe;




  my_bool rpl_parse;




  my_bool no_master_reads;

  my_bool separate_thread;

  mysql_option methods_to_use;
  char *client_ip;

  my_bool secure_auth;

  my_bool report_data_truncation;


  int (*local_infile_init)(void **,  char *, void *);
  int (*local_infile_read)(void *, char *, uint);
  void (*local_infile_end)(void *);
  int (*local_infile_error)(void *, char *, uint);
  void *local_infile_userdata;
}

enum mysql_status
{
  MYSQL_STATUS_READY,MYSQL_STATUS_GET_RESULT,MYSQL_STATUS_USE_RESULT
};

enum mysql_protocol_type
{
  MYSQL_PROTOCOL_DEFAULT, MYSQL_PROTOCOL_TCP, MYSQL_PROTOCOL_SOCKET,
  MYSQL_PROTOCOL_PIPE, MYSQL_PROTOCOL_MEMORY
};





enum mysql_rpl_type
{
  MYSQL_RPL_MASTER, MYSQL_RPL_SLAVE, MYSQL_RPL_ADMIN
};

// start self inserted

alias char pchar;
struct charset_info_st
{
	uint      number;
	const char *name;
	ubyte    *ctype;
	ubyte    *to_lower;
	ubyte    *to_upper;
	ubyte    *sort_order;

	uint      strxfrm_multiply;
	int     (*strcoll)(byte *, ubyte *);
	int     (*strxfrm)(ubyte *, ubyte *, int);
	int     (*strnncoll)(ubyte *, int, ubyte *, int);
	int     (*strnxfrm)(ubyte *, ubyte *, int, int);
	my_bool (*like_range)(char *, uint, pchar, uint,
	char *, char *, uint *, uint *);
	uint      mbmaxlen;
	int     (*ismbchar)(char *, char *);
	my_bool (*ismbhead)(uint);
	int     (*mbcharlen)(uint);
}
alias charset_info_st CHARSET_INFO;

// end self inserted

//struct st_mysql_methods; // conflict with line 1211

struct st_mysql {
  NET net;
  gptr connector_fd;
  //char *host,*user,*passwd,*unix_socket,*server_version,*host_info,*info;
  char* host,user,passwd,unix_socket,server_version,host_info,info;
  char *db;
  charset_info_st *charset;
  MYSQL_FIELD *fields;
  MEM_ROOT field_alloc;
  my_ulonglong affected_rows;
  my_ulonglong insert_id;
  my_ulonglong extra_info;
  uint thread_id;
  uint packet_length;
  uint port;
  uint client_flag,server_capabilities;
  uint protocol_version;
  uint field_count;
  uint server_status;
  uint server_language;
  uint warning_count;
  st_mysql_options options;
  mysql_status status;
  my_bool free_me;
  my_bool reconnect;


  char scramble[20 +1];





  my_bool rpl_pivot;




  alias st_mysql* master;
  alias st_mysql* *next_slave;

  alias st_mysql* last_used_slave;

  alias st_mysql* last_used_con;

  LIST *stmts;
  const st_mysql_methods *methods;
  void *thd;




  my_bool *unbuffered_fetch_owner;
};
alias st_mysql MYSQL;


struct st_mysql_res {
  my_ulonglong row_count;
  MYSQL_FIELD *fields;
  MYSQL_DATA *data;
  MYSQL_ROWS *data_cursor;
  uint *lengths;
  MYSQL *handle;
  MEM_ROOT field_alloc;
  uint field_count, current_field;
  MYSQL_ROW row;
  MYSQL_ROW current_row;
  my_bool eof;

  my_bool unbuffered_fetch_cancelled;
  const st_mysql_methods *methods;
};
alias st_mysql_res MYSQL_RES;

struct st_mysql_manager {
  NET net;
  char*  host,user,passwd;
  uint port;
  my_bool free_me;
  my_bool eof;
  int cmd_status;
  int last_errno;
  //char* net_buf,*net_buf_pos,*net_data_end;
  char* net_buf,net_buf_pos,net_data_end;
  int net_buf_size;
  char last_error[256];
};
alias st_mysql_manager MYSQL_MANAGER;


struct st_mysql_parameters {
  uint *p_max_allowed_packet;
  uint *p_net_buffer_length;
};
alias st_mysql_parameters MYSQL_PARAMETERS;

int mysql_server_init(int argc, char **argv, char **groups);
void mysql_server_end();
MYSQL_PARAMETERS * mysql_get_parameters();







my_bool mysql_thread_init();
void mysql_thread_end();






my_ulonglong mysql_num_rows(MYSQL_RES *res);
uint mysql_num_fields(MYSQL_RES *res);
my_bool mysql_eof(MYSQL_RES *res);
MYSQL_FIELD * mysql_fetch_field_direct(MYSQL_RES *res,
                                              uint fieldnr);
MYSQL_FIELD * mysql_fetch_fields(MYSQL_RES *res);
MYSQL_ROW_OFFSET mysql_row_tell(MYSQL_RES *res);
MYSQL_FIELD_OFFSET mysql_field_tell(MYSQL_RES *res);

uint mysql_field_count(MYSQL *mysql);
my_ulonglong mysql_affected_rows(MYSQL *mysql);
my_ulonglong mysql_insert_id(MYSQL *mysql);
uint mysql_errno(MYSQL *mysql);
 char * mysql_error(MYSQL *mysql);
 char * mysql_sqlstate(MYSQL *mysql);
uint mysql_warning_count(MYSQL *mysql);
 char * mysql_info(MYSQL *mysql);
uint mysql_thread_id(MYSQL *mysql);
 char * mysql_character_set_name(MYSQL *mysql);

MYSQL * mysql_init(MYSQL *mysql);
my_bool mysql_ssl_set(MYSQL *mysql,  char *key,
                                       char *cert,  char *ca,
                                       char *capath,  char *cipher);
my_bool mysql_change_user(MYSQL *mysql,  char *user,
                                           char *passwd,  char *db);
MYSQL * mysql_real_connect(MYSQL *mysql,  char *host,
                                            char *user,
                                            char *passwd,
                                            char *db,
                                           uint port,
                                            char *unix_socket,
                                           uint clientflag);
int mysql_select_db(MYSQL *mysql,  char *db);
int mysql_query(MYSQL *mysql,  char *q);
int mysql_send_query(MYSQL *mysql,  char *q,
                                         uint length);
int mysql_real_query(MYSQL *mysql,  char *q,
                                        uint length);
MYSQL_RES * mysql_store_result(MYSQL *mysql);
MYSQL_RES * mysql_use_result(MYSQL *mysql);


my_bool mysql_master_query(MYSQL *mysql,  char *q,
                                           uint length);
my_bool mysql_master_send_query(MYSQL *mysql,  char *q,
                                                uint length);

my_bool mysql_slave_query(MYSQL *mysql,  char *q,
                                          uint length);
my_bool mysql_slave_send_query(MYSQL *mysql,  char *q,
                                               uint length);





void
mysql_set_local_infile_handler(MYSQL *mysql,
                               int (*local_infile_init)(void **,  char *,
                            void *),
                               int (*local_infile_read)(void *, char *,
                                                        uint),
                               void (*local_infile_end)(void *),
                               int (*local_infile_error)(void *, char*,
                                                         uint),
                               void *);

void
mysql_set_local_infile_default(MYSQL *mysql);






void mysql_enable_rpl_parse(MYSQL* mysql);
void mysql_disable_rpl_parse(MYSQL* mysql);

int mysql_rpl_parse_enabled(MYSQL* mysql);


void mysql_enable_reads_from_master(MYSQL* mysql);
void mysql_disable_reads_from_master(MYSQL* mysql);

my_bool mysql_reads_from_master_enabled(MYSQL* mysql);

mysql_rpl_type mysql_rpl_query_type( char* q, int len);


my_bool mysql_rpl_probe(MYSQL* mysql);


int mysql_set_master(MYSQL* mysql,  char* host,
                                         uint port,
                                          char* user,
                                          char* passwd);
int mysql_add_slave(MYSQL* mysql,  char* host,
                                        uint port,
                                         char* user,
                                         char* passwd);

int mysql_shutdown(MYSQL *mysql,
                                       mysql_enum_shutdown_level
                                       shutdown_level);
int mysql_dump_debug_info(MYSQL *mysql);
int mysql_refresh(MYSQL *mysql,
                                     uint refresh_options);
int mysql_kill(MYSQL *mysql,uint pid);
int mysql_set_server_option(MYSQL *mysql,
                                                enum_mysql_set_option
                                                option);
int mysql_ping(MYSQL *mysql);
 char * mysql_stat(MYSQL *mysql);
 char * mysql_get_server_info(MYSQL *mysql);
 char * mysql_get_client_info();
uint mysql_get_client_version();
 char * mysql_get_host_info(MYSQL *mysql);
uint mysql_get_server_version(MYSQL *mysql);
uint mysql_get_proto_info(MYSQL *mysql);
MYSQL_RES * mysql_list_dbs(MYSQL *mysql, char *wild);
MYSQL_RES * mysql_list_tables(MYSQL *mysql, char *wild);
MYSQL_RES * mysql_list_processes(MYSQL *mysql);
int mysql_options(MYSQL *mysql,mysql_option option,
                                       char *arg);
void mysql_free_result(MYSQL_RES *result);
void mysql_data_seek(MYSQL_RES *result,
                                        my_ulonglong offset);
MYSQL_ROW_OFFSET mysql_row_seek(MYSQL_RES *result,
                                                MYSQL_ROW_OFFSET offset);
MYSQL_FIELD_OFFSET mysql_field_seek(MYSQL_RES *result,
                                           MYSQL_FIELD_OFFSET offset);
MYSQL_ROW mysql_fetch_row(MYSQL_RES *result);
uint * mysql_fetch_lengths(MYSQL_RES *result);
MYSQL_FIELD * mysql_fetch_field(MYSQL_RES *result);
MYSQL_RES * mysql_list_fields(MYSQL *mysql,  char *table,
                                           char *wild);
uint mysql_escape_string(char *to, char *from,
                                            uint from_length);
uint mysql_hex_string(char *to, char *from,
                                         uint from_length);
uint mysql_real_escape_string(MYSQL *mysql,
                                               char *to, char *from,
                                               uint length);
//void mysql_debug( char *debug);
void mysql_debug( char *debugB);   // debug a reserved word in D ?. I have renamed to *debugD
char * mysql_odbc_escape_string(MYSQL *mysql,
                                                 char *to,
                                                 uint to_length,
                                                  char *from,
                                                 uint from_length,
                                                 void *param,
                                                 char *
                                                 (*extend_buffer)
                                                 (void *, char *to,
                                                  uint *length));
void myodbc_remove_escape(MYSQL *mysql,char *name);
uint mysql_thread_safe();
my_bool mysql_embedded();
MYSQL_MANAGER* mysql_manager_init(MYSQL_MANAGER* con);
MYSQL_MANAGER* mysql_manager_connect(MYSQL_MANAGER* con,
                                               char* host,
                                               char* user,
                                               char* passwd,
                                              uint port);
void mysql_manager_close(MYSQL_MANAGER* con);
int mysql_manager_command(MYSQL_MANAGER* con,
                                                 char* cmd, int cmd_len);
int mysql_manager_fetch_line(MYSQL_MANAGER* con,
                                                  char* res_buf,
                                                 int res_buf_size);
my_bool mysql_read_query_result(MYSQL *mysql);
enum enum_mysql_stmt_state
{
  MYSQL_STMT_INIT_DONE= 1, MYSQL_STMT_PREPARE_DONE, MYSQL_STMT_EXECUTE_DONE,
  MYSQL_STMT_FETCH_DONE
};
struct st_mysql_bind {
  uint *length;
  my_bool *is_null;
  void *buffer;

  my_bool *error;
  enum_field_types buffer_type;

  uint buffer_length;
  ubyte *row_ptr;
  uint offset;
  uint length_value;
  uint param_number;
  uint pack_length;
  my_bool error_value;
  my_bool is_unsigned;
  my_bool int_data_used;
  my_bool is_null_value;
  void (*store_param_func)(NET *net, st_mysql_bind *param);
  void (*fetch_result)(st_mysql_bind *, MYSQL_FIELD *,
                       ubyte **row);
  void (*skip_result)(st_mysql_bind *, MYSQL_FIELD *,
                      ubyte **row);
};
alias st_mysql_bind MYSQL_BIND;




struct st_mysql_stmt {
  MEM_ROOT mem_root;
  LIST list;
  MYSQL *mysql;
  MYSQL_BIND *params;
  MYSQL_BIND *bind;
  MYSQL_FIELD *fields;
  MYSQL_DATA result;
  MYSQL_ROWS *data_cursor;

  my_ulonglong affected_rows;
  my_ulonglong insert_id;




  int (*read_row_func)(st_mysql_stmt *stmt,
                                  ubyte **row);
  uint stmt_id;
  uint flags;




  uint server_status;
  uint last_errno;
  uint param_count;
  uint field_count;
  enum_mysql_stmt_state state;
  char last_error[512];
  char sqlstate[5 +1];

  my_bool send_types_to_server;
  my_bool bind_param_done;
  ubyte bind_result_done;

  my_bool unbuffered_fetch_cancelled;




  my_bool update_max_length;
};
alias st_mysql_stmt MYSQL_STMT;


enum enum_stmt_attr_type
{







  STMT_ATTR_UPDATE_MAX_LENGTH,




  STMT_ATTR_CURSOR_TYPE
};


struct st_mysql_methods {
  my_bool (*read_query_result)(MYSQL *mysql);
  my_bool (*advanced_command)(MYSQL *mysql,
                              enum_server_command command,
                               char *header,
                              uint header_length,
                               char *arg,
                              uint arg_length,
                              my_bool skip_check);
  MYSQL_DATA *(*read_rows)(MYSQL *mysql,MYSQL_FIELD *mysql_fields,
                           uint fields);
  MYSQL_RES * (*use_result)(MYSQL *mysql);
  void (*fetch_lengths)(uint *to,
                        MYSQL_ROW column, uint field_count);
  void (*flush_use_result)(MYSQL *mysql);

  MYSQL_FIELD * (*list_fields)(MYSQL *mysql);
  my_bool (*read_prepare_result)(MYSQL *mysql, MYSQL_STMT *stmt);
  int (*stmt_execute)(MYSQL_STMT *stmt);
  int (*read_binary_rows)(MYSQL_STMT *stmt);
  int (*unbuffered_fetch)(MYSQL *mysql, char **row);
  void (*free_embedded_thd)(MYSQL *mysql);
   char *(*read_statistics)(MYSQL *mysql);
  my_bool (*next_result)(MYSQL *mysql);
  int (*read_change_user_result)(MYSQL *mysql, char *buff,  char *passwd);

};
alias st_mysql_methods MYSQL_METHODS;



MYSQL_STMT * mysql_stmt_init(MYSQL *mysql);
int mysql_stmt_prepare(MYSQL_STMT *stmt,  char *query,
                               uint length);
int mysql_stmt_execute(MYSQL_STMT *stmt);
int mysql_stmt_fetch(MYSQL_STMT *stmt);
int mysql_stmt_fetch_column(MYSQL_STMT *stmt, MYSQL_BIND *bind,
                                    uint column,
                                    uint offset);
int mysql_stmt_store_result(MYSQL_STMT *stmt);
uint mysql_stmt_param_count(MYSQL_STMT * stmt);
my_bool mysql_stmt_attr_set(MYSQL_STMT *stmt,
                                    enum_stmt_attr_type attr_type,
                                     void *attr);
my_bool mysql_stmt_attr_get(MYSQL_STMT *stmt,
                                    enum_stmt_attr_type attr_type,
                                    void *attr);
my_bool mysql_stmt_bind_param(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool mysql_stmt_bind_result(MYSQL_STMT * stmt, MYSQL_BIND * bnd);
my_bool mysql_stmt_close(MYSQL_STMT * stmt);
my_bool mysql_stmt_reset(MYSQL_STMT * stmt);
my_bool mysql_stmt_free_result(MYSQL_STMT *stmt);
my_bool mysql_stmt_send_long_data(MYSQL_STMT *stmt,
                                          uint param_number,
                                           char *data,
                                          uint length);
MYSQL_RES * mysql_stmt_result_metadata(MYSQL_STMT *stmt);
MYSQL_RES * mysql_stmt_param_metadata(MYSQL_STMT *stmt);
uint mysql_stmt_errno(MYSQL_STMT * stmt);
 char * mysql_stmt_error(MYSQL_STMT * stmt);
 char * mysql_stmt_sqlstate(MYSQL_STMT * stmt);
MYSQL_ROW_OFFSET mysql_stmt_row_seek(MYSQL_STMT *stmt,
                                             MYSQL_ROW_OFFSET offset);
MYSQL_ROW_OFFSET mysql_stmt_row_tell(MYSQL_STMT *stmt);
void mysql_stmt_data_seek(MYSQL_STMT *stmt, my_ulonglong offset);
my_ulonglong mysql_stmt_num_rows(MYSQL_STMT *stmt);
my_ulonglong mysql_stmt_affected_rows(MYSQL_STMT *stmt);
my_ulonglong mysql_stmt_insert_id(MYSQL_STMT *stmt);
uint mysql_stmt_field_count(MYSQL_STMT *stmt);

my_bool mysql_commit(MYSQL * mysql);
my_bool mysql_rollback(MYSQL * mysql);
my_bool mysql_autocommit(MYSQL * mysql, my_bool auto_mode);
my_bool mysql_more_results(MYSQL *mysql);
int mysql_next_result(MYSQL *mysql);
void mysql_close(MYSQL *sock);
uint net_safe_read(MYSQL* mysql);