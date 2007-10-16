/**
 * InterBase import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	InterBase version 7.5.1
 *
 *	Import library version 0.02
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.ib.imp;

version (Windows) {
	pragma (msg, "You will need to manually link in the InterBase library.");
} else version (linux) {
	pragma (msg, "You will need to manually link in the InterBase library.");
} else version (Posix) {
	pragma (msg, "You will need to manually link in the InterBase library.");
} else version (darwin) {
	pragma (msg, "You will need to manually link in the InterBase library.");
} else {
	pragma (msg, "You will need to manually link in the InterBase library.");
}

alias int ISC_LONG;
alias uint ISC_ULONG;
alias short ISC_BOOLEAN;
alias ushort ISC_USHORT;
alias int ISC_STATUS;
alias long ISC_INT64;
alias ulong ISC_UINT64;
alias int ISC_DATE;
alias uint ISC_TIME;
alias void* isc_att_handle;
alias void* isc_blob_handle;
alias void* isc_db_handle;
alias void* isc_form_handle;
alias void* isc_req_handle;
alias void* isc_stmt_handle;
alias void* isc_svc_handle;
alias void* isc_tr_handle;
alias void* isc_win_handle;
alias void function() isc_callback;
alias ISC_LONG isc_resv_handle;

const ulong isc_arith_except			= 335544321;
const ulong isc_bad_dbkey			= 335544322;
const ulong isc_bad_db_format			= 335544323;
const ulong isc_bad_db_handle			= 335544324;
const ulong isc_bad_dpb_content			= 335544325;
const ulong isc_bad_dpb_form			= 335544326;
const ulong isc_bad_req_handle			= 335544327;
const ulong isc_bad_segstr_handle		= 335544328;
const ulong isc_bad_segstr_id			= 335544329;
const ulong isc_bad_tpb_content			= 335544330;
const ulong isc_bad_tpb_form			= 335544331;
const ulong isc_bad_trans_handle		= 335544332;
const ulong isc_bug_check			= 335544333;
const ulong isc_convert_error			= 335544334;
const ulong isc_db_corrupt			= 335544335;
const ulong isc_deadlock			= 335544336;
const ulong isc_excess_trans			= 335544337;
const ulong isc_from_no_match			= 335544338;
const ulong isc_infinap				= 335544339;
const ulong isc_infona				= 335544340;
const ulong isc_infunk				= 335544341;
const ulong isc_integ_fail			= 335544342;
const ulong isc_invalid_blr			= 335544343;
const ulong isc_io_error			= 335544344;
const ulong isc_lock_conflict			= 335544345;
const ulong isc_metadata_corrupt		= 335544346;
const ulong isc_not_valid			= 335544347;
const ulong isc_no_cur_rec			= 335544348;
const ulong isc_no_dup				= 335544349;
const ulong isc_no_finish			= 335544350;
const ulong isc_no_meta_update			= 335544351;
const ulong isc_no_priv				= 335544352;
const ulong isc_no_recon			= 335544353;
const ulong isc_no_record			= 335544354;
const ulong isc_no_segstr_close			= 335544355;
const ulong isc_obsolete_metadata		= 335544356;
const ulong isc_open_trans			= 335544357;
const ulong isc_port_len			= 335544358;
const ulong isc_read_only_field			= 335544359;
const ulong isc_read_only_rel			= 335544360;
const ulong isc_read_only_trans			= 335544361;
const ulong isc_read_only_view			= 335544362;
const ulong isc_req_no_trans			= 335544363;
const ulong isc_req_sync			= 335544364;
const ulong isc_req_wrong_db			= 335544365;
const ulong isc_segment				= 335544366;
const ulong isc_segstr_eof			= 335544367;
const ulong isc_segstr_no_op			= 335544368;
const ulong isc_segstr_no_read			= 335544369;
const ulong isc_segstr_no_trans			= 335544370;
const ulong isc_segstr_no_write			= 335544371;
const ulong isc_segstr_wrong_db			= 335544372;
const ulong isc_sys_request			= 335544373;
const ulong isc_stream_eof			= 335544374;
const ulong isc_unavailable			= 335544375;
const ulong isc_unres_rel			= 335544376;
const ulong isc_uns_ext				= 335544377;
const ulong isc_wish_list			= 335544378;
const ulong isc_wrong_ods			= 335544379;
const ulong isc_wronumarg			= 335544380;
const ulong isc_imp_exc				= 335544381;
const ulong isc_random				= 335544382;
const ulong isc_fatal_conflict			= 335544383;
const ulong isc_badblk				= 335544384;
const ulong isc_invpoolcl			= 335544385;
const ulong isc_nopoolids			= 335544386;
const ulong isc_relbadblk			= 335544387;
const ulong isc_blktoobig			= 335544388;
const ulong isc_bufexh				= 335544389;
const ulong isc_syntaxerr			= 335544390;
const ulong isc_bufinuse			= 335544391;
const ulong isc_bdbincon			= 335544392;
const ulong isc_reqinuse			= 335544393;
const ulong isc_badodsver			= 335544394;
const ulong isc_relnotdef			= 335544395;
const ulong isc_fldnotdef			= 335544396;
const ulong isc_dirtypage			= 335544397;
const ulong isc_waifortra			= 335544398;
const ulong isc_doubleloc			= 335544399;
const ulong isc_nodnotfnd			= 335544400;
const ulong isc_dupnodfnd			= 335544401;
const ulong isc_locnotmar			= 335544402;
const ulong isc_badpagtyp			= 335544403;
const ulong isc_corrupt				= 335544404;
const ulong isc_badpage				= 335544405;
const ulong isc_badindex			= 335544406;
const ulong isc_dbbnotzer			= 335544407;
const ulong isc_tranotzer			= 335544408;
const ulong isc_trareqmis			= 335544409;
const ulong isc_badhndcnt			= 335544410;
const ulong isc_wrotpbver			= 335544411;
const ulong isc_wroblrver			= 335544412;
const ulong isc_wrodpbver			= 335544413;
const ulong isc_blobnotsup			= 335544414;
const ulong isc_badrelation			= 335544415;
const ulong isc_nodetach			= 335544416;
const ulong isc_notremote			= 335544417;
const ulong isc_trainlim			= 335544418;
const ulong isc_notinlim			= 335544419;
const ulong isc_traoutsta			= 335544420;
const ulong isc_connect_reject			= 335544421;
const ulong isc_dbfile				= 335544422;
const ulong isc_orphan				= 335544423;
const ulong isc_no_lock_mgr			= 335544424;
const ulong isc_ctxinuse			= 335544425;
const ulong isc_ctxnotdef			= 335544426;
const ulong isc_datnotsup			= 335544427;
const ulong isc_badmsgnum			= 335544428;
const ulong isc_badparnum			= 335544429;
const ulong isc_virmemexh			= 335544430;
const ulong isc_blocking_signal			= 335544431;
const ulong isc_lockmanerr			= 335544432;
const ulong isc_journerr			= 335544433;
const ulong isc_keytoobig			= 335544434;
const ulong isc_nullsegkey			= 335544435;
const ulong isc_sqlerr				= 335544436;
const ulong isc_wrodynver			= 335544437;
const ulong isc_funnotdef			= 335544438;
const ulong isc_funmismat			= 335544439;
const ulong isc_bad_msg_vec			= 335544440;
const ulong isc_bad_detach			= 335544441;
const ulong isc_noargacc_read			= 335544442;
const ulong isc_noargacc_write			= 335544443;
const ulong isc_read_only			= 335544444;
const ulong isc_ext_err				= 335544445;
const ulong isc_non_updatable			= 335544446;
const ulong isc_no_rollback			= 335544447;
const ulong isc_bad_sec_info			= 335544448;
const ulong isc_invalid_sec_info		= 335544449;
const ulong isc_misc_interpreted		= 335544450;
const ulong isc_update_conflict			= 335544451;
const ulong isc_unlicensed			= 335544452;
const ulong isc_obj_in_use			= 335544453;
const ulong isc_nofilter			= 335544454;
const ulong isc_shadow_accessed			= 335544455;
const ulong isc_invalid_sdl			= 335544456;
const ulong isc_out_of_bounds			= 335544457;
const ulong isc_invalid_dimension		= 335544458;
const ulong isc_rec_in_limbo			= 335544459;
const ulong isc_shadow_missing			= 335544460;
const ulong isc_cant_validate			= 335544461;
const ulong isc_cant_start_journal		= 335544462;
const ulong isc_gennotdef			= 335544463;
const ulong isc_cant_start_logging		= 335544464;
const ulong isc_bad_segstr_type			= 335544465;
const ulong isc_foreign_key			= 335544466;
const ulong isc_high_minor			= 335544467;
const ulong isc_tra_state			= 335544468;
const ulong isc_trans_invalid			= 335544469;
const ulong isc_buf_invalid			= 335544470;
const ulong isc_indexnotdefined			= 335544471;
const ulong isc_login				= 335544472;
const ulong isc_invalid_bookmark		= 335544473;
const ulong isc_bad_lock_level			= 335544474;
const ulong isc_relation_lock			= 335544475;
const ulong isc_record_lock			= 335544476;
const ulong isc_max_idx				= 335544477;
const ulong isc_jrn_enable			= 335544478;
const ulong isc_old_failure			= 335544479;
const ulong isc_old_in_progress			= 335544480;
const ulong isc_old_no_space			= 335544481;
const ulong isc_no_wal_no_jrn			= 335544482;
const ulong isc_num_old_files			= 335544483;
const ulong isc_wal_file_open			= 335544484;
const ulong isc_bad_stmt_handle			= 335544485;
const ulong isc_wal_failure			= 335544486;
const ulong isc_walw_err			= 335544487;
const ulong isc_logh_small			= 335544488;
const ulong isc_logh_inv_version		= 335544489;
const ulong isc_logh_open_flag			= 335544490;
const ulong isc_logh_open_flag2			= 335544491;
const ulong isc_logh_diff_dbname		= 335544492;
const ulong isc_logf_unexpected_eof		= 335544493;
const ulong isc_logr_incomplete			= 335544494;
const ulong isc_logr_header_small		= 335544495;
const ulong isc_logb_small			= 335544496;
const ulong isc_wal_illegal_attach		= 335544497;
const ulong isc_wal_invalid_wpb			= 335544498;
const ulong isc_wal_err_rollover		= 335544499;
const ulong isc_no_wal				= 335544500;
const ulong isc_drop_wal			= 335544501;
const ulong isc_stream_not_defined		= 335544502;
const ulong isc_wal_subsys_error		= 335544503;
const ulong isc_wal_subsys_corrupt		= 335544504;
const ulong isc_no_archive			= 335544505;
const ulong isc_shutinprog			= 335544506;
const ulong isc_range_in_use			= 335544507;
const ulong isc_range_not_found			= 335544508;
const ulong isc_charset_not_found		= 335544509;
const ulong isc_lock_timeout			= 335544510;
const ulong isc_prcnotdef			= 335544511;
const ulong isc_prcmismat			= 335544512;
const ulong isc_wal_bugcheck			= 335544513;
const ulong isc_wal_cant_expand			= 335544514;
const ulong isc_codnotdef			= 335544515;
const ulong isc_xcpnotdef			= 335544516;
const ulong isc_except				= 335544517;
const ulong isc_cache_restart			= 335544518;
const ulong isc_bad_lock_handle			= 335544519;
const ulong isc_jrn_present			= 335544520;
const ulong isc_wal_err_rollover2		= 335544521;
const ulong isc_wal_err_logwrite		= 335544522;
const ulong isc_wal_err_jrn_comm		= 335544523;
const ulong isc_wal_err_expansion		= 335544524;
const ulong isc_wal_err_setup			= 335544525;
const ulong isc_wal_err_ww_sync			= 335544526;
const ulong isc_wal_err_ww_start		= 335544527;
const ulong isc_shutdown			= 335544528;
const ulong isc_existing_priv_mod		= 335544529;
const ulong isc_primary_key_ref			= 335544530;
const ulong isc_primary_key_notnull		= 335544531;
const ulong isc_ref_cnstrnt_notfound		= 335544532;
const ulong isc_foreign_key_notfound		= 335544533;
const ulong isc_ref_cnstrnt_update		= 335544534;
const ulong isc_check_cnstrnt_update		= 335544535;
const ulong isc_check_cnstrnt_del		= 335544536;
const ulong isc_integ_index_seg_del		= 335544537;
const ulong isc_integ_index_seg_mod		= 335544538;
const ulong isc_integ_index_del			= 335544539;
const ulong isc_integ_index_mod			= 335544540;
const ulong isc_check_trig_del			= 335544541;
const ulong isc_check_trig_update		= 335544542;
const ulong isc_cnstrnt_fld_del			= 335544543;
const ulong isc_cnstrnt_fld_rename		= 335544544;
const ulong isc_rel_cnstrnt_update		= 335544545;
const ulong isc_constaint_on_view		= 335544546;
const ulong isc_invld_cnstrnt_type		= 335544547;
const ulong isc_primary_key_exists		= 335544548;
const ulong isc_systrig_update			= 335544549;
const ulong isc_not_rel_owner			= 335544550;
const ulong isc_grant_obj_notfound		= 335544551;
const ulong isc_grant_fld_notfound		= 335544552;
const ulong isc_grant_nopriv			= 335544553;
const ulong isc_nonsql_security_rel		= 335544554;
const ulong isc_nonsql_security_fld		= 335544555;
const ulong isc_wal_cache_err			= 335544556;
const ulong isc_shutfail			= 335544557;
const ulong isc_check_constraint		= 335544558;
const ulong isc_bad_svc_handle			= 335544559;
const ulong isc_shutwarn			= 335544560;
const ulong isc_wrospbver			= 335544561;
const ulong isc_bad_spb_form			= 335544562;
const ulong isc_svcnotdef			= 335544563;
const ulong isc_no_jrn				= 335544564;
const ulong isc_transliteration_failed		= 335544565;
const ulong isc_start_cm_for_wal		= 335544566;
const ulong isc_wal_ovflow_log_required		= 335544567;
const ulong isc_text_subtype			= 335544568;
const ulong isc_dsql_error			= 335544569;
const ulong isc_dsql_command_err		= 335544570;
const ulong isc_dsql_constant_err		= 335544571;
const ulong isc_dsql_cursor_err			= 335544572;
const ulong isc_dsql_datatype_err		= 335544573;
const ulong isc_dsql_decl_err			= 335544574;
const ulong isc_dsql_cursor_update_err		= 335544575;
const ulong isc_dsql_cursor_open_err		= 335544576;
const ulong isc_dsql_cursor_close_err		= 335544577;
const ulong isc_dsql_field_err			= 335544578;
const ulong isc_dsql_internal_err		= 335544579;
const ulong isc_dsql_relation_err		= 335544580;
const ulong isc_dsql_procedure_err		= 335544581;
const ulong isc_dsql_request_err		= 335544582;
const ulong isc_dsql_sqlda_err			= 335544583;
const ulong isc_dsql_var_count_err		= 335544584;
const ulong isc_dsql_stmt_handle		= 335544585;
const ulong isc_dsql_function_err		= 335544586;
const ulong isc_dsql_blob_err			= 335544587;
const ulong isc_collation_not_found		= 335544588;
const ulong isc_collation_not_for_charset	= 335544589;
const ulong isc_dsql_dup_option			= 335544590;
const ulong isc_dsql_tran_err			= 335544591;
const ulong isc_dsql_invalid_array		= 335544592;
const ulong isc_dsql_max_arr_dim_exceeded	= 335544593;
const ulong isc_dsql_arr_range_error		= 335544594;
const ulong isc_dsql_trigger_err		= 335544595;
const ulong isc_dsql_subselect_err		= 335544596;
const ulong isc_dsql_crdb_prepare_err		= 335544597;
const ulong isc_specify_field_err		= 335544598;
const ulong isc_num_field_err			= 335544599;
const ulong isc_col_name_err			= 335544600;
const ulong isc_where_err			= 335544601;
const ulong isc_table_view_err			= 335544602;
const ulong isc_distinct_err			= 335544603;
const ulong isc_key_field_count_err		= 335544604;
const ulong isc_subquery_err			= 335544605;
const ulong isc_expression_eval_err		= 335544606;
const ulong isc_node_err			= 335544607;
const ulong isc_command_end_err			= 335544608;
const ulong isc_index_name			= 335544609;
const ulong isc_exception_name			= 335544610;
const ulong isc_field_name			= 335544611;
const ulong isc_token_err			= 335544612;
const ulong isc_union_err			= 335544613;
const ulong isc_dsql_construct_err		= 335544614;
const ulong isc_field_aggregate_err		= 335544615;
const ulong isc_field_ref_err			= 335544616;
const ulong isc_order_by_err			= 335544617;
const ulong isc_return_mode_err			= 335544618;
const ulong isc_extern_func_err			= 335544619;
const ulong isc_alias_conflict_err		= 335544620;
const ulong isc_procedure_conflict_error	= 335544621;
const ulong isc_relation_conflict_err		= 335544622;
const ulong isc_dsql_domain_err			= 335544623;
const ulong isc_idx_seg_err			= 335544624;
const ulong isc_node_name_err			= 335544625;
const ulong isc_table_name			= 335544626;
const ulong isc_proc_name			= 335544627;
const ulong isc_idx_create_err			= 335544628;
const ulong isc_wal_shadow_err			= 335544629;
const ulong isc_dependency			= 335544630;
const ulong isc_idx_key_err			= 335544631;
const ulong isc_dsql_file_length_err		= 335544632;
const ulong isc_dsql_shadow_number_err		= 335544633;
const ulong isc_dsql_token_unk_err		= 335544634;
const ulong isc_dsql_no_relation_alias		= 335544635;
const ulong isc_indexname			= 335544636;
const ulong isc_no_stream_plan			= 335544637;
const ulong isc_stream_twice			= 335544638;
const ulong isc_stream_not_found		= 335544639;
const ulong isc_collation_requires_text		= 335544640;
const ulong isc_dsql_domain_not_found		= 335544641;
const ulong isc_index_unused			= 335544642;
const ulong isc_dsql_self_join			= 335544643;
const ulong isc_stream_bof			= 335544644;
const ulong isc_stream_crack			= 335544645;
const ulong isc_db_or_file_exists		= 335544646;
const ulong isc_invalid_operator		= 335544647;
const ulong isc_conn_lost			= 335544648;
const ulong isc_bad_checksum			= 335544649;
const ulong isc_page_type_err			= 335544650;
const ulong isc_ext_readonly_err		= 335544651;
const ulong isc_sing_select_err			= 335544652;
const ulong isc_psw_attach			= 335544653;
const ulong isc_psw_start_trans			= 335544654;
const ulong isc_invalid_direction		= 335544655;
const ulong isc_dsql_var_conflict		= 335544656;
const ulong isc_dsql_no_blob_array		= 335544657;
const ulong isc_dsql_base_table			= 335544658;
const ulong isc_duplicate_base_table		= 335544659;
const ulong isc_view_alias			= 335544660;
const ulong isc_index_root_page_full		= 335544661;
const ulong isc_dsql_blob_type_unknown		= 335544662;
const ulong isc_req_max_clones_exceeded		= 335544663;
const ulong isc_dsql_duplicate_spec		= 335544664;
const ulong isc_unique_key_violation		= 335544665;
const ulong isc_srvr_version_too_old		= 335544666;
const ulong isc_drdb_completed_with_errs	= 335544667;
const ulong isc_dsql_procedure_use_err		= 335544668;
const ulong isc_dsql_count_mismatch		= 335544669;
const ulong isc_blob_idx_err			= 335544670;
const ulong isc_array_idx_err			= 335544671;
const ulong isc_key_field_err			= 335544672;
const ulong isc_no_delete			= 335544673;
const ulong isc_del_last_field			= 335544674;
const ulong isc_sort_err			= 335544675;
const ulong isc_sort_mem_err			= 335544676;
const ulong isc_version_err			= 335544677;
const ulong isc_inval_key_posn			= 335544678;
const ulong isc_no_segments_err			= 335544679;
const ulong isc_crrp_data_err			= 335544680;
const ulong isc_rec_size_err			= 335544681;
const ulong isc_dsql_field_ref			= 335544682;
const ulong isc_req_depth_exceeded		= 335544683;
const ulong isc_no_field_access			= 335544684;
const ulong isc_no_dbkey			= 335544685;
const ulong isc_jrn_format_err			= 335544686;
const ulong isc_jrn_file_full			= 335544687;
const ulong isc_dsql_open_cursor_request	= 335544688;
const ulong isc_ib_error			= 335544689;
const ulong isc_cache_redef			= 335544690;
const ulong isc_cache_too_small			= 335544691;
const ulong isc_log_redef			= 335544692;
const ulong isc_log_too_small			= 335544693;
const ulong isc_partition_too_small		= 335544694;
const ulong isc_partition_not_supp		= 335544695;
const ulong isc_log_length_spec			= 335544696;
const ulong isc_precision_err			= 335544697;
const ulong isc_scale_nogt			= 335544698;
const ulong isc_expec_short			= 335544699;
const ulong isc_expec_long			= 335544700;
const ulong isc_expec_ushort			= 335544701;
const ulong isc_like_escape_invalid		= 335544702;
const ulong isc_svcnoexe			= 335544703;
const ulong isc_net_lookup_err			= 335544704;
const ulong isc_service_unknown			= 335544705;
const ulong isc_host_unknown			= 335544706;
const ulong isc_grant_nopriv_on_base		= 335544707;
const ulong isc_dyn_fld_ambiguous		= 335544708;
const ulong isc_dsql_agg_ref_err		= 335544709;
const ulong isc_complex_view			= 335544710;
const ulong isc_unprepared_stmt			= 335544711;
const ulong isc_expec_positive			= 335544712;
const ulong isc_dsql_sqlda_value_err		= 335544713;
const ulong isc_invalid_array_id		= 335544714;
const ulong isc_extfile_uns_op			= 335544715;
const ulong isc_svc_in_use			= 335544716;
const ulong isc_err_stack_limit			= 335544717;
const ulong isc_invalid_key			= 335544718;
const ulong isc_net_init_error			= 335544719;
const ulong isc_loadlib_failure			= 335544720;
const ulong isc_network_error			= 335544721;
const ulong isc_net_connect_err			= 335544722;
const ulong isc_net_connect_listen_err		= 335544723;
const ulong isc_net_event_connect_err		= 335544724;
const ulong isc_net_event_listen_err		= 335544725;
const ulong isc_net_read_err			= 335544726;
const ulong isc_net_write_err			= 335544727;
const ulong isc_integ_index_deactivate		= 335544728;
const ulong isc_integ_deactivate_primary	= 335544729;
const ulong isc_cse_not_supported		= 335544730;
const ulong isc_tra_must_sweep			= 335544731;
const ulong isc_unsupported_network_drive	= 335544732;
const ulong isc_io_create_err			= 335544733;
const ulong isc_io_open_err			= 335544734;
const ulong isc_io_close_err			= 335544735;
const ulong isc_io_read_err			= 335544736;
const ulong isc_io_write_err			= 335544737;
const ulong isc_io_delete_err			= 335544738;
const ulong isc_io_access_err			= 335544739;
const ulong isc_udf_exception			= 335544740;
const ulong isc_lost_db_connection		= 335544741;
const ulong isc_no_write_user_priv		= 335544742;
const ulong isc_token_too_long			= 335544743;
const ulong isc_max_att_exceeded		= 335544744;
const ulong isc_login_same_as_role_name		= 335544745;
const ulong isc_reftable_requires_pk		= 335544746;
const ulong isc_usrname_too_long		= 335544747;
const ulong isc_password_too_long		= 335544748;
const ulong isc_usrname_required		= 335544749;
const ulong isc_password_required		= 335544750;
const ulong isc_bad_protocol			= 335544751;
const ulong isc_dup_usrname_found		= 335544752;
const ulong isc_usrname_not_found		= 335544753;
const ulong isc_error_adding_sec_record		= 335544754;
const ulong isc_error_modifying_sec_record	= 335544755;
const ulong isc_error_deleting_sec_record	= 335544756;
const ulong isc_error_updating_sec_db		= 335544757;
const ulong isc_sort_rec_size_err		= 335544758;
const ulong isc_bad_default_value		= 335544759;
const ulong isc_invalid_clause			= 335544760;
const ulong isc_too_many_handles		= 335544761;
const ulong isc_optimizer_blk_exc		= 335544762;
const ulong isc_invalid_string_constant		= 335544763;
const ulong isc_transitional_date		= 335544764;
const ulong isc_read_only_database		= 335544765;
const ulong isc_must_be_dialect_2_and_up	= 335544766;
const ulong isc_blob_filter_exception		= 335544767;
const ulong isc_exception_access_violation	= 335544768;
const ulong isc_exception_datatype_missalignment= 335544769;
const ulong isc_exception_array_bounds_exceeded	= 335544770;
const ulong isc_exception_float_denormal_operand= 335544771;
const ulong isc_exception_float_divide_by_zero	= 335544772;
const ulong isc_exception_float_inexact_result	= 335544773;
const ulong isc_exception_float_invalid_operand	= 335544774;
const ulong isc_exception_float_overflow	= 335544775;
const ulong isc_exception_float_stack_check	= 335544776;
const ulong isc_exception_float_underflow	= 335544777;
const ulong isc_exception_integer_divide_by_zero= 335544778;
const ulong isc_exception_integer_overflow	= 335544779;
const ulong isc_exception_unknown		= 335544780;
const ulong isc_exception_stack_overflow	= 335544781;
const ulong isc_exception_sigsegv		= 335544782;
const ulong isc_exception_sigill		= 335544783;
const ulong isc_exception_sigbus		= 335544784;
const ulong isc_exception_sigfpe		= 335544785;
const ulong isc_ext_file_delete			= 335544786;
const ulong isc_ext_file_modify			= 335544787;
const ulong isc_adm_task_denied			= 335544788;
const ulong isc_extract_input_mismatch		= 335544789;
const ulong isc_insufficient_svc_privileges	= 335544790;
const ulong isc_file_in_use			= 335544791;
const ulong isc_service_att_err			= 335544792;
const ulong isc_ddl_not_allowed_by_db_sql_dial	= 335544793;
const ulong isc_cancelled			= 335544794;
const ulong isc_unexp_spb_form			= 335544795;
const ulong isc_sql_dialect_datatype_unsupport	= 335544796;
const ulong isc_svcnouser			= 335544797;
const ulong isc_depend_on_uncommitted_rel	= 335544798;
const ulong isc_svc_name_missing		= 335544799;
const ulong isc_too_many_contexts		= 335544800;
const ulong isc_datype_notsup			= 335544801;
const ulong isc_dialect_reset_warning		= 335544802;
const ulong isc_dialect_not_changed		= 335544803;
const ulong isc_database_create_failed		= 335544804;
const ulong isc_inv_dialect_specified		= 335544805;
const ulong isc_valid_db_dialects		= 335544806;
const ulong isc_sqlwarn				= 335544807;
const ulong isc_dtype_renamed			= 335544808;
const ulong isc_extern_func_dir_error		= 335544809;
const ulong isc_date_range_exceeded		= 335544810;
const ulong isc_inv_client_dialect_specified	= 335544811;
const ulong isc_valid_client_dialects		= 335544812;
const ulong isc_optimizer_between_err		= 335544813;
const ulong isc_service_not_supported		= 335544814;
const ulong isc_savepoint_err			= 335544815;
const ulong isc_generator_name			= 335544816;
const ulong isc_udf_name			= 335544817;
const ulong isc_non_unique_service_name		= 335544818;
const ulong isc_tran_no_savepoint		= 335544819;
const ulong isc_must_rollback			= 335544820;
const ulong isc_tempnotsup			= 335544821;
const ulong isc_gfix_db_name			= 335740929;
const ulong isc_gfix_invalid_sw			= 335740930;
const ulong isc_gfix_incmp_sw			= 335740932;
const ulong isc_gfix_replay_req			= 335740933;
const ulong isc_gfix_pgbuf_req			= 335740934;
const ulong isc_gfix_val_req			= 335740935;
const ulong isc_gfix_pval_req			= 335740936;
const ulong isc_gfix_trn_req			= 335740937;
const ulong isc_gfix_full_req			= 335740940;
const ulong isc_gfix_usrname_req		= 335740941;
const ulong isc_gfix_pass_req			= 335740942;
const ulong isc_gfix_subs_name			= 335740943;
const ulong isc_gfix_wal_req			= 335740944;
const ulong isc_gfix_sec_req			= 335740945;
const ulong isc_gfix_nval_req			= 335740946;
const ulong isc_gfix_type_shut			= 335740947;
const ulong isc_gfix_retry			= 335740948;
const ulong isc_gfix_retry_db			= 335740951;
const ulong isc_gfix_exceed_max			= 335740991;
const ulong isc_gfix_corrupt_pool		= 335740992;
const ulong isc_gfix_mem_exhausted		= 335740993;
const ulong isc_gfix_bad_pool			= 335740994;
const ulong isc_gfix_trn_not_valid		= 335740995;
const ulong isc_gfix_unexp_eoi			= 335741012;
const ulong isc_gfix_recon_fail			= 335741018;
const ulong isc_gfix_trn_unknown		= 335741036;
const ulong isc_gfix_mode_req			= 335741038;
const ulong isc_gfix_opt_SQL_dialect		= 335741039;
const ulong isc_gfix_commits_opt		= 335741041;
const ulong isc_dsql_dbkey_from_non_table	= 336003074;
const ulong isc_dsql_transitional_numeric	= 336003075;
const ulong isc_dsql_dialect_warning_expr	= 336003076;
const ulong isc_sql_db_dialect_dtype_unsupport	= 336003077;
const ulong isc_isc_sql_dialect_conflict_num	= 336003079;
const ulong isc_dsql_warning_number_ambiguous	= 336003080;
const ulong isc_dsql_warning_number_ambiguous1	= 336003081;
const ulong isc_dsql_warn_precision_ambiguous	= 336003082;
const ulong isc_dsql_warn_precision_ambiguous1	= 336003083;
const ulong isc_dsql_warn_precision_ambiguous2	= 336003084;
const ulong isc_dsql_rows_ties_err		= 336003085;
const ulong isc_dsql_cursor_stmt_err		= 336003086;
const ulong isc_dsql_on_commit_invalid		= 336003087;
const ulong isc_dsql_gen_cnstrnt_ref_temp	= 336003088;
const ulong isc_dsql_persist_cnstrnt_ref_temp	= 336003089;
const ulong isc_dsql_temp_cnstrnt_ref_persist	= 336003090;
const ulong isc_dsql_persist_refs_temp		= 336003091;
const ulong isc_dsql_temp_refs_persist		= 336003092;
const ulong isc_dsql_temp_refs_mismatch		= 336003093;
const ulong isc_dsql_usrname_lower		= 336003094;
const ulong isc_dyn_role_does_not_exist		= 336068796;
const ulong isc_dyn_no_grant_admin_opt		= 336068797;
const ulong isc_dyn_user_not_role_member	= 336068798;
const ulong isc_dyn_delete_role_failed		= 336068799;
const ulong isc_dyn_grant_role_to_user		= 336068800;
const ulong isc_dyn_inv_sql_role_name		= 336068801;
const ulong isc_dyn_dup_sql_role		= 336068802;
const ulong isc_dyn_kywd_spec_for_role		= 336068803;
const ulong isc_dyn_roles_not_supported		= 336068804;
const ulong isc_dyn_domain_name_exists		= 336068812;
const ulong isc_dyn_field_name_exists		= 336068813;
const ulong isc_dyn_dependency_exists		= 336068814;
const ulong isc_dyn_dtype_invalid		= 336068815;
const ulong isc_dyn_char_fld_too_small		= 336068816;
const ulong isc_dyn_invalid_dtype_conversion	= 336068817;
const ulong isc_dyn_dtype_conv_invalid		= 336068818;
const ulong isc_dyn_gen_does_not_exist		= 336068820;
const ulong isc_dyn_delete_generator_failed	= 336068821;
const ulong isc_dyn_drop_db_owner		= 336068836;
const ulong isc_gbak_unknown_switch		= 336330753;
const ulong isc_gbak_page_size_missing		= 336330754;
const ulong isc_gbak_page_size_toobig		= 336330755;
const ulong isc_gbak_redir_ouput_missing	= 336330756;
const ulong isc_gbak_switches_conflict		= 336330757;
const ulong isc_gbak_unknown_device		= 336330758;
const ulong isc_gbak_no_protection		= 336330759;
const ulong isc_gbak_page_size_not_allowed	= 336330760;
const ulong isc_gbak_multi_source_dest		= 336330761;
const ulong isc_gbak_filename_missing		= 336330762;
const ulong isc_gbak_dup_inout_names		= 336330763;
const ulong isc_gbak_inv_page_size		= 336330764;
const ulong isc_gbak_db_specified		= 336330765;
const ulong isc_gbak_db_exists			= 336330766;
const ulong isc_gbak_unk_device			= 336330767;
const ulong isc_gbak_blob_info_failed		= 336330772;
const ulong isc_gbak_unk_blob_item		= 336330773;
const ulong isc_gbak_get_seg_failed		= 336330774;
const ulong isc_gbak_close_blob_failed		= 336330775;
const ulong isc_gbak_open_blob_failed		= 336330776;
const ulong isc_gbak_put_blr_gen_id_failed	= 336330777;
const ulong isc_gbak_unk_type			= 336330778;
const ulong isc_gbak_comp_req_failed		= 336330779;
const ulong isc_gbak_start_req_failed		= 336330780;
const ulong isc_gbak_rec_failed			= 336330781;
const ulong isc_gbak_rel_req_failed		= 336330782;
const ulong isc_gbak_db_info_failed		= 336330783;
const ulong isc_gbak_no_db_desc			= 336330784;
const ulong isc_gbak_db_create_failed		= 336330785;
const ulong isc_gbak_decomp_len_error		= 336330786;
const ulong isc_gbak_tbl_missing		= 336330787;
const ulong isc_gbak_blob_col_missing		= 336330788;
const ulong isc_gbak_create_blob_failed		= 336330789;
const ulong isc_gbak_put_seg_failed		= 336330790;
const ulong isc_gbak_rec_len_exp		= 336330791;
const ulong isc_gbak_inv_rec_len		= 336330792;
const ulong isc_gbak_exp_data_type		= 336330793;
const ulong isc_gbak_gen_id_failed		= 336330794;
const ulong isc_gbak_unk_rec_type		= 336330795;
const ulong isc_gbak_inv_bkup_ver		= 336330796;
const ulong isc_gbak_missing_bkup_desc		= 336330797;
const ulong isc_gbak_string_trunc		= 336330798;
const ulong isc_gbak_cant_rest_record		= 336330799;
const ulong isc_gbak_send_failed		= 336330800;
const ulong isc_gbak_no_tbl_name		= 336330801;
const ulong isc_gbak_unexp_eof			= 336330802;
const ulong isc_gbak_db_format_too_old		= 336330803;
const ulong isc_gbak_inv_array_dim		= 336330804;
const ulong isc_gbak_xdr_len_expected		= 336330807;
const ulong isc_gbak_open_bkup_error		= 336330817;
const ulong isc_gbak_open_error			= 336330818;
const ulong isc_gbak_missing_block_fac		= 336330934;
const ulong isc_gbak_inv_block_fac		= 336330935;
const ulong isc_gbak_block_fac_specified	= 336330936;
const ulong isc_gbak_missing_username		= 336330940;
const ulong isc_gbak_missing_password		= 336330941;
const ulong isc_gbak_missing_skipped_bytes	= 336330952;
const ulong isc_gbak_inv_skipped_bytes		= 336330953;
const ulong isc_gbak_err_restore_charset	= 336330965;
const ulong isc_gbak_err_restore_collation	= 336330967;
const ulong isc_gbak_read_error			= 336330972;
const ulong isc_gbak_write_error		= 336330973;
const ulong isc_gbak_db_in_use			= 336330985;
const ulong isc_gbak_sysmemex			= 336330990;
const ulong isc_gbak_restore_role_failed	= 336331002;
const ulong isc_gbak_role_op_missing		= 336331005;
const ulong isc_gbak_page_buffers_missing	= 336331010;
const ulong isc_gbak_page_buffers_wrong_param	= 336331011;
const ulong isc_gbak_page_buffers_restore	= 336331012;
const ulong isc_gbak_inv_size			= 336331014;
const ulong isc_gbak_file_outof_sequence	= 336331015;
const ulong isc_gbak_join_file_missing		= 336331016;
const ulong isc_gbak_stdin_not_supptd		= 336331017;
const ulong isc_gbak_stdout_not_supptd		= 336331018;
const ulong isc_gbak_bkup_corrupt		= 336331019;
const ulong isc_gbak_unk_db_file_spec		= 336331020;
const ulong isc_gbak_hdr_write_failed		= 336331021;
const ulong isc_gbak_disk_space_ex		= 336331022;
const ulong isc_gbak_size_lt_min		= 336331023;
const ulong isc_gbak_svc_name_missing		= 336331025;
const ulong isc_gbak_not_ownr			= 336331026;
const ulong isc_gbak_mode_req			= 336331031;
const ulong isc_gbak_validate_restore		= 336331034;
const ulong isc_HLP_SETSAVEPOINT		= 336658539;
const ulong isc_gsec_cant_open_db		= 336723983;
const ulong isc_gsec_switches_error		= 336723984;
const ulong isc_gsec_no_op_spec			= 336723985;
const ulong isc_gsec_no_usr_name		= 336723986;
const ulong isc_gsec_err_add			= 336723987;
const ulong isc_gsec_err_modify			= 336723988;
const ulong isc_gsec_err_find_mod		= 336723989;
const ulong isc_gsec_err_rec_not_found		= 336723990;
const ulong isc_gsec_err_delete			= 336723991;
const ulong isc_gsec_err_find_del		= 336723992;
const ulong isc_gsec_err_find_disp		= 336723996;
const ulong isc_gsec_inv_param			= 336723997;
const ulong isc_gsec_op_specified		= 336723998;
const ulong isc_gsec_pw_specified		= 336723999;
const ulong isc_gsec_uid_specified		= 336724000;
const ulong isc_gsec_gid_specified		= 336724001;
const ulong isc_gsec_proj_specified		= 336724002;
const ulong isc_gsec_org_specified		= 336724003;
const ulong isc_gsec_fname_specified		= 336724004;
const ulong isc_gsec_mname_specified		= 336724005;
const ulong isc_gsec_lname_specified		= 336724006;
const ulong isc_gsec_inv_switch			= 336724008;
const ulong isc_gsec_amb_switch			= 336724009;
const ulong isc_gsec_no_op_specified		= 336724010;
const ulong isc_gsec_params_not_allowed		= 336724011;
const ulong isc_gsec_incompat_switch		= 336724012;
const ulong isc_gsec_inv_username		= 336724044;
const ulong isc_gsec_inv_pw_length		= 336724045;
const ulong isc_gsec_db_specified		= 336724046;
const ulong isc_gsec_db_admin_specified		= 336724047;
const ulong isc_gsec_db_admin_pw_specified	= 336724048;
const ulong isc_gsec_sql_role_specified		= 336724049;
const ulong isc_license_no_file			= 336789504;
const ulong isc_license_op_specified		= 336789523;
const ulong isc_license_op_missing		= 336789524;
const ulong isc_license_inv_switch		= 336789525;
const ulong isc_license_inv_switch_combo	= 336789526;
const ulong isc_license_inv_op_combo		= 336789527;
const ulong isc_license_amb_switch		= 336789528;
const ulong isc_license_inv_parameter		= 336789529;
const ulong isc_license_param_specified		= 336789530;
const ulong isc_license_param_req		= 336789531;
const ulong isc_license_syntx_error		= 336789532;
const ulong isc_license_dup_id			= 336789534;
const ulong isc_license_inv_id_key		= 336789535;
const ulong isc_license_err_remove		= 336789536;
const ulong isc_license_err_update		= 336789537;
const ulong isc_license_err_convert		= 336789538;
const ulong isc_license_err_unk			= 336789539;
const ulong isc_license_svc_err_add		= 336789540;
const ulong isc_license_svc_err_remove		= 336789541;
const ulong isc_license_eval_exists		= 336789563;
const ulong isc_smp_cpu_license			= 336789570;
const ulong isc_node_locked_full_unlimited_serve= 336789571;
const ulong isc_dev_only_full_server_licenses	= 336789572;
const ulong isc_license_not_registered		= 336789573;
const ulong isc_license_library_unloadable	= 336789574;
const ulong isc_license_registration_file	= 336789575;
const ulong isc_license_expire_limit		= 336789576;
const ulong isc_license_bad_reg_file		= 336789577;
const ulong isc_license_bad_lic_file		= 336789578;
const ulong isc_gstat_unknown_switch		= 336920577;
const ulong isc_gstat_retry			= 336920578;
const ulong isc_gstat_wrong_ods			= 336920579;
const ulong isc_gstat_unexpected_eof		= 336920580;
const ulong isc_gstat_open_err			= 336920605;
const ulong isc_gstat_read_err			= 336920606;
const ulong isc_gstat_sysmemex			= 336920607;
const uint isc_err_max				= 721;

const uint ISC_TRUE				= 1;
const uint ISC_FALSE				= 0;

const uint DSQL_close				= 1;
const uint DSQL_drop				= 2;
const uint DSQL_cancel				= 4;

const uint METADATALENGTH			= 68;

const ulong ISC_TIME_SECONDS_PRECISION		= 10000;
const int ISC_TIME_SECONDS_PRECISION_SCALE	= -4;

const uint ARR_DESC_VERSION2			= 2;
const uint ARR_DESC_CURRENT_VERSION		= ARR_DESC_VERSION2;

const uint BLB_DESC_VERSION2			= 2;
const uint BLB_DESC_CURRENT_VERSION		= BLB_DESC_VERSION2;

deprecated const uint SQLDA_VERSION1		= 1;

const uint SQLDA_VERSION2			= 2;
const uint SQLDA_CURRENT_VERSION		= SQLDA_VERSION2;

const uint SQL_DIALECT_V5			= 1; /// Meaning is same as DIALECT_xsqlda.
const uint SQL_DIALECT_V6_TRANSITION		= 2; /// Flagging anything that is delimited by double quotes as an error and flagging keyword DATE as an error.
const uint SQL_DIALECT_V6			= 3; /// supports SQL delimited identifier, SQLDATE/DATE, TIME, TIMESTAMP, CURRENT_DATE, CURRENT_TIME, CURRENT_TIMESTAMP, and 64-bit exact numeric type.
const uint SQL_DIALECT_CURRENT			= SQL_DIALECT_V6; /// latest IB DIALECT.

const uint sec_uid_spec			= 0x01;
const uint sec_gid_spec			= 0x02;
const uint sec_server_spec		= 0x04;
const uint sec_password_spec		= 0x08;
const uint sec_group_name_spec		= 0x10;
const uint sec_first_name_spec		= 0x20;
const uint sec_middle_name_spec		= 0x40;
const uint sec_last_name_spec		= 0x80;
const uint sec_dba_user_name_spec	= 0x100;
const uint sec_dba_password_spec	= 0x200;

const uint sec_protocol_tcpip		= 1;
const uint sec_protocol_netbeui		= 2;
const uint sec_protocol_spx		= 3;
const uint sec_protocol_local		= 4;

struct ISC_TIMESTAMP {
	ISC_DATE timestamp_date;
	ISC_TIME timestamp_time;
}

struct GDS_QUAD {
	ISC_LONG gds_quad_high;
	ISC_ULONG gds_quad_low;
}
alias GDS_QUAD ISC_QUAD;
alias GDS_QUAD.gds_quad_high isc_quad_high;
alias GDS_QUAD.gds_quad_low isc_quad_low;

struct ISC_ARRAY_BOUND {
	short array_bound_lower;
	short array_bound_upper;
}

struct ISC_ARRAY_DESC_V2 {
	short array_desc_version;
	ubyte array_desc_dtype;
	ubyte array_desc_subtype;
	char array_desc_scale;
	ushort array_desc_length;
	char[METADATALENGTH] array_desc_field_name;
	char[METADATALENGTH] array_desc_relation_name ;
	short array_desc_dimensions;
	short array_desc_flags;
	ISC_ARRAY_BOUND[16] array_desc_bounds;
}


struct ISC_BLOB_DESC_V2 {
	short blob_desc_version;
	short blob_desc_subtype;
	short blob_desc_charset;
	short blob_desc_segment_size;
	char[METADATALENGTH] blob_desc_field_name;
	char[METADATALENGTH] blob_desc_relation_name;
}

struct isc_blob_ctl {
	ISC_STATUS function() ctl_source;	/// Source filter.
	isc_blob_ctl* ctl_source_handle;	/// Argument to pass to source filter.
	short ctl_to_sub_type;			/// Target type.
	short ctl_from_sub_type;		/// Source type.
	ushort ctl_buffer_length;		/// Length of buffer.
	ushort ctl_segment_length;		/// Length of current segment.
	ushort ctl_bpb_length;			/// Length of blob parameter block.
	char* ctl_bpb;				/// Address of blob parameter block.
	ubyte* ctl_buffer;			/// Address of segment buffer.
	ISC_LONG ctl_max_segment;		/// Length of longest segment.
	ISC_LONG ctl_number_segments;		/// Total number of segments.
	ISC_LONG ctl_total_length;		/// Total length of blob.
	ISC_STATUS* ctl_status;			/// Address of status vector.
	long[8] ctl_data;			/// Application specific data.
}
alias isc_blob_ctl* ISC_BLOB_CTL;

struct bstream {
	void* bstr_blob;			/// Blob handle.
	char* bstr_buffer;			/// Address of buffer.
	char* bstr_ptr;				/// Next character.
	short bstr_length;			/// Length of buffer.
	short bstr_cnt;				/// Characters in buffer.
	char bstr_mode;				/// (mode) ? OUTPUT : INPUT.
}
alias bstream BSTREAM;

deprecated struct XSQLVAR_V1 {
	short sqltype;		/// Datatype of field.
	short sqlscale;		/// Scale factor.
	short sqlsubtype;	/// Datatype subtype.
	short sqllen;		/// Length of data area.
	char* sqldata;		/// Address of data.
	short* sqlind;		/// Address of indicator variable.
	short sqlname_length;	/// Length of sqlname field.
	char[32] sqlname;	/// Name of field, name length + space for NULL.
	short relname_length;	/// Length of relation name.
	char[32] relname;	/// Field's relation name + space for NULL.
	short ownname_length;	/// Length of owner name.
	char[32] ownname;	/// Relation's owner name + space for  NULL.
	short aliasname_length;	/// Length of alias name.
	char[32] aliasname;	/// Relation's alias name + space for  NULL.
}

deprecated struct ISC_ARRAY_DESC {
	ubyte array_desc_dtype;
	char array_desc_scale;
	ushort array_desc_length;
	char[32] array_desc_field_name;
	char[32] array_desc_relation_name;
	short array_desc_dimensions;
	short array_desc_flags;
	ISC_ARRAY_BOUND[16] array_desc_bounds;
}

deprecated struct ISC_BLOB_DESC {
	short blob_desc_subtype;
	short blob_desc_charset;
	short blob_desc_segment_size;
	char[32] blob_desc_field_name;
	char[32] blob_desc_relation_name;
}

struct XSQLVAR {
	short sqltype;			/// Datatype of field.
	short sqlscale;			/// Scale factor.
	short sqlprecision;		/// Precision : Reserved for future.
	short sqlsubtype;		/// Datatype subtype.
	short sqllen;			/// Length of data area.
	char* sqldata;			/// Address of data.
	short* sqlind;			/// Address of indicator variable.
	short sqlname_length;		/// Length of sqlname field.
	char[METADATALENGTH] sqlname;	/// Name of field, name length + space for NULL.
	short relname_length;		/// Length of relation name.
	char relname [METADATALENGTH];	/// Field's relation name + space for NULL.
	short ownname_length;		/// Length of owner name.
	char[METADATALENGTH] ownname;	/// Relation's owner name + space for NULL.
	short aliasname_length;		/// Length of alias name.
	char[METADATALENGTH] aliasname;	/// Relation's alias name + space for NULL.
}

struct XSQLDA {
	short sqlversion;		/// Version of this XSQLDA.
	char[8] sqldaid;		/// XSQLDA name field.
	ISC_LONG sqldabc;		/// Length in bytes of SQLDA.
	short sqln;			/// Number of fields allocated.
	short sqld;			/// Actual number of fields.
	XSQLVAR[1] sqlvar;		/// First field address.
}

struct USER_SEC_DATA {
	short sec_flags;	/// Which fields are specified.
	int uid;		/// The user's id.
	int gid;		/// The user's group id.
	int protocol;		/// Protocol to use for connection.
	char* server;		/// Server to administer.
	char* user_name;	/// The user's name.
	char* password;		/// The user's password.
	char* group_name;	/// The group name.
	char* first_name;	/// The user's first name.
	char* middle_name;	/// The user's middle name.
	char* last_name;	/// The user's last name.
	char* dba_user_name;	/// The dba user name.
	char* dba_password;	/// The dba password.
}

/+
#define getb(p)	(--(p)->bstr_cnt >= 0 ? *(p)->bstr_ptr++ & 0377: BLOB_get (p))
#define putb(x,p) (((x) == '\n' || (!(--(p)->bstr_cnt))) ? BLOB_put ((x),p) : ((int) (*(p)->bstr_ptr++ = (unsigned) (x))))
#define putbx(x,p) ((!(--(p)->bstr_cnt)) ? BLOB_put ((x),p) : ((int) (*(p)->bstr_ptr++ = (unsigned) (x))))
+/

uint XSQLDA_LENGTH (uint n) {
	return (XSQLDA.sizeof + n * XSQLVAR.sizeof);
}

void ADD_SPB_LENGTH (char* p, uint length) {
	*p++ = length;
	*p++ = length >> 8;
}

void ADD_SPB_NUMERIC (char* p, uint data) {
	*p++ = data;
	*p++ = data >> 8;
	*p++ = data >> 16;
	*p++ = data >> 24;
}

extern (C):

ISC_STATUS isc_attach_database (ISC_STATUS*, short, char*, isc_db_handle*, short, char*);

ISC_STATUS isc_array_gen_sdl (ISC_STATUS*, ISC_ARRAY_DESC*, short*, char*, short*);

ISC_STATUS isc_array_gen_sdl2 (ISC_STATUS*, ISC_ARRAY_DESC_V2*, short*, char*, short*);

ISC_STATUS isc_array_get_slice (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, ISC_ARRAY_DESC*, void*, ISC_LONG*);

ISC_STATUS isc_array_get_slice2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, ISC_ARRAY_DESC_V2*, void*, ISC_LONG*);

ISC_STATUS isc_array_lookup_bounds (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_ARRAY_DESC*);

ISC_STATUS isc_array_lookup_bounds2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_ARRAY_DESC_V2*);

ISC_STATUS isc_array_lookup_desc (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_ARRAY_DESC*);

ISC_STATUS isc_array_lookup_desc2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_ARRAY_DESC_V2*);

ISC_STATUS isc_array_set_desc (ISC_STATUS*, char*, char*, short*, short*, short*, ISC_ARRAY_DESC*);

ISC_STATUS isc_array_set_desc2 (ISC_STATUS*, char*, char*, short*, short*, short*, ISC_ARRAY_DESC_V2*);

ISC_STATUS isc_array_put_slice (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, ISC_ARRAY_DESC*, void*, ISC_LONG*);

ISC_STATUS isc_array_put_slice2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, ISC_ARRAY_DESC_V2*, void*, ISC_LONG*);

void isc_blob_default_desc (ISC_BLOB_DESC*, char*, char*);

void isc_blob_default_desc2 (ISC_BLOB_DESC_V2*, char*, char*);

ISC_STATUS isc_blob_gen_bpb (ISC_STATUS*,
					ISC_BLOB_DESC*,
					ISC_BLOB_DESC*,
					ushort,
					char*,
					ushort*);

ISC_STATUS isc_blob_gen_bpb2 (ISC_STATUS*, ISC_BLOB_DESC_V2*, ISC_BLOB_DESC_V2*, ushort, char*, ushort*);

ISC_STATUS isc_blob_info (ISC_STATUS*, isc_blob_handle*, short, char*, short, char*);

ISC_STATUS isc_blob_lookup_desc (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_BLOB_DESC*, char*);

ISC_STATUS isc_blob_lookup_desc2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, char*, ISC_BLOB_DESC_V2*, char*);

ISC_STATUS isc_blob_set_desc (ISC_STATUS*, char*, char*, short, short, short, ISC_BLOB_DESC*);

ISC_STATUS isc_blob_set_desc2 (ISC_STATUS*, char*, char*, short, short, short, ISC_BLOB_DESC_V2*);

ISC_STATUS isc_cancel_blob (ISC_STATUS*, isc_blob_handle*);

ISC_STATUS isc_cancel_events (ISC_STATUS*, isc_db_handle*, ISC_LONG*);

ISC_STATUS isc_close_blob (ISC_STATUS*, isc_blob_handle*);

ISC_STATUS isc_commit_retaining (ISC_STATUS*, isc_tr_handle*);

ISC_STATUS isc_commit_transaction (ISC_STATUS*, isc_tr_handle*);

ISC_STATUS isc_create_blob (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_blob_handle*, ISC_QUAD*);

ISC_STATUS isc_create_blob2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_blob_handle*, ISC_QUAD*, short, char*);

ISC_STATUS isc_create_database (ISC_STATUS*, short, char*, isc_db_handle*, short, char*, short);

ISC_STATUS isc_database_info (ISC_STATUS*, isc_db_handle*, short, char*, short, char*);

void isc_decode_date (ISC_QUAD*, void*);

void isc_decode_sql_date (ISC_DATE*, void*);

void isc_decode_sql_time (ISC_TIME*, void*);

void isc_decode_timestamp (ISC_TIMESTAMP*, void*);

ISC_STATUS isc_detach_database (ISC_STATUS*, isc_db_handle*);

ISC_STATUS isc_drop_database (ISC_STATUS*, isc_db_handle*);

ISC_STATUS isc_dsql_allocate_statement (ISC_STATUS*, isc_db_handle*, isc_stmt_handle*);

ISC_STATUS isc_dsql_alloc_statement2 (ISC_STATUS*, isc_db_handle*, isc_stmt_handle*);

ISC_STATUS isc_dsql_describe (ISC_STATUS*, isc_stmt_handle*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_describe_bind (ISC_STATUS*, isc_stmt_handle*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_exec_immed2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, XSQLDA*, XSQLDA*);

ISC_STATUS isc_dsql_execute (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_execute2 (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, XSQLDA*, XSQLDA*);

ISC_STATUS isc_dsql_execute_immediate (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_fetch (ISC_STATUS*, isc_stmt_handle*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_finish (isc_db_handle*);

ISC_STATUS isc_dsql_free_statement (ISC_STATUS*, isc_stmt_handle*, ushort);

ISC_STATUS isc_dsql_insert (ISC_STATUS*, isc_stmt_handle*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_prepare (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, char*, ushort, XSQLDA*);

ISC_STATUS isc_dsql_set_cursor_name (ISC_STATUS*, isc_stmt_handle*, char*, ushort);

ISC_STATUS isc_dsql_sql_info (ISC_STATUS*, isc_stmt_handle*, short, char*, short, char*);

void isc_encode_date (void*, ISC_QUAD*);

void isc_encode_sql_date (void*, ISC_DATE*);

void isc_encode_sql_time (void*, ISC_TIME*);

void isc_encode_timestamp (void*, ISC_TIMESTAMP*);

ISC_LONG isc_event_block (char**, char**, ushort, ...);

void isc_event_counts (ISC_ULONG*, short, char*,char*);

void isc_expand_dpb (char**, short*, ...);

int isc_modify_dpb (char**, short*, ushort, char*, short );

ISC_LONG isc_free (char*);

ISC_STATUS isc_get_segment (ISC_STATUS*, isc_blob_handle*, ushort*, ushort, char*);

ISC_STATUS isc_get_slice (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, short, char*, short, ISC_LONG*, ISC_LONG, void*, ISC_LONG*);

ISC_STATUS isc_interprete (char*, ISC_STATUS**);

ISC_STATUS isc_open_blob (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_blob_handle*, ISC_QUAD*);

ISC_STATUS isc_open_blob2 (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_blob_handle*, ISC_QUAD*, short, char*);

ISC_STATUS isc_prepare_transaction2 (ISC_STATUS*, isc_tr_handle*, short, char*);

void isc_print_sqlerror (short, ISC_STATUS*);

ISC_STATUS isc_print_status (ISC_STATUS*);

ISC_STATUS isc_put_segment (ISC_STATUS*, isc_blob_handle*, ushort, char*);

ISC_STATUS isc_put_slice (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ISC_QUAD*, short, char*, short, ISC_LONG*, ISC_LONG, void*);

ISC_STATUS isc_que_events (ISC_STATUS*, isc_db_handle*, ISC_LONG*, short, char*, isc_callback, void*);

ISC_STATUS isc_release_savepoint (ISC_STATUS*, isc_tr_handle*, char*);

ISC_STATUS isc_rollback_retaining (ISC_STATUS*, isc_tr_handle*);

ISC_STATUS isc_rollback_savepoint (ISC_STATUS*, isc_tr_handle*, char*, ushort);

ISC_STATUS isc_rollback_transaction (ISC_STATUS*, isc_tr_handle*);

ISC_STATUS isc_start_multiple (ISC_STATUS*, isc_tr_handle*, short, void*);

ISC_STATUS isc_start_savepoint (ISC_STATUS*, isc_tr_handle*, char*);

ISC_STATUS isc_start_transaction (ISC_STATUS*, isc_tr_handle*, short, ...);

ISC_LONG isc_sqlcode (ISC_STATUS*);

void isc_sql_interprete (short, char*, short);

ISC_STATUS isc_transaction_info (ISC_STATUS*, isc_tr_handle*, short, char*, short, char*);

ISC_STATUS isc_transact_request (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, char*, ushort, char*);

ISC_LONG isc_vax_integer (char*, short);

ISC_INT64 isc_portable_integer (char*, short);

int isc_add_user (ISC_STATUS*, USER_SEC_DATA*);

int isc_delete_user (ISC_STATUS*, USER_SEC_DATA*);

int isc_modify_user (ISC_STATUS*, USER_SEC_DATA*);

ISC_STATUS isc_compile_request (ISC_STATUS*, isc_db_handle*, isc_req_handle*, short, char*);

ISC_STATUS isc_compile_request2 (ISC_STATUS*, isc_db_handle*, isc_req_handle*, short, char*);

ISC_STATUS isc_ddl (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, short, char*);

ISC_STATUS isc_prepare_transaction (ISC_STATUS*, isc_tr_handle*);

ISC_STATUS isc_receive (ISC_STATUS*, isc_req_handle*, short, short, void*, short);

ISC_STATUS isc_reconnect_transaction (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, short, char*);

ISC_STATUS isc_release_request (ISC_STATUS*, isc_req_handle*);

ISC_STATUS isc_request_info (ISC_STATUS*, isc_req_handle*, short, short, char*, short, char*);

ISC_STATUS isc_seek_blob (ISC_STATUS*, isc_blob_handle*, short, ISC_LONG, ISC_LONG*);

ISC_STATUS isc_send (ISC_STATUS*, isc_req_handle*, short, short, void*, short);

ISC_STATUS isc_start_and_send (ISC_STATUS*, isc_req_handle*, isc_tr_handle*, short, short, void*, short);

ISC_STATUS isc_start_request (ISC_STATUS*, isc_req_handle*, isc_tr_handle*, short);

ISC_STATUS isc_unwind_request (ISC_STATUS*, isc_tr_handle*, short);

ISC_STATUS isc_wait_for_event (ISC_STATUS*, isc_db_handle*, short, char*, char*);

ISC_STATUS isc_close (ISC_STATUS*, char*);

ISC_STATUS isc_declare (ISC_STATUS*, char*, char*);

ISC_STATUS isc_describe (ISC_STATUS*, char*, XSQLDA*);

ISC_STATUS isc_describe_bind (ISC_STATUS*, char*, XSQLDA*);

ISC_STATUS isc_execute (ISC_STATUS*, isc_tr_handle*, char*, XSQLDA*);

ISC_STATUS isc_execute_immediate (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, short*, char*);

ISC_STATUS isc_fetch (ISC_STATUS*, char*, XSQLDA*);

ISC_STATUS isc_open (ISC_STATUS*, isc_tr_handle*, char*, XSQLDA*);

ISC_STATUS isc_prepare (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, char*, short*, char*, XSQLDA*);

ISC_STATUS isc_dsql_execute_m (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_execute2_m (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, char*, ushort, ushort, char*, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_execute_immediate_m (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_exec_immed3_m (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, ushort, char*, ushort, ushort,char*, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_fetch_m (ISC_STATUS*, isc_stmt_handle*, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_insert_m (ISC_STATUS*, isc_stmt_handle*, ushort, char*, ushort, ushort, char*);

ISC_STATUS isc_dsql_prepare_m (ISC_STATUS*, isc_tr_handle*, isc_stmt_handle*, ushort, char*, ushort, ushort, char*, ushort, char*);

ISC_STATUS isc_dsql_release (ISC_STATUS*, char*);

ISC_STATUS isc_embed_dsql_close (ISC_STATUS*, char*);

ISC_STATUS isc_embed_dsql_declare (ISC_STATUS*, char*, char*);

ISC_STATUS isc_embed_dsql_describe (ISC_STATUS*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_describe_bind (ISC_STATUS*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_execute (ISC_STATUS*, isc_tr_handle*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_execute2 (ISC_STATUS*, isc_tr_handle*, char*, ushort, XSQLDA*, XSQLDA*);

ISC_STATUS isc_embed_dsql_execute_immed (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, ushort, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_fetch (ISC_STATUS*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_open (ISC_STATUS*, isc_tr_handle*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_open2 (ISC_STATUS*, isc_tr_handle*, char*, ushort, XSQLDA*,XSQLDA*);

ISC_STATUS isc_embed_dsql_insert (ISC_STATUS*, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_prepare (ISC_STATUS*, isc_db_handle*,isc_tr_handle*, char*, ushort, char*, ushort, XSQLDA*);

ISC_STATUS isc_embed_dsql_release (ISC_STATUS*, char*);

BSTREAM* BLOB_open (isc_blob_handle, char*, int);

int BLOB_put (char, BSTREAM*);

int BLOB_close (BSTREAM*);

int BLOB_get (BSTREAM*);

int BLOB_display (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

int BLOB_dump (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

int BLOB_edit (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

int BLOB_load (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

int BLOB_text_dump (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

int BLOB_text_load (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

BSTREAM* Bopen (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*);

BSTREAM* Bopen2 (ISC_QUAD*, isc_db_handle, isc_tr_handle, char*, ushort);

ISC_LONG isc_ftof (char*, ushort, char*, ushort);

ISC_STATUS isc_print_blr (char*, isc_callback, void*, short);

void isc_set_debug (int);

void isc_qtoq (ISC_QUAD*, ISC_QUAD*);

void isc_vtof (char*, char*,ushort);

void isc_vtov (char*, char*, short);

int isc_version (isc_db_handle*, isc_callback, void*);

ISC_LONG isc_reset_fpe (ushort);

ISC_STATUS isc_service_attach (ISC_STATUS*, ushort, char*, isc_svc_handle*, ushort, char*);

ISC_STATUS isc_service_detach (ISC_STATUS*, isc_svc_handle*);

ISC_STATUS isc_service_query (ISC_STATUS*, isc_svc_handle*, isc_resv_handle*,
ushort, char*, ushort, char*, ushort, char*);

ISC_STATUS isc_service_start (ISC_STATUS*, isc_svc_handle*, isc_resv_handle*, ushort, char*);

void isc_get_client_version (char*);
int isc_get_client_major_version ();
int isc_get_client_minor_version ();

ISC_STATUS isc_compile_map (ISC_STATUS*, isc_form_handle*, isc_req_handle*, short*, char*);

ISC_STATUS isc_compile_menu (ISC_STATUS*, isc_form_handle*, isc_req_handle*, short*, char*);

ISC_STATUS isc_compile_sub_map (ISC_STATUS*, isc_win_handle*, isc_req_handle*, short*, char*);

ISC_STATUS isc_create_window (ISC_STATUS*, isc_win_handle*, short*, char*, short*, short*);

ISC_STATUS isc_delete_window (ISC_STATUS*, isc_win_handle*);

ISC_STATUS isc_drive_form (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_win_handle*, isc_req_handle*, char*, char*);

ISC_STATUS isc_drive_menu (ISC_STATUS*, isc_win_handle*, isc_req_handle*, short*, char*, short*, char*, short*, short*, char*, ISC_LONG*);

ISC_STATUS isc_form_delete (ISC_STATUS*, isc_form_handle*);

ISC_STATUS isc_form_fetch (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_req_handle*, char*);

ISC_STATUS isc_form_insert (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_req_handle*, char*);

ISC_STATUS isc_get_entree (ISC_STATUS*, isc_req_handle*, short*, char*, ISC_LONG*, short*);

ISC_STATUS isc_initialize_menu (ISC_STATUS*, isc_req_handle*);

ISC_STATUS isc_menu (ISC_STATUS*, isc_win_handle*, isc_req_handle*, short*, char*);

ISC_STATUS isc_load_form (ISC_STATUS*, isc_db_handle*, isc_tr_handle*, isc_form_handle*, short*, char*);

ISC_STATUS isc_pop_window (ISC_STATUS*, isc_win_handle*);

ISC_STATUS isc_put_entree (ISC_STATUS*, isc_req_handle*, short*, char*, ISC_LONG*);

ISC_STATUS isc_reset_form (ISC_STATUS*, isc_req_handle*);

ISC_STATUS isc_suspend_window (ISC_STATUS*, isc_win_handle*);