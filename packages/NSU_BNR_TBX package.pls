create or replace PACKAGE nsu_bnr_tbx IS
/*

    This package contains procedures to process inbound TBX deduction files
    to update data in the payroll stream.

    Northeastnern State University
    23 Oct 18 - Scott Williamson - start 

*/

    PROCEDURE load_staging_table;

    PROCEDURE load_pdrdedn;

    PROCEDURE mass_enddate;

END nsu_bnr_tbx;