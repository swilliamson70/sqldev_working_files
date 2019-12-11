--------------------------------------------------------
--  File created - Wednesday-December-11-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package NSU_BNR_TBX
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "NSUDEV"."NSU_BNR_TBX" IS
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

/
